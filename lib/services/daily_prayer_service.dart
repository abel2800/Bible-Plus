class DailyPrayer {
  const DailyPrayer({
    required this.title,
    required this.body,
    required this.focus,
  });

  final String title;
  final String body;
  final String focus;
}

/// Rotating original daily prayers (not third-party devotionals).
/// Index is stable for a calendar day so every user sees the same prayer
/// that day, and a different one the next.
class DailyPrayerService {
  DailyPrayerService._();

  static int indexForDate(DateTime local) {
    final day = DateTime(local.year, local.month, local.day);
    return day.difference(DateTime(local.year)).inDays;
  }

  static DailyPrayer forToday([DateTime? now]) {
    return forDate(now ?? DateTime.now());
  }

  static DailyPrayer forDate(DateTime local) {
    final catalog = prayers;
    return catalog[indexForDate(local) % catalog.length];
  }

  static const List<DailyPrayer> prayers = [
    DailyPrayer(
      title: 'Morning light',
      focus: 'Gratitude',
      body:
          'Father, thank You for this new day. Open my eyes to Your kindness, '
          'steady my heart with Your peace, and help me walk in Your truth.',
    ),
    DailyPrayer(
      title: 'Quiet strength',
      focus: 'Courage',
      body:
          'Lord, when I feel weak, be my strength. Give me courage to do what '
          'is right and faith to trust You with what I cannot control.',
    ),
    DailyPrayer(
      title: 'Clean heart',
      focus: 'Forgiveness',
      body:
          'Merciful God, forgive my sins and wash my heart clean. Teach me to '
          'forgive others as You have forgiven me.',
    ),
    DailyPrayer(
      title: 'Guided steps',
      focus: 'Wisdom',
      body: 'God of wisdom, guide my decisions today. Help me listen before I '
          'speak, and choose what honors You.',
    ),
    DailyPrayer(
      title: 'Peace in the storm',
      focus: 'Peace',
      body: 'Prince of Peace, calm my anxious thoughts. Remind me that You are '
          'near, and fill my home with Your quiet rest.',
    ),
    DailyPrayer(
      title: 'Love like Yours',
      focus: 'Compassion',
      body:
          'Jesus, teach me to love as You love—patiently, kindly, and without '
          'pride. Let someone feel Your care through me today.',
    ),
    DailyPrayer(
      title: 'Daily bread',
      focus: 'Provision',
      body:
          'Provider God, thank You for what I have. Meet my needs, and make me '
          'generous with what You place in my hands.',
    ),
    DailyPrayer(
      title: 'Faithful path',
      focus: 'Faithfulness',
      body: 'Lord, help me be faithful in small things. Keep me honest in my '
          'words and diligent in my work.',
    ),
    DailyPrayer(
      title: 'Healing touch',
      focus: 'Healing',
      body:
          'Healer of hearts, bring comfort where there is pain. Restore body, '
          'mind, and soul according to Your will.',
    ),
    DailyPrayer(
      title: 'Family blessing',
      focus: 'Family',
      body: 'Father, bless my family. Protect us, unite us, and help us speak '
          'with kindness under our roof.',
    ),
    DailyPrayer(
      title: 'Hungry for Your Word',
      focus: 'Scripture',
      body:
          'Lord, give me hunger for Your Word. Let Scripture shape my thoughts '
          'and renew my hope today.',
    ),
    DailyPrayer(
      title: 'Humble heart',
      focus: 'Humility',
      body:
          'God, keep me humble. Guard me from pride, and help me serve others '
          'with a willing spirit.',
    ),
    DailyPrayer(
      title: 'Joy that remains',
      focus: 'Joy',
      body:
          'Lord Jesus, fill me with joy that does not depend on circumstances. '
          'Let gratitude rise even in hard moments.',
    ),
    DailyPrayer(
      title: 'Light in darkness',
      focus: 'Hope',
      body: 'God of hope, shine in every dark place in my life. Remind me that '
          'Your light is stronger than fear.',
    ),
    DailyPrayer(
      title: 'Ready to listen',
      focus: 'Prayer',
      body: 'Holy Spirit, quiet my rushing thoughts. Help me listen for Your '
          'gentle voice and obey with trust.',
    ),
    DailyPrayer(
      title: 'Hands for service',
      focus: 'Service',
      body: 'Lord, use my hands and time today. Show me one person I can help, '
          'and give me a willing heart.',
    ),
    DailyPrayer(
      title: 'Truth on my lips',
      focus: 'Integrity',
      body:
          'God of truth, keep my words honest. Let my life match what I say I '
          'believe.',
    ),
    DailyPrayer(
      title: 'Refuge and rest',
      focus: 'Rest',
      body: 'Shepherd of my soul, I come under Your care. Give rest to my mind '
          'and safety to my spirit.',
    ),
    DailyPrayer(
      title: 'Nation and neighbors',
      focus: 'Community',
      body: 'Lord, bless my neighbors and my nation. Bring justice, mercy, and '
          'peace where there is conflict.',
    ),
    DailyPrayer(
      title: 'Patient waiting',
      focus: 'Patience',
      body:
          'Father, teach me patience. While I wait for answers, help me trust '
          'Your timing and stay kind.',
    ),
    DailyPrayer(
      title: 'Pure motives',
      focus: 'Purity',
      body: 'Holy God, purify my desires. Keep my eyes, thoughts, and choices '
          'pleasing to You.',
    ),
    DailyPrayer(
      title: 'Bold witness',
      focus: 'Witness',
      body: 'Jesus, give me gentle boldness to speak of Your love. Let my life '
          'point others to You.',
    ),
    DailyPrayer(
      title: 'Comfort the weary',
      focus: 'Comfort',
      body:
          'God of all comfort, hold those who are grieving or tired. Use me as '
          'a quiet presence of Your care.',
    ),
    DailyPrayer(
      title: 'Grateful evening',
      focus: 'Thanksgiving',
      body: 'Lord, thank You for today\'s gifts—seen and unseen. Forgive what '
          'went wrong, and keep me in Your peace tonight.',
    ),
    DailyPrayer(
      title: 'Open hands',
      focus: 'Surrender',
      body:
          'Father, I surrender my plans to You. Take what I cling to, and lead '
          'me where You want me to go.',
    ),
    DailyPrayer(
      title: 'Steady mind',
      focus: 'Focus',
      body:
          'Lord, help me focus on what matters. Free me from distraction, and '
          'give me clarity for today\'s work.',
    ),
    DailyPrayer(
      title: 'Grace for others',
      focus: 'Mercy',
      body: 'Merciful Savior, when others frustrate me, give me grace. Help me '
          'respond with patience instead of anger.',
    ),
    DailyPrayer(
      title: 'Strong foundation',
      focus: 'Trust',
      body: 'Rock of Ages, plant my feet on Your promises. When life feels '
          'unstable, be my firm foundation.',
    ),
    DailyPrayer(
      title: 'New beginning',
      focus: 'Renewal',
      body:
          'Lord, make all things new in me. Renew my hope, restore my joy, and '
          'revive my love for You.',
    ),
    DailyPrayer(
      title: 'Childlike trust',
      focus: 'Trust',
      body:
          'Heavenly Father, give me childlike trust. I bring my worries to You '
          'and rest in Your care.',
    ),
    DailyPrayer(
      title: 'Unity of heart',
      focus: 'Unity',
      body:
          'Lord Jesus, make Your people one in love. Heal division, and teach '
          'us to pursue peace.',
    ),
  ];
}
