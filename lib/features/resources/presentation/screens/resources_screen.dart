import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/empty_state_card.dart';
import '../../../patient/presentation/providers/patient_providers.dart';
import '../../../patient/presentation/widgets/form_detail_sheet.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Worksheets',
    'Mental Health',
    'Medications',
    'Therapy Guides',
    'Wellness',
  ];

  final List<_HealthResource> _allResources = [
    const _HealthResource(
      id: 'cbt-thought-record',
      title: 'CBT Thought Record Worksheet',
      category: 'Worksheets',
      readTime: '5 min read',
      icon: Icons.edit_note_rounded,
      color: Color(0xFF6C5CE7),
      summary:
          'Identify automatic negative thoughts, detect cognitive distortions, and construct rational alternatives.',
      content:
          'A Cognitive Behavioral Therapy (CBT) Thought Record helps you slow down anxious or distressing thoughts.\n\n'
          'Step 1: The Situation\nDescribe what was happening when you felt the shift in emotion (Who, What, Where, When).\n\n'
          'Step 2: The Automatic Thought\nWhat was running through your mind? (e.g. "I will fail this presentation", "Nobody likes me").\n\n'
          'Step 3: The Emotion & Intensity\nRate your anxiety or sadness on a scale from 0 to 100%.\n\n'
          'Step 4: Objective Evidence\n• Evidence supporting the thought\n• Evidence contradicting the thought\n\n'
          'Step 5: Balanced Alternative\nFormulate a realistic, compassionate reframe and re-rate your emotional intensity.',
    ),
    const _HealthResource(
      id: 'grounding-54321',
      title: '5-4-3-2-1 Sensory Grounding Technique',
      category: 'Mental Health',
      readTime: '3 min read',
      icon: Icons.spa_rounded,
      color: Color(0xFF10B981),
      summary:
          'A rapid sensory exercise to ground your nervous system during panic attacks or overwhelming stress.',
      content:
          'When panic strikes, your nervous system triggers fight-or-flight. Grounding redirects attention to your physical environment.\n\n'
          '5 things you can SEE: Look for small details—a crack in the wall, light reflecting on wood, the weave in your shirt.\n\n'
          '4 things you can FEEL: The weight of your feet on the floor, the texture of your pants, temperature of the air.\n\n'
          '3 things you can HEAR: Traffic outside, a clock ticking, air conditioner hum.\n\n'
          '2 things you can SMELL: Coffee, fresh breeze, clean laundry, or hand soap.\n\n'
          '1 thing you can TASTE: Sip of cold water or mint gum.\n\n'
          'Finish with 3 slow, deep belly breaths.',
    ),
    const _HealthResource(
      id: 'sleep-hygiene',
      title: 'Circadian Sleep Hygiene Protocol',
      category: 'Wellness',
      readTime: '6 min read',
      icon: Icons.bedtime_outlined,
      color: Color(0xFF3B82F6),
      summary:
          'Evidence-based lifestyle guidelines to optimize deep sleep architecture and circadian rhythm consistency.',
      content:
          'High quality sleep is foundational to emotional regulation and neurological repair.\n\n'
          '1. Morning Light Anchor:\nGet 10-15 minutes of direct sunlight within 30 minutes of waking to trigger cortisol release and set the melatonin countdown.\n\n'
          '2. Temperature Control:\nThe body must drop 2-3°F to initiate deep REM sleep. Keep your bedroom between 65-68°F (18-20°C).\n\n'
          '3. Stimulant Cutoff:\nCaffeine has an average half-life of 5-7 hours. Cut off caffeine consumption 10 hours before bed.\n\n'
          '4. Wind-Down Buffer:\nPower down bright LED screens 45 minutes before sleep. Switch to warm amber lighting or audiobooks.',
    ),
    const _HealthResource(
      id: 'medication-adherence',
      title: 'Medication Safety & Adherence Guide',
      category: 'Medications',
      readTime: '4 min read',
      icon: Icons.medication_liquid_outlined,
      color: Color(0xFFF59E0B),
      summary:
          'Essential safety principles for psychiatric and routine medications, missed dose management, and doctor tracking.',
      content:
          'Medications work best when maintained at steady therapeutic levels in your bloodstream.\n\n'
          '• Never stop medications abruptly: Antidepressants, mood stabilizers, and anxiolytics must be safely tapered under clinical supervision to avoid discontinuation syndrome.\n\n'
          '• What to do if you miss a dose: Take it as soon as you remember unless it is nearly time for your next scheduled dose. Never take a double dose to make up for a missed one.\n\n'
          '• Log side effects: Use the Altrix Daily Check-in to note nausea, fatigue, or mood changes to share directly with your prescriber at your next visit.',
    ),
    const _HealthResource(
      id: 'box-breathing',
      title: 'Box Breathing (4-4-4-4 Technique)',
      category: 'Therapy Guides',
      readTime: '2 min read',
      icon: Icons.air_rounded,
      color: Color(0xFF8B5CF6),
      summary:
          'A tactical autonomic nervous system regulation tool used to rapidly decrease heart rate and cortisol.',
      content:
          'Box breathing engages the vagus nerve to stimulate parasympathetic recovery.\n\n'
          '1. Inhale deeply through the nose for 4 seconds.\n'
          '2. Hold breath with full lungs for 4 seconds.\n'
          '3. Exhale smoothly through the mouth for 4 seconds.\n'
          '4. Hold breath empty for 4 seconds.\n\n'
          'Repeat this 4-step square cycle 4 times whenever experiencing acute stress.',
    ),
    const _HealthResource(
      id: 'depression-activation',
      title: 'Behavioral Activation for Depression',
      category: 'Therapy Guides',
      readTime: '7 min read',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFEC4899),
      summary:
          'Overcoming the inertia of depression through graded activity scheduling and small intentional actions.',
      content:
          'Depression creates a trap: feeling tired leads to inactivity, which reduces positive reinforcement, worsening depression.\n\n'
          'Behavioral Activation reverses this cycle by acting before feeling motivated.\n\n'
          '• The 5-Minute Rule: Commit to an activity (like walking outside or washing dishes) for just 5 minutes. You can stop after 5 minutes if you wish, but 80% of people continue.\n\n'
          '• Master & Pleasure Activities: Balance necessary tasks (paying bills, cleaning) with joyful tasks (listening to music, cooking).\n\n'
          '• Celebrate Micro-Wins: Any movement during a depressive episode is a triumph.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_HealthResource> get _filteredResources {
    return _allResources.where((r) {
      final matchesCategory =
          _selectedCategory == 'All' || r.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.summary.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openResourceDetail(_HealthResource resource) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResourceDetailSheet(resource: resource),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Resources'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Health Library'),
            Tab(text: 'Forms & Consents'),
            Tab(text: 'Crisis Hotlines'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Health Library
          _buildHealthLibraryTab(responsive),

          // Tab 2: Clinical Forms & Consents (Endpoint 7.1 & 7.2)
          _buildFormsTab(responsive),

          // Tab 3: Crisis Hotlines
          _buildCrisisHotlinesTab(responsive),
        ],
      ),
    );
  }

  Widget _buildHealthLibraryTab(Responsive responsive) {
    final resources = _filteredResources;

    return ListView(
      padding: responsive.pagePadding.copyWith(
        top: responsive.rz(14),
        bottom: responsive.rz(36),
      ),
      children: [
        // Search Bar
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: 'Search health guides & worksheets...',
              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(height: responsive.rz(14)),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: responsive.rz(18)),

        // Resource List
        if (resources.isEmpty)
          const EmptyStateCard(
            title: 'No resources found',
            message: 'Try adjusting your search terms or selecting another category.',
            icon: Icons.menu_book_outlined,
          )
        else
          for (final resource in resources)
            Padding(
              padding: EdgeInsets.only(bottom: responsive.rz(12)),
              child: _ResourceCard(
                resource: resource,
                onTap: () => _openResourceDetail(resource),
              ),
            ),
      ],
    );
  }

  Widget _buildFormsTab(Responsive responsive) {
    final formsAsync = ref.watch(formsProvider);

    return formsAsync.when(
      loading: () => const Center(
        child: InlineLoadingCard(label: 'Loading clinic forms...'),
      ),
      error: (error, _) => ListView(
        padding: responsive.pagePadding,
        children: [
          InlineErrorCard(
            message: friendlyErrorMessage(error),
            onRetry: () => ref.invalidate(formsProvider),
          ),
        ],
      ),
      data: (forms) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(formsProvider),
          child: ListView(
            padding: responsive.pagePadding.copyWith(
              top: responsive.rz(14),
              bottom: responsive.rz(36),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primarySoft.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Required Intake & Consents',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap any document to review clinical details or electronically sign.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.rz(16)),
              if (forms.isEmpty)
                const EmptyStateCard(
                  title: 'All caught up!',
                  message: 'You have completed all questionnaires and forms assigned by your doctor.',
                  icon: Icons.task_alt_rounded,
                )
              else
                for (final form in forms)
                  Padding(
                    padding: EdgeInsets.only(bottom: responsive.rz(12)),
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => showFormDetailModal(context, formId: form.id),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (form.isSigned
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: form.isSigned
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      form.title,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (form.dueAt.isNotEmpty)
                                      Text(
                                        'Due: ${form.dueAt}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (form.isSigned
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  form.isSigned ? 'Signed' : 'Open Form',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: form.isSigned
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCrisisHotlinesTab(Responsive responsive) {
    return ListView(
      padding: responsive.pagePadding.copyWith(
        top: responsive.rz(16),
        bottom: responsive.rz(36),
      ),
      children: [
        // Urgent Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'If you or someone you know is in immediate physical danger, call 911 immediately or go to the nearest emergency room.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF991B1B),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.rz(18)),

        // 988 Lifeline Card
        _CrisisCard(
          title: '988 Suicide & Crisis Lifeline',
          subtitle: 'Free, confidential support available 24/7/365 across the US.',
          phoneLabel: 'Call or Text 988',
          onAction: () async {
            final uri = Uri.parse('tel:988');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
          actionIcon: Icons.phone_in_talk_rounded,
          color: const Color(0xFFDC2626),
        ),
        SizedBox(height: responsive.rz(12)),

        // Crisis Text Line
        _CrisisCard(
          title: 'Crisis Text Line',
          subtitle: 'Text HOME to 741741 to connect with a volunteer crisis counselor.',
          phoneLabel: 'Text HOME to 741741',
          onAction: () async {
            final uri = Uri.parse('sms:741741?body=HOME');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
          actionIcon: Icons.sms_rounded,
          color: const Color(0xFF2563EB),
        ),
        SizedBox(height: responsive.rz(12)),

        // The Trevor Project
        _CrisisCard(
          title: 'The Trevor Project (LGBTQ+ Youth)',
          subtitle: '24/7 confidential crisis support for LGBTQ young people.',
          phoneLabel: 'Call 1-866-488-7386',
          onAction: () async {
            final uri = Uri.parse('tel:18664887386');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
          actionIcon: Icons.phone_rounded,
          color: const Color(0xFF7C3AED),
        ),
        SizedBox(height: responsive.rz(12)),

        // Veterans Crisis Line
        _CrisisCard(
          title: 'Veterans Crisis Line',
          subtitle: 'Dial 988 and press 1 to reach caring VA responders.',
          phoneLabel: 'Dial 988, then Press 1',
          onAction: () async {
            final uri = Uri.parse('tel:988');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
          actionIcon: Icons.military_tech_rounded,
          color: const Color(0xFF0D9488),
        ),
      ],
    );
  }
}

class _HealthResource {
  const _HealthResource({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.icon,
    required this.color,
    required this.summary,
    required this.content,
  });

  final String id;
  final String title;
  final String category;
  final String readTime;
  final IconData icon;
  final Color color;
  final String summary;
  final String content;
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.onTap});

  final _HealthResource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: resource.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(resource.icon, color: resource.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          resource.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: resource.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          resource.readTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.summary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceDetailSheet extends StatelessWidget {
  const _ResourceDetailSheet({required this.resource});

  final _HealthResource resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(resource.icon, color: resource.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resource.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: resource.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        resource.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: resource.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      resource.readTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  resource.content,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrisisCard extends StatelessWidget {
  const _CrisisCard({
    required this.title,
    required this.subtitle,
    required this.phoneLabel,
    required this.onAction,
    required this.actionIcon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String phoneLabel;
  final VoidCallback onAction;
  final IconData actionIcon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(actionIcon, size: 18),
              label: Text(
                phoneLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
