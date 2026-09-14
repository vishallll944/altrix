import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/empty_state_card.dart';
import '../../data/models/patient_models.dart';
import '../providers/patient_providers.dart';
import '../widgets/form_detail_sheet.dart';

class FormsScreen extends ConsumerWidget {
  const FormsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final formsAsync = ref.watch(formsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forms & Consents'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: formsAsync.when(
            loading: () => const Center(
              child: InlineLoadingCard(label: 'Loading forms & consents...'),
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
            data: (forms) => RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(formsProvider),
              child: ListView(
                padding: responsive.pagePadding.copyWith(
                  top: responsive.rz(8),
                  bottom: responsive.rz(32),
                ),
                children: [
                  Text(
                    'Clinical questionnaires, assessments, and consent documents.',
                    style: responsiveTextStyle(
                      context,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.rz(20)),
                  if (forms.isEmpty)
                    const EmptyStateCard(
                      title: 'No forms due',
                      message:
                          'You do not have any pending forms or consents from your clinic at this time.',
                      icon: Icons.description_outlined,
                    )
                  else ...[
                    _FormsSummaryBanner(forms: forms),
                    SizedBox(height: responsive.rz(20)),
                    Text(
                      'All Documents',
                      style: responsiveTextStyle(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.rz(12)),
                    for (final form in forms)
                      Padding(
                        padding: EdgeInsets.only(bottom: responsive.rz(12)),
                        child: _FormCard(form: form),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormsSummaryBanner extends StatelessWidget {
  const _FormsSummaryBanner({required this.forms});

  final List<PatientFormModel> forms;

  @override
  Widget build(BuildContext context) {
    final pendingCount = forms.where((f) => f.isPending).length;
    final signedCount = forms.where((f) => f.isSigned).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              count: pendingCount,
              label: 'Action Required',
              color: const Color(0xFFF59E0B),
              icon: Icons.assignment_late_outlined,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: AppColors.border,
          ),
          Expanded(
            child: _SummaryItem(
              count: signedCount,
              label: 'Completed',
              color: const Color(0xFF10B981),
              icon: Icons.task_alt_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  final int count;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.form});

  final PatientFormModel form;

  Color _badgeColor() {
    switch (form.status.toLowerCase()) {
      case 'signed':
        return const Color(0xFF10B981);
      case 'declined':
        return const Color(0xFFEF4444);
      case 'expired':
        return const Color(0xFF6B7280);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _badgeText() {
    switch (form.status.toLowerCase()) {
      case 'signed':
        return 'Signed';
      case 'declined':
        return 'Declined';
      case 'expired':
        return 'Expired';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor();

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => showFormDetailModal(context, formId: form.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.description_outlined, color: badgeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          form.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (form.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            form.description,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _badgeText(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (form.dueAt.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${form.dueAt}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
