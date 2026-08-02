import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_capabilities.dart';
import '../providers/community_provider.dart';
import '../services/auth_service.dart';
import '../services/daily_verse_service.dart';
import '../studio/mood_engine.dart';
import '../studio/studio_animation_exporter.dart';
import '../studio/studio_canvas.dart';
import '../studio/studio_toolbar.dart';
import '../studio/verse_design.dart';
import '../studio/verse_studio_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

class WallpaperGeneratorScreen extends StatefulWidget {
  const WallpaperGeneratorScreen({super.key});

  @override
  State<WallpaperGeneratorScreen> createState() =>
      _WallpaperGeneratorScreenState();
}

class _WallpaperGeneratorScreenState extends State<WallpaperGeneratorScreen> {
  final GlobalKey _exportKey = GlobalKey();
  VerseStudioController? _studio;
  bool _initializedFromRoute = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromRoute) return;
    _initializedFromRoute = true;

    String? text;
    String? reference;
    Map<String, dynamic>? designJson;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      text = arguments['text'] as String?;
      reference = arguments['reference'] as String?;
      if (arguments['designJson'] is Map) {
        designJson = Map<String, dynamic>.from(arguments['designJson'] as Map);
      }
    }

    final studio = VerseStudioController(
      initialText: text,
      initialReference: reference,
    );
    if (designJson != null) {
      studio.design.applyFrom(VerseDesign.fromJson(designJson));
    }
    _studio = studio;
    studio.loadTemplates();
    _seedChallenge(studio);
  }

  Future<void> _seedChallenge(VerseStudioController studio) async {
    try {
      final verse = await DailyVerseService().verseForToday(versionId: 'WEB');
      if (verse == null) {
        await studio.loadChallenge(
          verseText: studio.design.verseText.isEmpty
              ? 'The Lord is my shepherd; I shall lack nothing.'
              : studio.design.verseText,
          reference: studio.design.reference.isEmpty
              ? 'Psalm 23:1'
              : studio.design.reference,
        );
        return;
      }
      const names = {
        19: 'Psalm',
        43: 'John',
        40: 'Matthew',
        45: 'Romans',
        20: 'Proverbs',
      };
      final book = names[verse.book] ?? 'Bible';
      await studio.loadChallenge(
        verseText: verse.text,
        reference: '$book ${verse.chapter}:${verse.verse}',
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _studio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studio = _studio;
    if (studio == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedBuilder(
      animation: studio,
      builder: (context, _) {
        final capabilities = context.watch<AppCapabilities>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
        final design = studio.design;
        final px = design.exportPixelSize;

        Widget preview = AspectRatio(
          aspectRatio: design.aspectRatio,
          child: StudioCanvas(
            design: design,
            controller: studio,
            animateMotion: studio.animateMotion,
          ),
        );

        if (studio.magicPulse) {
          preview = preview
              .animate()
              .fadeIn(duration: 280.ms)
              .shimmer(duration: 500.ms, color: AppTheme.goldSoft);
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      BpIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verse Studio',
                              style:
                                  AppTheme.brandTitle(fontSize: 20, color: ink),
                            ),
                            Text(
                              '${MoodEngine.labelFor(design.effectiveMood)} · ${px.width.toInt()}×${px.height.toInt()}',
                              style: AppTheme.ui(
                                fontSize: 11,
                                color: isDark
                                    ? AppTheme.inkSoftDark
                                    : AppTheme.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      BpIconButton(
                        icon: Icons.undo_rounded,
                        tooltip: 'Undo',
                        onPressed: studio.canUndo ? studio.undo : null,
                      ),
                      BpIconButton(
                        icon: Icons.auto_awesome,
                        tooltip: 'Magic Design',
                        onPressed: studio.magicDesign,
                      ),
                      BpIconButton(
                        icon: Icons.download_rounded,
                        tooltip: capabilities.wallpaperExport
                            ? 'Save ${px.width.toInt()}×${px.height.toInt()}'
                            : 'Save unavailable on this platform',
                        onPressed: capabilities.wallpaperExport && !_busy
                            ? () => _saveWallpaper(studio)
                            : null,
                      ),
                      BpIconButton(
                        icon: Icons.share_rounded,
                        tooltip: 'Share',
                        onPressed: _busy ? null : () => _shareCard(studio),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final preset in StudioExportPreset.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(preset.name),
                              selected: design.exportPreset == preset,
                              onSelected: (_) => studio.setExportPreset(preset),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        alignment: Alignment.center,
                        children: [
                          preview,
                          // Hidden full-pixel renderer for exact export.
                          Positioned(
                            left: 0,
                            top: 0,
                            width: 1,
                            height: 1,
                            child: IgnorePointer(
                              child: OverflowBox(
                                alignment: Alignment.topLeft,
                                minWidth: px.width,
                                maxWidth: px.width,
                                minHeight: px.height,
                                maxHeight: px.height,
                                child: Opacity(
                                  opacity: 0,
                                  child: RepaintBoundary(
                                    key: _exportKey,
                                    child: StudioCanvas(
                                      design: design,
                                      editable: false,
                                      animateMotion: false,
                                      forExport: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                StudioToolbar(
                  controller: studio,
                  onPickPhoto: () => _pickPhoto(studio),
                  onClearPhoto: () => studio.setPhotoPath(null),
                  onSaveTemplate: () => _saveTemplate(studio),
                  onPublishGallery: () async {
                    await studio.publishToLocalGallery();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved to My Gallery (this device)'),
                      ),
                    );
                  },
                  onPublishCommunity: () => _publishCommunity(studio),
                  onExportAnimation: () => _exportAnimation(studio),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _publishCommunity(VerseStudioController studio) async {
    final capabilities = context.read<AppCapabilities>();
    if (!capabilities.community) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community needs cloud sign-in (Firebase).'),
        ),
      );
      return;
    }
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to publish to Community.')),
      );
      return;
    }
    try {
      await context.read<CommunityProvider>().publishVerseDesign(
            userId: user.uid,
            verseText: studio.design.verseText,
            reference: studio.design.reference,
            designJson: studio.design.toJson(),
            authorName: user.email ?? user.uid.substring(0, 6),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Published to Community')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish: $e')),
      );
    }
  }

  Future<void> _exportAnimation(VerseStudioController studio) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Animated export works on mobile/desktop.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await StudioAnimationExporter().export(
        context: context,
        design: studio.design,
      );
      await Share.shareXFiles(
        [XFile(result.filePath)],
        text: studio.design.reference,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Animation export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto(VerseStudioController studio) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo backgrounds work best on mobile.')),
      );
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) studio.setPhotoPath(picked.path);
  }

  Future<void> _saveTemplate(VerseStudioController studio) async {
    final nameController = TextEditingController(text: 'My Favorites');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save template'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || name.isEmpty) return;
    await studio.saveTemplate(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved “$name”')),
    );
  }

  Future<Uint8List?> _captureExact(VerseStudioController studio) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final boundary =
        _exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _shareCard(VerseStudioController studio) async {
    setState(() => _busy = true);
    try {
      final bytes = await _captureExact(studio);
      if (bytes == null) return;
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'biblepulse-verse-studio.png',
          ),
        ],
        text: studio.design.reference,
      );
      if (studio.challenge != null && !studio.challenge!.completed) {
        await studio.completeChallenge();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveWallpaper(VerseStudioController studio) async {
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Wallpaper save works on mobile. On web, use Share.',
                style: AppTheme.ui(fontSize: 13),
              ),
            ),
          );
        }
        return;
      }

      await Permission.storage.request();
      final image = await _captureExact(studio);
      if (image != null) {
        await ImageGallerySaverPlus.saveImage(image);
        if (studio.challenge != null && !studio.challenge!.completed) {
          await studio.completeChallenge();
        }
        if (mounted) {
          final px = studio.design.exportPixelSize;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saved ${px.width.toInt()}×${px.height.toInt()} PNG',
                style: AppTheme.ui(fontSize: 13),
              ),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save wallpaper on this device.',
              style: AppTheme.ui(fontSize: 13),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
