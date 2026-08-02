import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'gradient_library.dart';
import 'mood_engine.dart';
import 'scenic_backgrounds.dart';
import 'studio_fonts.dart';
import 'verse_design.dart';
import 'verse_studio_controller.dart';

class StudioToolbar extends StatelessWidget {
  const StudioToolbar({
    super.key,
    required this.controller,
    required this.onPickPhoto,
    required this.onClearPhoto,
    required this.onSaveTemplate,
    required this.onPublishGallery,
    required this.onPublishCommunity,
    required this.onExportAnimation,
  });

  final VerseStudioController controller;
  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;
  final VoidCallback onSaveTemplate;
  final VoidCallback onPublishGallery;
  final VoidCallback onPublishCommunity;
  final VoidCallback onExportAnimation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;
    final design = controller.design;

    return Material(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final tab in StudioToolTab.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_tabLabel(tab)),
                      selected: controller.activeTab == tab,
                      onSelected: (_) => controller.setTab(tab),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _panel(context, design, ink, soft),
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(StudioToolTab tab) {
    switch (tab) {
      case StudioToolTab.background:
        return 'Background';
      case StudioToolTab.text:
        return 'Text';
      case StudioToolTab.font:
        return 'Font';
      case StudioToolTab.effects:
        return 'Effects';
      case StudioToolTab.layout:
        return 'Layout';
      case StudioToolTab.decor:
        return 'Decor';
      case StudioToolTab.export:
        return 'Export';
    }
  }

  Widget _panel(
    BuildContext context,
    VerseDesign design,
    Color ink,
    Color soft,
  ) {
    switch (controller.activeTab) {
      case StudioToolTab.background:
        return _BackgroundPanel(
          controller: controller,
          design: design,
          soft: soft,
          onPickPhoto: onPickPhoto,
          onClearPhoto: onClearPhoto,
        );
      case StudioToolTab.text:
        return _TextPanel(controller: controller, design: design, ink: ink);
      case StudioToolTab.font:
        return _FontPanel(controller: controller, design: design, soft: soft);
      case StudioToolTab.effects:
        return _EffectsPanel(
          controller: controller,
          design: design,
          soft: soft,
        );
      case StudioToolTab.layout:
        return _LayoutPanel(controller: controller, design: design, soft: soft);
      case StudioToolTab.decor:
        return _DecorPanel(
          controller: controller,
          design: design,
          soft: soft,
          onSaveTemplate: onSaveTemplate,
        );
      case StudioToolTab.export:
        return _ExportPanel(
          controller: controller,
          design: design,
          soft: soft,
          onPublishGallery: onPublishGallery,
          onPublishCommunity: onPublishCommunity,
          onExportAnimation: onExportAnimation,
        );
    }
  }
}

class _BackgroundPanel extends StatelessWidget {
  const _BackgroundPanel({
    required this.controller,
    required this.design,
    required this.soft,
    required this.onPickPhoto,
    required this.onClearPhoto,
  });

  final VerseStudioController controller;
  final VerseDesign design;
  final Color soft;
  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;

