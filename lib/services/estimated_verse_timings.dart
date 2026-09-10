import 'audio_contracts.dart';

/// Builds approximate verse timings when no licensed timestamp file exists.
/// Weights each verse by text length so longer verses get more playback time.
List<AudioVerseTiming> estimateVerseTimings({
  required List<int> verseCharWeights,
  required Duration totalDuration,
}) {
  if (verseCharWeights.isEmpty || totalDuration <= Duration.zero) {
    return const [];
  }

  final weights = verseCharWeights.map((w) => w.clamp(1, 10000)).toList();
  final totalWeight = weights.fold<int>(0, (sum, w) => sum + w);
  if (totalWeight <= 0) return const [];

  var elapsedMs = 0;
  final totalMs = totalDuration.inMilliseconds;
  final timings = <AudioVerseTiming>[];

  for (var i = 0; i < weights.length; i++) {
    final verseMs = (totalMs * weights[i] / totalWeight).round();
    final start = Duration(milliseconds: elapsedMs);
    elapsedMs += verseMs;
    final end = i == weights.length - 1
        ? totalDuration
        : Duration(milliseconds: elapsedMs);
    timings.add(
      AudioVerseTiming(
        verse: i + 1,
        start: start,
        end: end,
      ),
    );
  }

  return timings;
}
