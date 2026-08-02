import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'magic_design.dart';
import 'mood_engine.dart';
import 'studio_fonts.dart';
import 'verse_design.dart';

enum StudioToolTab {
  background,
  text,
  font,
  effects,
  layout,
  decor,
  export,
}

class SavedStudioTemplate {
  SavedStudioTemplate({
    required this.id,
    required this.name,
    required this.design,
    required this.savedAt,
  });

  final String id;
  final String name;
  final VerseDesign design;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'design': design.toJson(),
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedStudioTemplate.fromJson(Map<String, dynamic> json) {
    return SavedStudioTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Template',
      design: VerseDesign.fromJson(
        Map<String, dynamic>.from(json['design'] as Map? ?? {}),
      ),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class StudioChallengeProgress {
  StudioChallengeProgress({
    required this.dayKey,
    required this.verseText,
    required this.reference,
    required this.completed,
    this.badge,
  });

  final String dayKey;
  final String verseText;
  final String reference;
  final bool completed;
  final String? badge;

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'verseText': verseText,
        'reference': reference,
        'completed': completed,
        'badge': badge,
      };

  factory StudioChallengeProgress.fromJson(Map<String, dynamic> json) {
    return StudioChallengeProgress(
      dayKey: json['dayKey'] as String? ?? '',
      verseText: json['verseText'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      badge: json['badge'] as String?,
    );
  }
}

class PublishedStudioCard {
  PublishedStudioCard({
    required this.id,
    required this.title,
    required this.reference,
    required this.designJson,
    required this.savedAt,
    this.likes = 0,
  });

  final String id;
  final String title;
  final String reference;
  final Map<String, dynamic> designJson;
  final DateTime savedAt;
  int likes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'reference': reference,
        'designJson': designJson,
        'savedAt': savedAt.toIso8601String(),
        'likes': likes,
      };

  factory PublishedStudioCard.fromJson(Map<String, dynamic> json) {
    return PublishedStudioCard(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      designJson: Map<String, dynamic>.from(json['designJson'] as Map? ?? {}),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      likes: json['likes'] as int? ?? 0,
    );
  }
}

class VerseStudioController extends ChangeNotifier {
  VerseStudioController({
    String? initialText,
    String? initialReference,
  }) : design = VerseDesign(
          verseText: initialText ?? '',
          reference: initialReference ?? '',
        ) {
    _detectMood();
    MoodEngine.applyMood(design, VerseMood.auto);
  }

  final VerseDesign design;
  final MagicDesignEngine _magic = MagicDesignEngine();
  final List<String> _undoStack = [];
  static const _templatesKey = 'verse_studio_templates_v1';
  static const _challengeKey = 'verse_studio_challenge_v1';
  static const _galleryKey = 'verse_studio_local_gallery_v1';
  static const _maxUndo = 30;

  StudioToolTab activeTab = StudioToolTab.background;
  StudioLayerId selectedLayer = StudioLayerId.verse;
  bool magicPulse = false;
  bool animateMotion = true;
  String? backgroundCategory;
  List<SavedStudioTemplate> templates = [];
  List<PublishedStudioCard> gallery = [];
  StudioChallengeProgress? challenge;

  bool get canUndo => _undoStack.isNotEmpty;

  void _detectMood() {
    design.detectedMood = MoodEngine.detect(
      design.verseText,
      reference: design.reference,
    );
  }