  @override
  Widget build(BuildContext context) {
    final category = controller.backgroundCategory;
    final gradients = category == null
        ? StudioGradientLibrary.all
        : StudioGradientLibrary.byCategory(category);

    return ListView(
      children: [
        Text('Theme / Mood', style: AppTheme.ui(fontSize: 12, color: soft)),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final mood in VerseMood.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      mood == VerseMood.auto
                          ? 'Auto · ${MoodEngine.labelFor(design.detectedMood)}'
                          : MoodEngine.labelFor(mood),
                      style: AppTheme.ui(fontSize: 11),
                    ),
                    selected: design.mood == mood,
                    onSelected: (_) => controller.setMood(mood),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Palette', style: AppTheme.ui(fontSize: 12, color: soft)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: [
            for (final rec
                in StudioPaletteEngine.recommend(design.effectiveMood))
              ActionChip(
                label: Text(rec.name),
                onPressed: () => controller.applyPalette(rec),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Scenic packs (original art)',
            style: AppTheme.ui(fontSize: 12, color: soft)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('None'),
              selected: design.scenicPackId == 'none',
              onSelected: (_) => controller.setScenicPack('none'),
            ),
            for (final pack in ScenicPackLibrary.packs)
              ChoiceChip(
                label: Text(pack.name),
                selected: design.scenicPackId == pack.id.name,
                onSelected: (_) => controller.setScenicPack(pack.id.name),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Categories', style: AppTheme.ui(fontSize: 12, color: soft)),
        const SizedBox(height: 4),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: category == null,
                  onSelected: (_) => controller.setBackgroundCategory(null),
                ),
              ),
              for (final c in StudioGradientLibrary.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: category == c,
                    onSelected: (_) => controller.setBackgroundCategory(c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: gradients.length,
            itemBuilder: (context, index) {
              final g = gradients[index];
              final selected = design.gradientId == g.id;
              return GestureDetector(
                onTap: () => controller.setGradient(g.id),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: g.toGradient(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppTheme.gold : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: onPickPhoto,
              icon: const Icon(Icons.photo_outlined, size: 18),
              label: const Text('Photo'),
            ),
            if (design.photoPath != null)
              TextButton(onPressed: onClearPhoto, child: const Text('Clear')),
          ],
        ),
        if (design.photoPath != null) ...[
          Text('Filter', style: AppTheme.ui(fontSize: 11, color: soft)),
          Wrap(
            spacing: 6,
            children: [
              for (final f in StudioPhotoFilter.values)
                ChoiceChip(
                  label: Text(f.name),
                  selected: design.photoFilter == f,
                  onSelected: (_) => controller.setPhotoFilter(f),
                ),
            ],
          ),
          Text('Darken', style: AppTheme.ui(fontSize: 11, color: soft)),
          Slider(
            value: design.photoDarken,
            min: 0,
            max: 0.8,
            onChanged: controller.setPhotoDarken,
          ),
          Text('Blur', style: AppTheme.ui(fontSize: 11, color: soft)),
          Slider(
            value: design.photoBlur,
            min: 0,
            max: 12,
            onChanged: controller.setPhotoBlur,
          ),
          Text('Brightness', style: AppTheme.ui(fontSize: 11, color: soft)),
          Slider(
            value: design.photoBrightness,
            min: -1,
            max: 1,
            onChanged: controller.setPhotoBrightness,
          ),
          Text('Contrast', style: AppTheme.ui(fontSize: 11, color: soft)),
          Slider(
            value: design.photoContrast,
            min: -0.5,
            max: 1,
            onChanged: controller.setPhotoContrast,
          ),
          Text('Saturation', style: AppTheme.ui(fontSize: 11, color: soft)),
          Slider(
            value: design.photoSaturation,
            min: -1,
            max: 1,
            onChanged: controller.setPhotoSaturation,
          ),
        ],
      ],
    );
  }
}

class _TextPanel extends StatefulWidget {
  const _TextPanel({
    required this.controller,
    required this.design,
    required this.ink,
  });

  final VerseStudioController controller;
  final VerseDesign design;
  final Color ink;

  @override
  State<_TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends State<_TextPanel> {
  late final TextEditingController _verse;
  late final TextEditingController _reference;

  @override
  void initState() {
    super.initState();
    _verse = TextEditingController(text: widget.design.verseText);
    _reference = TextEditingController(text: widget.design.reference);
  }

  @override
  void didUpdateWidget(covariant _TextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_verse.text != widget.design.verseText) {
      _verse.text = widget.design.verseText;
    }
    if (_reference.text != widget.design.reference) {
      _reference.text = widget.design.reference;
    }
  }

