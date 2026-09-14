import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/empty_state_card.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Telehealth',
    'Appointments',
    'Forms & Privacy',
    'Care Team',
    'Billing',
  ];

  final List<_FaqItem> _faqItems = [
    const _FaqItem(
      category: 'Telehealth',
      question: 'How do I join my virtual telehealth video visit?',
      answer:
          'When your appointment is scheduled, tap "Join visit" on your Home screen or Schedule tab. This opens the Telehealth Lobby where you can preview your camera, test your microphone, and tap "I\'m Here" to alert your clinician that you have arrived in the waiting room. Then tap "Enter Video Consultation" to connect.',
    ),
    const _FaqItem(
      category: 'Telehealth',
      question: 'What if my camera or microphone does not work?',
      answer:
          '1. Ensure you have granted Camera and Microphone permissions to Altrix in your device settings.\n'
          '2. In the Telehealth Lobby, use the camera and mic toggle buttons to test device feeds.\n'
          '3. Try plugging in wired or bluetooth headphones with a built-in mic.\n'
          '4. If issues persist, close other apps that might be using the camera, or restart the app.',
    ),
    const _FaqItem(
      category: 'Telehealth',
      question: 'Is my virtual video call private and HIPAA-compliant?',
      answer:
          'Yes. All video consultations on Altrix use end-to-end 256-bit AES encryption adhering strictly to HIPAA and state telehealth confidentiality requirements. Sessions are live and never recorded without prior written consent.',
    ),
    const _FaqItem(
      category: 'Appointments',
      question: 'How do I book a virtual vs in-person appointment?',
      answer:
          'Tap "Book appointment" in your Schedule or Home screen. When choosing your visit details, select the "Virtual Video Visit" card for secure telehealth from home, or "In-Person Clinic" to meet your provider at the medical facility.',
    ),
    const _FaqItem(
      category: 'Appointments',
      question: 'Can I reschedule or cancel my appointment?',
      answer:
          'Yes. In the Schedule tab, locate your upcoming appointment and tap "Reschedule" to pick a new clinician slot, or tap "Cancel appointment". We request at least 24 hours advance notice for cancellations.',
    ),
    const _FaqItem(
      category: 'Forms & Privacy',
      question: 'How do I complete and sign clinical intake forms?',
      answer:
          'Navigate to the Resources screen or Care tab and tap "Forms & Consents". Tap any document labeled "Action Required" to read the clinical disclosures, check the electronic signature acknowledgment, and tap "Sign & Submit Form".',
    ),
    const _FaqItem(
      category: 'Forms & Privacy',
      question: 'Who has access to my health records and check-ins?',
      answer:
          'Only your assigned multidisciplinary care team (doctors, therapists, clinical nurse specialists) can view your clinical notes and mood check-ins. Your health data is never sold or shared with third parties.',
    ),
    const _FaqItem(
      category: 'Care Team',
      question: 'How do I send a secure message to my care team?',
      answer:
          'Open the Messages tab from the bottom navigation bar. Select your active care team conversation to send HIPAA-compliant text messages or share updates between visits.',
    ),
    const _FaqItem(
      category: 'Billing',
      question: 'Does insurance cover telehealth sessions?',
      answer:
          'Most commercial insurance plans, Medicare, and Medicaid cover outpatient telehealth visits under mental and behavioral healthcare parity laws. Co-pays are processed according to your policy benefits.',
    ),
  ];

  List<_FaqItem> get _filteredFaqs {
    return _faqItems.where((faq) {
      final matchesCategory =
          _selectedCategory == 'All' || faq.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showContactSupportDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String category = 'General Inquiry';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.support_agent_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Contact Clinic Support', style: TextStyle(fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a message to the patient help desk. We typically respond within 1-2 business hours.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'General Inquiry', child: Text('General Inquiry')),
                    DropdownMenuItem(value: 'Telehealth Technical Issue', child: Text('Telehealth Technical Issue')),
                    DropdownMenuItem(value: 'Appointment Scheduling', child: Text('Appointment Scheduling')),
                    DropdownMenuItem(value: 'Forms & Documents', child: Text('Forms & Documents')),
                    DropdownMenuItem(value: 'Billing & Insurance', child: Text('Billing & Insurance')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support request sent! Ticket #ALT-8492 created.'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Submit Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final faqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: responsive.pagePadding.copyWith(
              top: responsive.rz(12),
              bottom: responsive.rz(36),
            ),
            children: [
              // Hero Banner
              Container(
                padding: EdgeInsets.all(responsive.rz(18)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E266F), Color(0xFF1E174C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E174C).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.live_help_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '24/7 Patient Support',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.rz(12)),
                    Text(
                      'How can we help you today?',
                      style: responsiveTextStyle(
                        context,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: responsive.rz(6)),
                    const Text(
                      'Search our clinical guides, FAQs, or contact your care coordinator.',
                      style: TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.rz(18)),

              // Search Input
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search telehealth, billing, appointments...',
                    hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: responsive.rz(14)),

              // Category Pills
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
              SizedBox(height: responsive.rz(20)),

              // Quick Contact Channels
              Text(
                'Contact Support',
                style: responsiveTextStyle(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.rz(12)),
              Row(
                children: [
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Support Ticket',
                      subtitle: 'Fast email response',
                      color: AppColors.primary,
                      onTap: () => _showContactSupportDialog(context),
                    ),
                  ),
                  SizedBox(width: responsive.rz(10)),
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.phone_outlined,
                      title: 'Call Clinic',
                      subtitle: '1-800-555-0199',
                      color: const Color(0xFF10B981),
                      onTap: () async {
                        final uri = Uri.parse('tel:18005550199');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  ),
                  SizedBox(width: responsive.rz(10)),
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.mail_outline_rounded,
                      title: 'Email Us',
                      subtitle: 'support@altrix.com',
                      color: const Color(0xFF3B82F6),
                      onTap: () async {
                        final uri = Uri.parse('mailto:support@altrixs.com?subject=Patient%20Support%20Inquiry');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.rz(24)),

              // FAQ Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Frequently Asked Questions',
                      style: responsiveTextStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${faqs.length} topics',
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
              SizedBox(height: responsive.rz(12)),

              if (faqs.isEmpty)
                const EmptyStateCard(
                  title: 'No matching answers',
                  message: 'Try searching with other terms or contact our support team above.',
                  icon: Icons.search_off_rounded,
                )
              else
                for (final faq in faqs)
                  Padding(
                    padding: EdgeInsets.only(bottom: responsive.rz(10)),
                    child: _FaqAccordionTile(faq: faq),
                  ),

              SizedBox(height: responsive.rz(20)),

              // 24/7 Crisis Hotline Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.crisis_alert_rounded,
                        color: Color(0xFFDC2626),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Need Immediate Crisis Support?',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Call or text 988 for free, confidential 24/7 mental health crisis help.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D)),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final uri = Uri.parse('tel:988');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Call 988', style: TextStyle(fontSize: 12)),
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

class _FaqItem {
  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });

  final String category;
  final String question;
  final String answer;
}

class _FaqAccordionTile extends StatelessWidget {
  const _FaqAccordionTile({required this.faq});

  final _FaqItem faq;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            faq.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            faq.answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
