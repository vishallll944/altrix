import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/empty_state_card.dart';
import '../../data/models/patient_models.dart';
import '../providers/patient_providers.dart';

Future<void> showFormDetailModal(BuildContext context, {required String formId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FormDetailSheet(formId: formId),
  );
}

class FormDetailSheet extends ConsumerStatefulWidget {
  const FormDetailSheet({super.key, required this.formId});

  final String formId;

  @override
  ConsumerState<FormDetailSheet> createState() => _FormDetailSheetState();
}

class _FormDetailSheetState extends ConsumerState<FormDetailSheet> {
  bool _agreed = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(formDetailProvider(widget.formId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Clinical Form Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Body content
          Expanded(
            child: formAsync.when(
              loading: () => const Center(
                child: InlineLoadingCard(label: 'Loading form details...'),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: InlineErrorCard(
                  message: friendlyErrorMessage(error),
                  onRetry: () => ref.invalidate(formDetailProvider(widget.formId)),
                ),
              ),
              data: (form) => _FormContent(
                form: form,
                agreed: _agreed,
                submitting: _submitting,
                onAgreedChanged: (val) => setState(() => _agreed = val ?? false),
                onSubmit: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _submitting = true);
                  await Future.delayed(const Duration(milliseconds: 600));
                  if (!mounted) return;
                  setState(() => _submitting = false);
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('${form.title} completed successfully.'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.form,
    required this.agreed,
    required this.submitting,
    required this.onAgreedChanged,
    required this.onSubmit,
  });

  final PatientFormModel form;
  final bool agreed;
  final bool submitting;
  final ValueChanged<bool?> onAgreedChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isSigned = form.isSigned;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title & status row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                form.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isSigned
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSigned ? 'Signed' : 'Action Required',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSigned
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
        if (form.dueAt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'Due by: ${form.dueAt}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Description / Instructions
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Instructions & Purpose',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                form.description.isNotEmpty
                    ? form.description
                    : 'Please review and confirm this clinic document before your next session. Your answers help your care team personalize your treatment plan.',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Form items / fields
        const Text(
          'Document Questions & Declarations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _QuestionTile(
          number: '1',
          question: 'Informed Telehealth & Treatment Consent',
          answer:
              'I understand telehealth visits are conducted via HIPAA-compliant encrypted video and audio.',
        ),
        const SizedBox(height: 8),
        _QuestionTile(
          number: '2',
          question: 'Emergency Contact & Physical Location',
          answer:
              'I agree to provide my physical address at the start of any virtual telehealth session.',
        ),
        const SizedBox(height: 8),
        _QuestionTile(
          number: '3',
          question: 'Notice of Privacy Practices',
          answer:
              'I acknowledge access to the clinic Notice of Privacy Practices regarding Protected Health Information (PHI).',
        ),
        const SizedBox(height: 20),
        if (isSigned) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Electronically Signed & Filed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      if (form.signedAt.isNotEmpty)
                        Text(
                          'Signed on ${form.signedAt}',
                          style: const TextStyle(
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
        ] else ...[
          // Signing action
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: agreed,
                  activeColor: AppColors.primary,
                  onChanged: onAgreedChanged,
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'I confirm that the information provided is accurate and grant my electronic signature.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: agreed && !submitting ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.draw_outlined, size: 18),
              label: Text(
                submitting ? 'Submitting Signature...' : 'Sign & Submit Form',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.number,
    required this.question,
    required this.answer,
  });

  final String number;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
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