  @override
  void dispose() {
    _verse.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TextField(
          controller: _verse,
          maxLines: 3,
          style: AppTheme.scripture(fontSize: 14, color: widget.ink),
          decoration: const InputDecoration(labelText: 'Verse'),
          onChanged: widget.controller.setVerseText,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reference,
          style: AppTheme.ui(fontSize: 13, color: widget.ink),
          decoration: const InputDecoration(labelText: 'Reference'),
          onChanged: widget.controller.setReference,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Smart line breaks', style: AppTheme.ui(fontSize: 13)),
          value: widget.design.smartBreaks,
          onChanged: widget.controller.setSmartBreaks,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Quote fade-in', style: AppTheme.ui(fontSize: 13)),
          value: widget.design.quoteAnimation,
          onChanged: widget.controller.setQuoteAnimation,
        ),
        Text('Text path', style: AppTheme.ui(fontSize: 12)),
        Wrap(
          spacing: 6,
          children: [
            for (final p in StudioTextPath.values)
              ChoiceChip(
                label: Text(p.name),
                selected: widget.design.textPath == p,
                onSelected: (_) => widget.controller.setTextPath(p),
              ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => widget.controller.setTextAlign(TextAlign.left),
              icon: Icon(
                Icons.format_align_left,
                color: widget.design.textAlign == TextAlign.left
                    ? AppTheme.gold
                    : null,
              ),
            ),
            IconButton(
              onPressed: () => widget.controller.setTextAlign(TextAlign.center),
              icon: Icon(
                Icons.format_align_center,
                color: widget.design.textAlign == TextAlign.center
                    ? AppTheme.gold
                    : null,
              ),
            ),
            IconButton(
              onPressed: () => widget.controller.setTextAlign(TextAlign.right),
              icon: Icon(
                Icons.format_align_right,
                color: widget.design.textAlign == TextAlign.right
                    ? AppTheme.gold
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FontPanel extends StatelessWidget {
  const _FontPanel({
    required this.controller,
    required this.design,
    required this.soft,
  });

  final VerseStudioController controller;
  final VerseDesign design;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final entry in StudioFonts.categories.entries) ...[
          Text(entry.key, style: AppTheme.ui(fontSize: 11, color: soft)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in entry.value)
                ChoiceChip(
                  label: Text(StudioFonts.labels[id] ?? id.name),
                  selected: design.fontId == id,
                  onSelected: (_) => controller.setFont(id),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text('Size ${design.fontSize.round()}',
            style: AppTheme.ui(fontSize: 12, color: soft)),
        Slider(
          value: design.fontSize,
          min: 16,
          max: 42,
          onChanged: controller.setFontSize,
        ),
        Text('Letter spacing', style: AppTheme.ui(fontSize: 11, color: soft)),
        Slider(
          value: design.letterSpacing,
          min: -0.5,
          max: 3,
          onChanged: controller.setLetterSpacing,
        ),
        Text('Line height', style: AppTheme.ui(fontSize: 11, color: soft)),
        Slider(
          value: design.lineHeight,
          min: 1.1,
          max: 2.0,
          onChanged: controller.setLineHeight,
        ),
      ],
    );
  }
}

class _EffectsPanel extends StatelessWidget {
  const _EffectsPanel({
    required this.controller,
    required this.design,
    required this.soft,
  });

  final VerseStudioController controller;
  final VerseDesign design;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final words = SmartVerseFormatter.words(design.verseText);
    return ListView(
      children: [
        Text('Text effect', style: AppTheme.ui(fontSize: 12, color: soft)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final effect in StudioTextEffect.values)
              ChoiceChip(
                label: Text(effect.name),
                selected: design.effect == effect,
                onSelected: (_) => controller.setEffect(effect),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Glass card', style: AppTheme.ui(fontSize: 13)),
          value: design.glassEnabled,
          onChanged: controller.setGlass,
        ),
        Text('Text color', style: AppTheme.ui(fontSize: 12, color: soft)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final c in [
              Colors.white,
              AppTheme.goldSoft,
              AppTheme.gold,
              AppTheme.ink,
              const Color(0xFFF6F0E1),
            ])
              GestureDetector(
                onTap: () => controller.setTextColor(c),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: design.textColorValue == c.toARGB32()
                          ? AppTheme.gold
                          : Colors.white24,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Word highlight', style: AppTheme.ui(fontSize: 11, color: soft)),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < words.length; i++)
              ActionChip(
                label: Text(words[i]),
                onPressed: () => controller.toggleWordHighlight(
                  i,
                  i.isEven
                      ? AppTheme.gold.toARGB32()
                      : AppTheme.teal.toARGB32(),
                ),
              ),
          ],
        ),
        if (design.highlights.isNotEmpty)
          TextButton(
            onPressed: controller.clearHighlights,
            child: const Text('Clear highlights'),
          ),
      ],
    );
  }
}

class _LayoutPanel extends StatelessWidget {
  const _LayoutPanel({
    required this.controller,
    required this.design,
    required this.soft,
  });

  final VerseStudioController controller;
  final VerseDesign design;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final layout in StudioLayoutPreset.values)
              ChoiceChip(
                label: Text(layout.name),
                selected: design.layout == layout,
                onSelected: (_) => controller.setLayout(layout),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Select layer to drag / pinch / rotate',
            style: AppTheme.ui(fontSize: 12, color: soft)),
        Wrap(
          spacing: 6,
          children: [
            for (final layer in StudioLayerId.values)
              ChoiceChip(
                label: Text(layer.name),
                selected: controller.selectedLayer == layer,
                onSelected: (_) => controller.selectLayer(layer),
              ),
          ],
        ),
      ],
    );
  }
}

class _DecorPanel extends StatelessWidget {
  const _DecorPanel({
    required this.controller,
    required this.design,
    required this.soft,
    required this.onSaveTemplate,
  });