  void _pushUndo() {
    _undoStack.add(jsonEncode(design.toJson()));
    if (_undoStack.length > _maxUndo) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final raw = _undoStack.removeLast();
    try {
      design.applyFrom(
        VerseDesign.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map)),
      );
      notifyListeners();
    } catch (_) {}
  }

  void _mutate(VoidCallback fn) {
    _pushUndo();
    fn();
    notifyListeners();
  }

  void setVerseText(String value) {
    design.verseText = value;
    _detectMood();
    if (design.mood == VerseMood.auto) {
      MoodEngine.applyMood(design, VerseMood.auto);
    }
    notifyListeners();
  }

  void setReference(String value) {
    design.reference = value;
    _detectMood();
    notifyListeners();
  }

  void setTab(StudioToolTab tab) {
    activeTab = tab;
    notifyListeners();
  }

  void selectLayer(StudioLayerId layer) {
    selectedLayer = layer;
    notifyListeners();
  }

  void setExportPreset(StudioExportPreset preset) => _mutate(() {
        design.exportPreset = preset;
      });

  void setLayout(StudioLayoutPreset layout) => _mutate(() {
        design.layout = layout;
      });

  void setGradient(String id) => _mutate(() {
        design.gradientId = id;
      });

  void setBackgroundCategory(String? category) {
    backgroundCategory = category;
    notifyListeners();
  }

  void setFont(StudioFontId id) => _mutate(() => design.fontId = id);

  void setFontSize(double size) {
    design.fontSize = size.clamp(14, 48);
    notifyListeners();
  }

  void setTextColor(Color color) =>
      _mutate(() => design.textColorValue = color.toARGB32());

  void setAccentColor(Color color) =>
      _mutate(() => design.accentColorValue = color.toARGB32());

  void setTextAlign(TextAlign align) => _mutate(() => design.textAlign = align);

  void setLetterSpacing(double value) {
    design.letterSpacing = value;
    notifyListeners();
  }

  void setLineHeight(double value) {
    design.lineHeight = value;
    notifyListeners();
  }

  void setEffect(StudioTextEffect effect) =>
      _mutate(() => design.effect = effect);

  void setGlass(bool enabled) => _mutate(() => design.glassEnabled = enabled);

  void setSmartBreaks(bool enabled) =>
      _mutate(() => design.smartBreaks = enabled);

  void setMood(VerseMood mood) => _mutate(() {
        design.mood = mood;
        MoodEngine.applyMood(design, mood, variant: DateTime.now().day);
        final rec = StudioPaletteEngine.recommend(design.effectiveMood).first;
        design.gradientId = rec.backgroundGradientId;
        design.textColorValue = rec.textColorValue;
        design.accentColorValue = rec.accentColorValue;
      });

  void applyPalette(ColorPaletteRec rec) => _mutate(() {
        design.gradientId = rec.backgroundGradientId;
        design.textColorValue = rec.textColorValue;
        design.accentColorValue = rec.accentColorValue;
      });

  void setDecor(StudioDecorId decor) => _mutate(() => design.decor = decor);

  void setTexture(StudioTextureId texture) =>
      _mutate(() => design.texture = texture);

  void setFrame(StudioFrameId frame) => _mutate(() => design.frame = frame);

  void setMotion(StudioMotionId motion) =>
      _mutate(() => design.motion = motion);

  void setScenicPack(String id) => _mutate(() {
        design.scenicPackId = id;
        if (id != 'none') {
          // Scenic art replaces flat gradient mood washes.
          design.gradientId = 'dark_mode';
        }
      });

  void setPhotoFilter(StudioPhotoFilter filter) =>
      _mutate(() => design.photoFilter = filter);

  void setTextPath(StudioTextPath path) =>
      _mutate(() => design.textPath = path);

  void setShowLogo(bool show) => _mutate(() => design.showLogo = show);

  void setQuoteAnimation(bool enabled) =>
      _mutate(() => design.quoteAnimation = enabled);

  void setAnimateMotion(bool enabled) {
    animateMotion = enabled;
    notifyListeners();
  }

  void setPhotoPath(String? path) => _mutate(() => design.photoPath = path);

  void setPhotoBlur(double value) {
    design.photoBlur = value;
    notifyListeners();
  }

  void setPhotoBrightness(double value) {
    design.photoBrightness = value;
    notifyListeners();
  }

  void setPhotoContrast(double value) {
    design.photoContrast = value;
    notifyListeners();
  }

  void setPhotoSaturation(double value) {
    design.photoSaturation = value;
    notifyListeners();
  }

  void setPhotoDarken(double value) {
    design.photoDarken = value;
    notifyListeners();
  }

  void updateLayerTransform(StudioLayerId layer, LayerTransform transform) {
    switch (layer) {
      case StudioLayerId.verse:
        design.verseTransform = transform;
      case StudioLayerId.reference:
        design.referenceTransform = transform;
      case StudioLayerId.logo:
        design.logoTransform = transform;
      case StudioLayerId.decor:
        design.decorTransform = transform;
    }
    notifyListeners();
  }

  void commitLayerGesture() => _pushUndo();

  void toggleWordHighlight(int wordIndex, int colorValue) => _mutate(() {
        final existing =
            design.highlights.indexWhere((h) => h.wordIndex == wordIndex);
        if (existing >= 0) {
          design.highlights.removeAt(existing);
        } else {
          design.highlights.add(
            WordHighlight(wordIndex: wordIndex, colorValue: colorValue),
          );
        }
      });

  void clearHighlights() => _mutate(() => design.highlights.clear());

  void magicDesign() {
    _pushUndo();
    _magic.apply(design);
    magicPulse = true;
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      magicPulse = false;
      notifyListeners();
    });
  }

  Future<void> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_templatesKey);
    if (raw == null) {
      templates = [];
    } else {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        templates = list
            .map(
              (e) => SavedStudioTemplate.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      } catch (_) {
        templates = [];
      }
    }
    final galleryRaw = prefs.getString(_galleryKey);
    if (galleryRaw != null) {
      try {
        final list = jsonDecode(galleryRaw) as List<dynamic>;
        gallery = list
            .map(
              (e) => PublishedStudioCard.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      } catch (_) {
        gallery = [];
      }
    }
    notifyListeners();
  }

  Future<void> saveTemplate(String name) async {
    final copy = design.copy()..templateName = name;
    templates = [
      SavedStudioTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        design: copy,
        savedAt: DateTime.now(),
      ),
      ...templates,
    ];
    await _persistTemplates();
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    templates.removeWhere((t) => t.id == id);
    await _persistTemplates();
    notifyListeners();
  }

  Future<void> applyTemplate(SavedStudioTemplate template) async {
    _pushUndo();
    final loaded = template.design.copy();
    if (loaded.verseText.trim().isEmpty && design.verseText.trim().isNotEmpty) {
      loaded.verseText = design.verseText;
      loaded.reference = design.reference;
    }
    design.applyFrom(loaded);
    notifyListeners();
  }

  Future<void> _persistTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _templatesKey,
      jsonEncode(templates.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> publishToLocalGallery() async {
    final card = PublishedStudioCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: design.reference.isEmpty ? 'Untitled verse' : design.reference,
      reference: design.reference,
      designJson: design.toJson(),
      savedAt: DateTime.now(),
    );
    gallery = [card, ...gallery];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _galleryKey,
      jsonEncode(gallery.map((g) => g.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> likeGalleryCard(String id) async {
    final index = gallery.indexWhere((g) => g.id == id);
    if (index < 0) return;
    gallery[index].likes += 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _galleryKey,
      jsonEncode(gallery.map((g) => g.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> loadChallenge({
    required String verseText,
    required String reference,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    var progress = StudioChallengeProgress(
      dayKey: today,
      verseText: verseText,
      reference: reference,
      completed: false,
    );
    final raw = prefs.getString(_challengeKey);
    if (raw != null) {
      try {
        final stored = StudioChallengeProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        if (stored.dayKey == today) progress = stored;
      } catch (_) {}
    }
    if (design.verseText.trim().isEmpty) {
      design.verseText = progress.verseText;
      design.reference = progress.reference;
      _detectMood();
      MoodEngine.applyMood(design, VerseMood.auto);
    }
    challenge = progress;
    notifyListeners();
  }

  Future<void> completeChallenge() async {
    if (challenge == null) return;
    challenge = StudioChallengeProgress(
      dayKey: challenge!.dayKey,
      verseText: challenge!.verseText,
      reference: challenge!.reference,
      completed: true,
      badge: 'Verse Artist',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_challengeKey, jsonEncode(challenge!.toJson()));
    notifyListeners();
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
