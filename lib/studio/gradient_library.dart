import 'package:flutter/material.dart';

import 'verse_design.dart';

class StudioGradientLibrary {
  StudioGradientLibrary._();

  static const categories = [
    'AI Gradients',
    'Nature',
    'Ocean',
    'Sky',
    'Galaxy',
    'Minimal',
    'Luxury',
    'Abstract',
    'Dark',
    'Seasonal',
  ];

  static final List<StudioGradientSpec> all = [
    const StudioGradientSpec(
      id: 'purple_pink',
      name: 'Purple → Pink',
      category: 'AI Gradients',
      colors: [Color(0xFF5B2C6F), Color(0xFFE8A0BF)],
    ),
    const StudioGradientSpec(
      id: 'blue_cyan',
      name: 'Blue → Cyan',
      category: 'AI Gradients',
      colors: [Color(0xFF0B3D91), Color(0xFF56CCF2)],
    ),
    const StudioGradientSpec(
      id: 'orange_red',
      name: 'Orange → Red',
      category: 'AI Gradients',
      colors: [Color(0xFFE07A3D), Color(0xFFA83232)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    const StudioGradientSpec(
      id: 'emerald_teal',
      name: 'Emerald → Teal',
      category: 'AI Gradients',
      colors: [Color(0xFF0F3D34), Color(0xFF1E7F72)],
    ),
    const StudioGradientSpec(
      id: 'gold_black',
      name: 'Gold → Black',
      category: 'Luxury',
      colors: [Color(0xFFC08A28), Color(0xFF10182A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    const StudioGradientSpec(
      id: 'sunset',
      name: 'Sunset',
      category: 'Sky',
      colors: [Color(0xFFFF8A5B), Color(0xFF6B2D5C), Color(0xFF1B1430)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    const StudioGradientSpec(
      id: 'aurora',
      name: 'Aurora',
      category: 'Galaxy',
      colors: [Color(0xFF0B1D2A), Color(0xFF1E7F72), Color(0xFF7B5EA7)],
    ),
    const StudioGradientSpec(
      id: 'ocean',
      name: 'Ocean',
      category: 'Ocean',
      colors: [Color(0xFF0A2E36), Color(0xFF148C9C), Color(0xFF7FDBDA)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    const StudioGradientSpec(
      id: 'forest',
      name: 'Forest',
      category: 'Nature',
      colors: [Color(0xFF1A2F1C), Color(0xFF3D5A3E), Color(0xFF6E8B3D)],
    ),
    const StudioGradientSpec(
      id: 'mountain',
      name: 'Mountains',
      category: 'Nature',
      colors: [Color(0xFF2C3E50), Color(0xFF5D6D7E), Color(0xFFABB2B9)],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
    const StudioGradientSpec(
      id: 'sky_soft',
      name: 'Soft Sky',
      category: 'Sky',
      colors: [Color(0xFF87CEEB), Color(0xFFE8F4F8), Color(0xFFF6F0E1)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    const StudioGradientSpec(
      id: 'galaxy',
      name: 'Galaxy',
      category: 'Galaxy',
      colors: [Color(0xFF0B0B2B), Color(0xFF2E1A47), Color(0xFF7B5EA7)],
    ),
    const StudioGradientSpec(
      id: 'minimal_cream',
      name: 'Minimal Cream',
      category: 'Minimal',
      colors: [Color(0xFFF6F0E1), Color(0xFFE8DCC0)],
    ),
    const StudioGradientSpec(
      id: 'minimal_ink',
      name: 'Minimal Ink',
      category: 'Minimal',
      colors: [Color(0xFF161F33), Color(0xFF10182A)],
    ),
    const StudioGradientSpec(
      id: 'luxury_navy_gold',
      name: 'Navy Gold',
      category: 'Luxury',
      colors: [Color(0xFF10182A), Color(0xFF241804), Color(0xFFC08A28)],
    ),
    const StudioGradientSpec(
      id: 'abstract_violet',
      name: 'Abstract Violet',
      category: 'Abstract',
      colors: [Color(0xFF2C1654), Color(0xFF7B5EA7), Color(0xFFE8A0BF)],
    ),
    const StudioGradientSpec(
      id: 'dark_mode',
      name: 'Dark Mode',
      category: 'Dark',
      colors: [Color(0xFF0A0E17), Color(0xFF161F33)],
    ),
    const StudioGradientSpec(
      id: 'candlelight',
      name: 'Candlelight',
      category: 'Dark',
      colors: [Color(0xFF1A1208), Color(0xFF3D2A12), Color(0xFFC08A28)],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ),
    const StudioGradientSpec(
      id: 'blush_love',
      name: 'Blush Love',
      category: 'Abstract',
      colors: [Color(0xFF5C2A3A), Color(0xFFD4A5A5), Color(0xFFF6E8E8)],
    ),
    const StudioGradientSpec(
      id: 'christmas',
      name: 'Christmas',
      category: 'Seasonal',
      colors: [Color(0xFF1B4332), Color(0xFFA83232), Color(0xFFC08A28)],
    ),
    const StudioGradientSpec(
      id: 'easter',
      name: 'Easter Dawn',
      category: 'Seasonal',
      colors: [Color(0xFF6B8F71), Color(0xFFF6F0E1), Color(0xFFE8C766)],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
    const StudioGradientSpec(
      id: 'hope_sunrise',
      name: 'Hope Sunrise',
      category: 'Sky',
      colors: [Color(0xFFFFB347), Color(0xFFFF7E5F), Color(0xFF6B2D5C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    const StudioGradientSpec(
      id: 'peace_lake',
      name: 'Peace Lake',
      category: 'Ocean',
      colors: [Color(0xFF1E3A3A), Color(0xFF4A7C7C), Color(0xFFA8C5C5)],
    ),
    const StudioGradientSpec(
      id: 'majesty',
      name: 'Majesty',
      category: 'Luxury',
      colors: [Color(0xFF0A1628), Color(0xFF1B2540), Color(0xFFC08A28)],
    ),
  ];

  static StudioGradientSpec byId(String id) {
    return all.firstWhere(
      (g) => g.id == id,
      orElse: () => all.firstWhere((g) => g.id == 'emerald_teal'),
    );
  }

  static List<StudioGradientSpec> byCategory(String category) {
    return all.where((g) => g.category == category).toList();
  }
}
