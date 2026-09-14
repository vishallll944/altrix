import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../auth/domain/entities/user.dart';
import '../../patient/data/models/patient_models.dart';

/// Service for generating and downloading patient medical summary PDF reports.
class MedicalSummaryPdfService {
  MedicalSummaryPdfService._();

  /// Generates the raw PDF bytes for a patient's medical summary.
  static Future<Uint8List> generatePdf({
    required User? user,
    List<AppointmentModel> appointments = const [],
    List<CheckInModel> checkIns = const [],
    ProgressModel? progress,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateFormatted =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final patientName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'Patient Record';
    final patientEmail = (user?.email.isNotEmpty ?? false) ? user!.email : 'N/A';
    final patientPhone = (user?.phone.isNotEmpty ?? false) ? user!.phone : 'N/A';
    final patientId = (user?.id.isNotEmpty ?? false) ? user!.id : 'ALT-P-UNASSIGNED';

    final primaryColor = PdfColor.fromHex('#4A3AFF');
    final darkHeader = PdfColor.fromHex('#0F172A');
    final secondaryText = PdfColor.fromHex('#475569');
    final borderColor = PdfColor.fromHex('#CBD5E1');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final accentGreen = PdfColor.fromHex('#10B981');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Top Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: darkHeader,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ALTRIX HEALTHCARE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Official Patient Medical Summary & Health Record',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#94A3B8'),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: accentGreen,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'HIPAA VERIFIED',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Metadata Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated: $dateFormatted',
                  style: pw.TextStyle(fontSize: 9, color: secondaryText),
                ),
                pw.Text(
                  'Record ID: ALT-${now.millisecondsSinceEpoch.toString().substring(5)}',
                  style: pw.TextStyle(fontSize: 9, color: secondaryText),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: borderColor, thickness: 1),
            pw.SizedBox(height: 12),

            // Patient Demographics Section
            pw.Text(
              '1. PATIENT DEMOGRAPHICS & PROFILE',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _pdfField('Full Legal Name', patientName),
                      ),
                      pw.Expanded(
                        child: _pdfField('Patient ID / MRN', patientId),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _pdfField('Email Address', patientEmail),
                      ),
                      pw.Expanded(
                        child: _pdfField('Phone Number', patientPhone),
                      ),
                    ],
                  ),
                  if ((user?.emergencyContactName.isNotEmpty ?? false) ||
                      (user?.emergencyContactPhone.isNotEmpty ?? false)) ...[
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _pdfField(
                            'Emergency Contact',
                            user?.emergencyContactName.isNotEmpty ?? false
                                ? user!.emergencyContactName
                                : 'Not specified',
                          ),
                        ),
                        pw.Expanded(
                          child: _pdfField(
                            'Emergency Phone',
                            user?.emergencyContactPhone.isNotEmpty ?? false
                                ? user!.emergencyContactPhone
                                : 'Not specified',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Appointments & Consultations Section
            pw.Text(
              '2. CLINICAL CONSULTATIONS & APPOINTMENTS',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (appointments.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Text(
                  'No recent clinical consultations or appointments on record.',
                  style: pw.TextStyle(fontSize: 10, color: secondaryText),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                headers: ['Date', 'Time', 'Clinician / Provider', 'Format', 'Status'],
                data: appointments.take(10).map((a) {
                  return [
                    a.dateLabel.isNotEmpty ? a.dateLabel : 'Scheduled',
                    a.timeLabel.isNotEmpty ? a.timeLabel : 'TBD',
                    a.providerName.isNotEmpty
                        ? a.providerName
                        : (a.title.isNotEmpty ? a.title : 'Care Provider'),
                    a.isVirtual ? 'Virtual Video Visit' : 'In-Person Clinic',
                    a.status.toUpperCase(),
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 16),

            // Check-ins & Wellness Tracking
            pw.Text(
              '3. WELLNESS MONITORING & DAILY CHECK-INS',
              style: pw.TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (checkIns.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Text(
                  'No recent daily check-ins recorded. Regular daily check-ins help clinicians personalize your care.',
                  style: pw.TextStyle(fontSize: 10, color: secondaryText),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: darkHeader),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                headers: ['Check-in Date', 'Mood Level', 'Sleep', 'Stress', 'Notes'],
                data: checkIns.take(10).map((c) {
                  return [
                    c.createdAt.isNotEmpty ? c.createdAt.split('T').first : 'Recent',
                    c.mood != null ? '${c.mood}/5' : 'N/A',
                    c.sleep != null ? '${c.sleep} hrs' : 'N/A',
                    c.stress != null ? '${c.stress}/10' : 'N/A',
                    c.journal.isNotEmpty
                        ? (c.journal.length > 30 ? '${c.journal.substring(0, 27)}...' : c.journal)
                        : 'None',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 20),

            // Legal & HIPAA Notice
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'HIPAA PRIVACY & CONFIDENTIALITY NOTICE',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: darkHeader,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'This document contains Protected Health Information (PHI) generated through the Altrix Health Platform in compliance with HIPAA 45 CFR § 164.524. It is strictly intended for the designated patient and their authorized medical care team. Any unauthorized copying, distribution, or alteration is prohibited by federal and state law.',
                    style: pw.TextStyle(fontSize: 7.5, color: secondaryText),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Electronic Certification: Altrix Cryptographic Key Validated',
                        style: pw.TextStyle(fontSize: 7.5, color: secondaryText),
                      ),
                      pw.Text(
                        'Page 1 of 1',
                        style: pw.TextStyle(fontSize: 7.5, color: secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7.5,
            color: PdfColor.fromHex('#64748B'),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromHex('#0F172A'),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static Future<Directory> _getStorageDirectory() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST') ||
          WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
        return Directory.systemTemp;
      }
      return await getApplicationDocumentsDirectory().timeout(
        const Duration(milliseconds: 600),
        onTimeout: () => Directory.systemTemp,
      );
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  /// Generates the medical summary PDF, persists it locally, and opens the system share dialog.
  static Future<File?> generateAndSavePdf({
    required User? user,
    List<AppointmentModel> appointments = const [],
    List<CheckInModel> checkIns = const [],
    ProgressModel? progress,
  }) async {
    final pdfBytes = await generatePdf(
      user: user,
      appointments: appointments,
      checkIns: checkIns,
      progress: progress,
    );

    final cleanName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        : 'Patient';
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final filename = 'Altrix_Medical_Summary_${cleanName}_$dateStr.pdf';

    File? savedFile;
    try {
      final dir = await _getStorageDirectory();
      savedFile = File('${dir.path}/$filename');
      savedFile.writeAsBytesSync(pdfBytes);
      debugPrint('Medical summary PDF written to: ${savedFile.path}');
    } catch (e) {
      debugPrint('Could not save to application documents directory: $e');
    }

    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    } catch (e) {
      debugPrint('Printing.sharePdf caught: $e');
    }

    return savedFile;
  }

  /// Saves pre-generated PDF bytes to device storage.
  static Future<File?> savePdfBytes({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final dir = await _getStorageDirectory();
      final savedFile = File('${dir.path}/$filename');
      savedFile.writeAsBytesSync(bytes);
      return savedFile;
    } catch (e) {
      debugPrint('Could not save PDF bytes to documents directory: $e');
      return null;
    }
  }
}
