import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/journey_session.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';
import '../services/journey_calculator.dart';
import '../services/study_sync_service.dart';
import '../services/auth_service.dart';

class JourneyProvider extends ChangeNotifier with WidgetsBindingObserver {
  JourneyProvider({
    required AudioService audioService,
    AuthService? authService,
    this.ownerId = 'guest',
    DatabaseService? database,
    DateTime Function()? clock,
    bool? useSqlite,
  })  : _audioService = audioService,
        _database = database ?? DatabaseService(),
        _clock = clock ?? DateTime.now,
        _sqliteOverride = useSqlite {
    _audioService.addListener(_onAudioChanged);
    _audioCompletionSubscription = _audioService.chapterCompletions.listen(
      (item) => unawaited(recordChapterCompleted(
        bookId: item.bookId,
        bookName: item.bookName,
        chapter: item.chapter,
        type: JourneySessionType.listening,
      )),
    );
    _authService = authService;
    _authService?.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_recordActiveInterval());
    });
    ready = initialize();
  }

  static const _uuid = Uuid();
  static const _idleTimeout = Duration(seconds: 60);
  String get _goalTypeKey => 'journey_goal_type_$ownerId';
  String get _goalTargetKey => 'journey_goal_target_$ownerId';
  static const _fallbackSessionsKey = 'journey_sessions';

  final AudioService _audioService;
  final DatabaseService _database;
  final DateTime Function() _clock;
  final bool? _sqliteOverride;
  late final AuthService? _authService;
  late final StreamSubscription<dynamic> _audioCompletionSubscription;
  final List<JourneySession> _sessions = [];
  final List<({String date, JourneyGoalType type, int target})> _goalHistory =
      [];
  Timer? _timer;
  late final Future<void> ready;
  String ownerId;
  JourneyGoalType _goalType = JourneyGoalType.minutes;
  int _goalTarget = 20;
  bool _readingContext = false;
  DateTime? _lastReaderInteraction;
  DateTime? _lastTick;
  int? _bookId;
  String? _bookName;
  int? _chapter;
  int? _verse;
  bool _isForeground = true;
  bool _audioWasPlaying = false;
  Duration _lastAudioPosition = Duration.zero;
  bool isLoading = true;
  Object? error;
  bool syncPending = false;

  JourneyGoalType get goalType => _goalType;
  int get goalTarget => _goalTarget;
  List<JourneySession> get sessions => List.unmodifiable(_sessions);
  JourneySummary get summary =>
      JourneyCalculator.calculate(_sessions, now: _clock());
  bool get hasActivity => _sessions.isNotEmpty;
  bool get readerContextActive => _readingContext;

  ({JourneyGoalType type, int target, bool known}) goalForDate(DateTime value) {
    final key = JourneyCalculator.dateKey(value);
    ({String date, JourneyGoalType type, int target})? effective;
    for (final entry in _goalHistory) {
      if (entry.date.compareTo(key) <= 0 &&
          (effective == null || entry.date.compareTo(effective.date) > 0)) {
        effective = entry;
      }
    }
    return (
      type: effective?.type ?? JourneyGoalType.minutes,
      target: effective?.target ?? 20,
      known: effective != null,
    );
  }

  JourneyDay day(DateTime value) => summary.day(value);

  double goalProgress([DateTime? value]) {
    final selected = day(value ?? _clock());
    final amount = _goalType == JourneyGoalType.minutes
        ? selected.totalMinutes
        : selected.completedChapters;
    return (amount / _goalTarget).clamp(0.0, 1.0);
  }

  int goalAmount([DateTime? value]) {
    final selected = day(value ?? _clock());
    return _goalType == JourneyGoalType.minutes
        ? selected.totalMinutes
        : selected.completedChapters;
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _goalType = JourneyGoalType.values.firstWhere(
        (value) => value.name == prefs.getString(_goalTypeKey),
        orElse: () => JourneyGoalType.minutes,
      );
      _goalTarget = (prefs.getInt(_goalTargetKey) ?? 20).clamp(1, 240);
      _loadGoalHistory(prefs.getString(_goalHistoryKey));
      _ensureGoalBaseline(prefs);
      await _loadSessions();
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setGoal({
    required JourneyGoalType type,
    required int target,
  }) async {
    _goalType = type;
    _goalTarget = target.clamp(1, type == JourneyGoalType.minutes ? 240 : 20);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalTypeKey, type.name);
    await prefs.setInt(_goalTargetKey, _goalTarget);
    final date = JourneyCalculator.dateKey(_clock());
    _goalHistory.removeWhere((entry) => entry.date == date);
    _goalHistory.add((date: date, type: type, target: _goalTarget));
    _goalHistory.sort((a, b) => a.date.compareTo(b.date));
    await prefs.setString(
      _goalHistoryKey,
      jsonEncode(_goalHistory
          .map((entry) => {
                'date': entry.date,
                'type': entry.type.name,
                'target': entry.target,
              })
          .toList()),
    );
    notifyListeners();
  }

  void beginReader({
    required int bookId,
    required String bookName,
    required int chapter,
    int? verse,
  }) {
    if (_readingContext &&
        (_bookId != bookId || _chapter != chapter || _bookName != bookName)) {
      unawaited(_recordActiveInterval(force: true));
      _lastTick = _clock();
    }
    _readingContext = true;
    _lastReaderInteraction = null;
    _bookId = bookId;
    _bookName = bookName;
    _chapter = chapter;
    _verse = verse;
    _lastTick = _clock();
  }

  void readerInteraction({int? verse}) {
    if (!_readingContext) return;
    final now = _clock();
    if (_lastReaderInteraction == null ||
        now.difference(_lastReaderInteraction!) > _idleTimeout) {
      _lastTick = now;
    }
    _lastReaderInteraction = now;
    if (verse != null) _verse = verse;
  }

  void endReader() {
    if (!_readingContext) return;
    unawaited(_recordActiveInterval(force: true));
    _readingContext = false;
  }

  Future<void> recordChapterCompleted({
    required int bookId,
    required String bookName,
    required int chapter,
    JourneySessionType type = JourneySessionType.reading,
  }) async {
    final now = _clock().toUtc();
    await _saveSession(
      JourneySession(
        id: _uuid.v4(),
        ownerId: ownerId,
        type: type,
        startedAt: now,
        endedAt: now,
        durationSeconds: 0,
        createdAt: now,
        updatedAt: now,
        bookId: bookId,
        bookName: bookName,
        chapter: chapter,
        completedChapters: 1,
      ),
    );
  }

  Future<void> synchronize(StudySyncGateway gateway, String userId) async {
    syncPending = true;
    notifyListeners();
    try {
      final records =
          _sessions.where((session) => session.ownerId == userId).map(
                (session) => SyncRecord(
                  kind: 'journey',
                  id: session.id,
                  updatedAt: session.updatedAt,
                  data: session.toJson(),
                ),
              );
      final merged = await gateway.synchronize(userId, records);
      for (final record in merged.where((value) => value.kind == 'journey')) {
        final data = Map<String, Object?>.from(record.data);
        data['id'] = record.id;
        data['ownerId'] = userId;
        final remote = JourneySession.fromJson(data);
        final localIndex =
            _sessions.indexWhere((value) => value.id == remote.id);
        if (localIndex == -1) {
          _sessions.add(remote);
          await _persist(remote);
        } else if (remote.updatedAt.isAfter(_sessions[localIndex].updatedAt)) {
          _sessions[localIndex] = remote;
          await _persist(remote);
        }
      }
      await _loadSessions(notify: false);
    } catch (value) {
      error = value;
    } finally {
      syncPending = false;
      notifyListeners();
    }
  }

  void setOwner(String value) {
    if (ownerId == value) return;
    final previousOwner = ownerId;
    final previousSessions = List<JourneySession>.from(_sessions);
    ownerId = value;
    _sessions.clear();
    isLoading = true;
    notifyListeners();
    unawaited(_switchOwner(previousOwner, value, previousSessions));
  }

  Future<void> _switchOwner(
    String previousOwner,
    String nextOwner,
    List<JourneySession> previousSessions,
  ) async {
    if (previousOwner == 'guest' && nextOwner != 'guest') {
      final localSessions = _usesSqlite
          ? await _database.getJourneySessions(previousOwner)
          : previousSessions
              .where((value) => value.ownerId == previousOwner)
              .toList();
      for (final session in localSessions) {
        final moved = session.copyWith(
          ownerId: nextOwner,
          updatedAt: _clock().toUtc(),
          syncVersion: session.syncVersion + 1,
        );
        await _persist(moved);
      }
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt(_goalTargetKey) == null) {
        final guestTarget = prefs.getInt('journey_goal_target_guest');
        final guestType = prefs.getString('journey_goal_type_guest');
        if (guestTarget != null) {
          await prefs.setInt(_goalTargetKey, guestTarget);
        }
        if (guestType != null) await prefs.setString(_goalTypeKey, guestType);
      }
      final guestHistory = prefs.getString('journey_goal_history_guest');
      if (guestHistory != null && prefs.getString(_goalHistoryKey) == null) {
        await prefs.setString(_goalHistoryKey, guestHistory);
      }
    }
    await _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _goalType = JourneyGoalType.values.firstWhere(
      (value) => value.name == prefs.getString(_goalTypeKey),
      orElse: () => JourneyGoalType.minutes,
    );
    _goalTarget = (prefs.getInt(_goalTargetKey) ?? 20).clamp(1, 240);
    _loadGoalHistory(prefs.getString(_goalHistoryKey));
    _ensureGoalBaseline(prefs);
    await _loadSessions();
    isLoading = false;
    notifyListeners();
  }

  void _onAudioChanged() {
    final playing = _audioService.isPlaying;
    if (playing) {
      if (!_audioWasPlaying) {
        unawaited(_flushReaderBeforeAudio());
        _lastTick = _clock();
        _lastAudioPosition = _audioService.position;
      }
      _readingContext = false;
      _lastReaderInteraction = null;
    } else if (_audioWasPlaying) {
      unawaited(_recordActiveInterval(force: true, audioWasActive: true));
    }
    _audioWasPlaying = playing;
    _lastTick ??= _clock();
  }

  Future<void> _flushReaderBeforeAudio() async {
    final now = _clock();
    final previous = _lastTick;
    final interaction = _lastReaderInteraction;
    if (previous == null ||
        interaction == null ||
        now.difference(interaction) > _idleTimeout) {
      return;
    }
    final seconds = now.difference(previous).inSeconds;
    if (seconds <= 0) return;
    final stamp = now.toUtc();
    await _saveSession(
      JourneySession(
        id: _uuid.v4(),
        ownerId: ownerId,
        type: JourneySessionType.reading,
        startedAt: previous.toUtc(),
        endedAt: stamp,
        durationSeconds: seconds.clamp(0, 20),
        createdAt: stamp,
        updatedAt: stamp,
        bookId: _bookId,
        bookName: _bookName,
        chapter: _chapter,
        startVerse: _verse,
        endVerse: _verse,
      ),
    );
  }

  String get _goalHistoryKey => 'journey_goal_history_$ownerId';

  void _loadGoalHistory(String? raw) {
    _goalHistory.clear();
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final item in decoded) {
        final entry = Map<String, dynamic>.from(item as Map);
        _goalHistory.add((
          date: entry['date'] as String,
          type: JourneyGoalType.values.firstWhere(
            (value) => value.name == entry['type'],
            orElse: () => JourneyGoalType.minutes,
          ),
          target: (entry['target'] as num).toInt(),
        ));
      }
    } catch (_) {
      _goalHistory.clear();
    }
  }

  void _ensureGoalBaseline(SharedPreferences prefs) {
    if (_goalHistory.isNotEmpty) return;
    final date = JourneyCalculator.dateKey(_clock());
    _goalHistory.add((date: date, type: _goalType, target: _goalTarget));
    unawaited(prefs.setString(
      _goalHistoryKey,
      jsonEncode([
        {'date': date, 'type': _goalType.name, 'target': _goalTarget},
      ]),
    ));
  }

  Future<void> _recordActiveInterval({
    bool force = false,
    bool audioWasActive = false,
  }) async {
    final now = _clock();
    final previous = _lastTick;
    _lastTick = now;
    if (previous == null) return;

    final audioActive = _audioService.isPlaying || audioWasActive;
    if (!_isForeground && !audioActive) return;
    var intervalEnd = now;
    if (!audioActive) {
      final interaction = _lastReaderInteraction;
      if (!_readingContext || interaction == null) return;
      final idleEnd = interaction.add(_idleTimeout);
      if (idleEnd.isBefore(intervalEnd)) intervalEnd = idleEnd;
      if (!intervalEnd.isAfter(previous)) return;
    }
    if (audioActive && _readingContext) {
      _readingContext = false;
      _lastReaderInteraction = null;
    }
    final duration = intervalEnd.difference(previous).inSeconds;
    if (duration <= 0 || (!force && duration < 10)) return;
    var recordedSeconds = duration;
    if (audioActive) {
      final position = _audioService.position;
      final positionDelta = position - _lastAudioPosition;
      _lastAudioPosition = position;
      if (positionDelta <= Duration.zero) return;
      recordedSeconds =
          (positionDelta.inMilliseconds / (_audioService.speed * 1000)).round();
      recordedSeconds = recordedSeconds.clamp(0, duration);
      if (recordedSeconds <= 0) return;
    }
    final startedAt = audioActive
        ? now.subtract(Duration(seconds: recordedSeconds)).toUtc()
        : previous.toUtc();
    final endedAt = intervalEnd.toUtc();
    final type =
        audioActive ? JourneySessionType.listening : JourneySessionType.reading;
    final session = JourneySession(
      id: _uuid.v4(),
      ownerId: ownerId,
      type: type,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: recordedSeconds,
      createdAt: endedAt,
      updatedAt: endedAt,
      bookId: audioActive ? _audioService.activeBookId : _bookId,
      bookName: audioActive ? _audioService.activeBookName : _bookName,
      chapter: audioActive ? _audioService.activeChapter : _chapter,
      startVerse: audioActive ? _audioService.currentVerse : _verse,
      endVerse: audioActive ? _audioService.currentVerse : _verse,
    );
    await _saveSession(session);
  }

  Future<void> _saveSession(JourneySession session) async {
    if (_sessions.any((value) => value.id == session.id)) return;
    _sessions.add(session);
    try {
      await _persist(session);
      error = null;
    } catch (value) {
      error = value;
      _sessions.removeWhere((item) => item.id == session.id);
    }
    notifyListeners();
  }

  Future<void> _loadSessions({bool notify = true}) async {
    try {
      if (_usesSqlite) {
        _sessions
          ..clear()
          ..addAll(await _database.getJourneySessions(ownerId));
      } else {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_fallbackSessionsKey);
        final decoded =
            raw == null ? const [] : jsonDecode(raw) as List<dynamic>;
        _sessions
          ..clear()
          ..addAll(decoded.map((value) => JourneySession.fromJson(
                Map<String, Object?>.from(value as Map),
              )))
          ..removeWhere((value) => value.ownerId != ownerId);
      }
      error = null;
    } catch (value) {
      error = value;
    }
    if (notify) notifyListeners();
  }

  Future<void> _persist(JourneySession session) async {
    if (_usesSqlite) {
      await _database.upsertJourneySession(session);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_fallbackSessionsKey);
    final decoded =
        raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
    final values = decoded
        .map((value) => Map<String, Object?>.from(value as Map))
        .toList();
    final index = values.indexWhere((value) => value['id'] == session.id);
    if (index == -1) {
      values.add(session.toJson());
    } else {
      values[index] = session.toJson();
    }
    await prefs.setString(_fallbackSessionsKey, jsonEncode(values));
  }

  bool get _usesSqlite =>
      _sqliteOverride ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS));

  void _onAuthChanged() {
    final user = _authService?.currentUser;
    setOwner(user?.uid ?? 'guest');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_recordActiveInterval(force: true));
      _isForeground = false;
    } else {
      _isForeground = true;
      _lastTick = _clock();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.removeListener(_onAudioChanged);
    unawaited(_audioCompletionSubscription.cancel());
    _authService?.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_recordActiveInterval(force: true));
    super.dispose();
  }
}