  final VerseStudioController controller;
  final VerseDesign design;
  final Color soft;
  final VoidCallback onSaveTemplate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Stickers', style: AppTheme.ui(fontSize: 12, color: soft)),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final decor in StudioDecorId.values)
              ChoiceChip(
                label: Text(decor.name),
                selected: design.decor == decor,
                onSelected: (_) => controller.setDecor(decor),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Frame', style: AppTheme.ui(fontSize: 12, color: soft)),
        Wrap(
          spacing: 6,
          children: [
            for (final f in StudioFrameId.values)
              ChoiceChip(
                label: Text(f.name),
                selected: design.frame == f,
                onSelected: (_) => controller.setFrame(f),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Texture', style: AppTheme.ui(fontSize: 12, color: soft)),
        Wrap(
          spacing: 6,
          children: [
            for (final t in StudioTextureId.values)
              ChoiceChip(
                label: Text(t.name),
                selected: design.texture == t,
                onSelected: (_) => controller.setTexture(t),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Motion preview', style: AppTheme.ui(fontSize: 12, color: soft)),
        Wrap(
          spacing: 6,
          children: [
            for (final m in StudioMotionId.values)
              ChoiceChip(
                label: Text(m.name),
                selected: design.motion == m,
                onSelected: (_) => controller.setMotion(m),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Animate motion', style: AppTheme.ui(fontSize: 13)),
          value: controller.animateMotion,
          onChanged: controller.setAnimateMotion,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('BiblePulse logo', style: AppTheme.ui(fontSize: 13)),
          value: design.showLogo,
          onChanged: controller.setShowLogo,
        ),
        FilledButton.tonal(
          onPressed: onSaveTemplate,
          child: const Text('Save to My Templates'),
        ),
        if (controller.templates.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('My Templates', style: AppTheme.ui(fontSize: 12, color: soft)),
          ...controller.templates.take(5).map(
                (t) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.name, style: AppTheme.ui(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => controller.deleteTemplate(t.id),
                  ),
                  onTap: () => controller.applyTemplate(t),
                ),
              ),
        ],
      ],
    );
  }
}

class _ExportPanel extends StatelessWidget {
  const _ExportPanel({
    required this.controller,
    required this.design,
    required this.soft,
    required this.onPublishGallery,
    required this.onPublishCommunity,
    required this.onExportAnimation,
  });

  final VerseStudioController controller;
  final VerseDesign design;
  final Color soft;
  final VoidCallback onPublishGallery;
  final VoidCallback onPublishCommunity;
  final VoidCallback onExportAnimation;

  @override
  Widget build(BuildContext context) {
    final challenge = controller.challenge;
    final px = design.exportPixelSize;
    return ListView(
      children: [
        Text(
          'Social size · ${px.width.toInt()}×${px.height.toInt()}',
          style: AppTheme.ui(fontSize: 12, color: soft),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in StudioExportPreset.values)
              ChoiceChip(
                label: Text(preset.name),
                selected: design.exportPreset == preset,
                onSelected: (_) => controller.setExportPreset(preset),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onExportAnimation,
          icon: const Icon(Icons.movie_creation_outlined),
          label: const Text('Export animated MP4 / GIF'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: onPublishCommunity,
          child: const Text('Publish to Community'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: onPublishGallery,
          child: const Text('Save to My Gallery'),
        ),
        if (controller.gallery.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'My Gallery (local)',
            style: AppTheme.ui(fontSize: 12, color: soft),
          ),
          ...controller.gallery.take(4).map(
                (g) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(g.title, style: AppTheme.ui(fontSize: 13)),
                  subtitle: Text('${g.likes} likes · ${g.reference}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite_border, size: 18),
                    onPressed: () => controller.likeGalleryCard(g.id),
                  ),
                  onTap: () {
                    controller.applyTemplate(
                      SavedStudioTemplate(
                        id: g.id,
                        name: g.title,
                        design: VerseDesign.fromJson(g.designJson),
                        savedAt: g.savedAt,
                      ),
                    );
                  },
                ),
              ),
        ],
        if (challenge != null) ...[
          const SizedBox(height: 8),
          Text(
            'Daily Challenge',
            style: AppTheme.ui(fontSize: 12, color: soft),
          ),
          Text(
            challenge.completed
                ? 'Badge: ${challenge.badge ?? 'Verse Artist'}'
                : 'Today: ${challenge.reference}',
            style: AppTheme.ui(fontSize: 13),
          ),
        ],
      ],
    );
  }
}
