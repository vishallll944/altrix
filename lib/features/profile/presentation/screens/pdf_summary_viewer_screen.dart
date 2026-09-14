import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../theme/app_colors.dart';

/// In-app PDF Viewer screen that displays the downloaded medical summary.
class PdfSummaryViewerScreen extends StatelessWidget {
  const PdfSummaryViewerScreen({
    super.key,
    required this.pdfBytes,
    required this.filename,
  });

  final Uint8List pdfBytes;
  final String filename;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Encrypted Medical Summary',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share / Save PDF',
            onPressed: () => Printing.sharePdf(bytes: pdfBytes, filename: filename),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Summary',
            onPressed: () => Printing.layoutPdf(
              name: filename,
              onLayout: (format) async => pdfBytes,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: PdfPreview(
          build: (format) => pdfBytes,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          pdfFileName: filename,
          loadingWidget: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
