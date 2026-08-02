import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'studio_canvas.dart';
import 'verse_design.dart';

class StudioAnimationExportResult {
  const StudioAnimationExportResult({
    required this.filePath,
    required this.isMp4,
    required this.message,
  });

  final String filePath;
  final bool isMp4;
  final String message;
}

/// Captures motion frames → MP4 (FFmpeg Kit / system ffmpeg) or animated GIF.
class StudioAnimationExporter {
  Future<StudioAnimationExportResult> export({
    required BuildContext context,
    required VerseDesign design,
    int frameCount = 24,
    int fps = 12,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Animated export is not available on web.');
    }

    final px = design.exportPixelSize;
    final width = px.width > 1080 ? 1080.0 : px.width;
    final height = width / design.aspectRatio;

    final frames = <Uint8List>[];
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    final keys = List.generate(frameCount, (_) => GlobalKey());

    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: -20000,
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  for (var i = 0; i < frameCount; i++)
                    Positioned(
                      left: i * (width + 8),
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: RepaintBoundary(
                          key: keys[i],
                          child: StudioCanvas(
                            design: design.copy()
                              ..motion = design.motion == StudioMotionId.none
                                  ? StudioMotionId.sparkles
                                  : design.motion,
                            editable: false,
                            animateMotion: false,
                            forExport: true,
                            motionProgress: i / (frameCount - 1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    await WidgetsBinding.instance.endOfFrame;

    try {
      for (var i = 0; i < frameCount; i++) {
        final boundary = keys[i].currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) continue;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) frames.add(bytes.buffer.asUint8List());
      }
    } finally {
      entry.remove();
    }

    if (frames.length < 2) {
      throw StateError('Could not capture animation frames.');
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final frameDir = Directory(p.join(dir.path, 'bp_anim_$stamp'));
    await frameDir.create(recursive: true);

    for (var i = 0; i < frames.length; i++) {
      final file = File(
        p.join(frameDir.path, 'frame_${i.toString().padLeft(3, '0')}.png'),
      );
      await file.writeAsBytes(frames[i]);
    }

    final mp4Path = p.join(dir.path, 'biblepulse_$stamp.mp4');
    final pattern = p.join(frameDir.path, 'frame_%03d.png');
    final mp4Ok = await _tryEncodeMp4(
      framePattern: pattern,
      outputPath: mp4Path,
      fps: fps,
    );

    if (mp4Ok) {
      return StudioAnimationExportResult(
        filePath: mp4Path,
        isMp4: true,
        message: 'MP4 wallpaper exported',
      );
    }

    final gifPath = p.join(dir.path, 'biblepulse_$stamp.gif');
    final encoder = img.GifEncoder(repeat: 0);
    for (final png in frames) {
      final decoded = img.decodePng(png);
      if (decoded == null) continue;
      encoder.addFrame(decoded, duration: (100 / fps).round().clamp(2, 50));
    }
    final gifBytes = encoder.finish();
    if (gifBytes == null) {
      throw StateError('GIF encode failed.');
    }
    await File(gifPath).writeAsBytes(gifBytes);
    return StudioAnimationExportResult(
      filePath: gifPath,
      isMp4: false,
      message:
          'Animated GIF exported (MP4 encoder unavailable on this device).',
    );
  }

  Future<bool> _tryEncodeMp4({
    required String framePattern,
    required String outputPath,
    required int fps,
  }) async {
    final command =
        '-y -framerate $fps -i "$framePattern" -c:v mpeg4 -q:v 5 "$outputPath"';

    // FFmpeg Kit is linked on Android / iOS / macOS. Windows CI strips the
    // native plugin (see tools/ci/strip_ffmpeg_windows_plugin.ps1).
    final useKit =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    if (useKit) {
      try {
        final session = await FFmpegKit.execute(command);
        final code = await session.getReturnCode();
        if (ReturnCode.isSuccess(code) && File(outputPath).existsSync()) {
          return true;
        }
      } catch (_) {}
    }

    try {
      final result = await Process.run(
        'ffmpeg',
        [
          '-y',
          '-framerate',
          '$fps',
          '-i',
          framePattern,
          '-c:v',
          'libx264',
          '-pix_fmt',
          'yuv420p',
          outputPath,
        ],
        runInShell: true,
      );
      if (result.exitCode == 0 && File(outputPath).existsSync()) {
        return true;
      }
    } catch (_) {}

    return false;
  }
}
