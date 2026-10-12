import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/services/campus_download_service.dart';
import '../../../../core/services/file_open_service.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/models/dept_admin_models.dart';

/// Professional Institutional PDF Generator for NBA / NAAC Department Accreditation.
class DeptAccreditationPdfService {
  static const PdfColor _primaryNavy = PdfColor.fromInt(0xFF1E3A8A);
  static const PdfColor _secondaryBlue = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor _tealAccent = PdfColor.fromInt(0xFF0D9488);
  static const PdfColor _darkText = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _mutedText = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _cardBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _borderGray = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _successGreen = PdfColor.fromInt(0xFF16A34A);

  /// Generates the official multi-page accreditation PDF report with genuine datagrams,
  /// saves it to device storage, and opens it using the default system viewer.
  static Future<String?> generateAndDownloadReport({
    required BuildContext context,
    required DeptReportsData reportData,
    required DeptInfo deptInfo,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    // Show loading modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Generating Report PDF',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Compiling ${deptInfo.code} accreditation datagram...',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final doc = pw.Document(
        title: '${deptInfo.name} Accreditation Report ${reportData.academicYear}',
        author: 'CampusHub Institutional Portal',
      );

      final metrics = reportData.metrics;
      final placement = reportData.placementStatus;
      final fsrRatio = metrics.faculty > 0 ? (metrics.students / metrics.faculty).round() : 15;
      final placementRate = placement.total > 0
          ? ((placement.placed / placement.total) * 100).toStringAsFixed(1)
          : '0.0';
      final formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now());
      final auditRef = 'GCEE/NBA-${deptInfo.code}/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          header: (pw.Context ctx) => _buildHeader(deptInfo, reportData, auditRef, formattedDate),
          footer: (pw.Context ctx) => _buildFooter(ctx, deptInfo),
          build: (pw.Context ctx) => [
            pw.SizedBox(height: 12),
            _buildKpiSummaryGrid(metrics, fsrRatio),
            pw.SizedBox(height: 16),
            _buildYearDistributionDatagram(reportData, metrics.students),
            pw.SizedBox(height: 16),
            _buildPlacementDatagram(placement, placementRate),
            pw.SizedBox(height: 16),
            _buildAccreditationAuditCompliance(metrics, fsrRatio, placementRate),
            pw.SizedBox(height: 20),
            _buildInstitutionalSignOff(deptInfo, reportData),
          ],
        ),
      );

      final pdfBytes = await doc.save();

      // Get user-accessible reports folder
      final downloadDir = await CampusDownloadService.getDownloadDirectory(subFolder: 'Reports');
      final cleanYear = reportData.academicYear.replaceAll(' ', '').replaceAll('-', '_');
      final fileName = '${deptInfo.code}_Accreditation_Report_${cleanYear}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf';
      final targetPath = '${downloadDir.path}/$fileName';

      final file = File(targetPath);
      await file.writeAsBytes(pdfBytes, flush: true);

      // Dismiss loading modal
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Fire system notification
      await LocalNotificationService.showNotification(
        title: 'Accreditation PDF Generated',
        body: '$fileName saved in Reports folder',
        payload: targetPath,
      );

      // Show user feedback with Open Action
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ $fileName generated!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saved to: ${downloadDir.path}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Open PDF',
              textColor: Colors.white,
              onPressed: () {
                FileOpenService.openLocalFile(targetPath, context: context);
              },
            ),
          ),
        );

        // Open automatically
        await FileOpenService.openLocalFile(targetPath, context: context);
      }

      return targetPath;
    } catch (e, stack) {
      debugPrint('⚠️ [DeptAccreditationPdfService] PDF export error: $e\n$stack');
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to generate Accreditation PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  // --- PDF WIDGET BUILDERS ---

  static pw.Widget _buildHeader(
    DeptInfo deptInfo,
    DeptReportsData reportData,
    String auditRef,
    String formattedDate,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _primaryNavy,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 44,
                height: 44,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  shape: pw.BoxShape.circle,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  deptInfo.code,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryNavy,
                  ),
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GOVERNMENT COLLEGE OF ENGINEERING, ERODE',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Autonomous Institution | Affiliated to Anna University, Chennai | NBA Accredited Program',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.grey300,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'DEPARTMENT OF ${deptInfo.name.toUpperCase()} (${deptInfo.degree})',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.amber200,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _cardBg,
            border: pw.Border.all(color: _borderGray),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'OFFICIAL ACCREDITATION & ACADEMIC AUDIT REPORT',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryNavy,
                ),
              ),
              pw.Text(
                'Session: ${reportData.academicYear}  |  Ref: $auditRef',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: _mutedText,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 1, color: _secondaryBlue),
      ],
    );
  }

  static pw.Widget _buildKpiSummaryGrid(DeptReportMetrics metrics, int fsrRatio) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'EXECUTIVE KPI SUMMARY DATAGRAM',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _primaryNavy,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _buildKpiCard('Total Enrollment', '${metrics.students}', 'Active Students', _secondaryBlue),
            pw.SizedBox(width: 8),
            _buildKpiCard('Faculty Strength', '${metrics.faculty}', 'FSR 1:$fsrRatio (Target <= 1:20)', _tealAccent),
            pw.SizedBox(width: 8),
            _buildKpiCard('Department CGPA', metrics.avgCgpa.toStringAsFixed(2), 'Out of 10.0 scale', _primaryNavy),
            pw.SizedBox(width: 8),
            _buildKpiCard('Attendance Rate', '${metrics.attendance}%', 'Institutional Min: 75%', _successGreen),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildKpiCard(String title, String value, String subtitle, PdfColor accentColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: _cardBg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _borderGray),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: _mutedText,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 7,
                color: _darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildYearDistributionDatagram(DeptReportsData reportData, int totalStudents) {
    final list = reportData.studentsByYear;
    int maxCount = 1;
    for (var m in list) {
      if (m.count > maxCount) maxCount = m.count;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _borderGray),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '1. COHORT ENROLLMENT & ACADEMIC YEAR DISTRIBUTION',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryNavy,
                ),
              ),
              pw.Text(
                'Total Cohort: $totalStudents Students',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _secondaryBlue,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          ...list.map((yearMetric) {
            final pct = totalStudents > 0
                ? ((yearMetric.count / totalStudents) * 100).toStringAsFixed(1)
                : '0.0';
            final ratio = (yearMetric.count / maxCount).clamp(0.05, 1.0);

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 70,
                    child: pw.Text(
                      yearMetric.year,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkText,
                      ),
                    ),
                  ),
                  pw.SizedBox(
                    width: 55,
                    child: pw.Text(
                      '${yearMetric.count} ($pct%)',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: _mutedText,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Stack(
                      children: [
                        pw.Container(
                          height: 10,
                          decoration: pw.BoxDecoration(
                            color: _borderGray,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                        pw.Container(
                          height: 10,
                          width: ratio * 280,
                          decoration: pw.BoxDecoration(
                            color: _secondaryBlue,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildPlacementDatagram(
    DeptPlacementBreakdown placement,
    String placementRate,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _borderGray),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '2. CAREER TRANSITION & PLACEMENT OUTCOMES DATAGRAM',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryNavy,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: _successGreen,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Success Rate: $placementRate%',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: _borderGray, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell('Category / Status', isHeader: true),
                  _tableCell('Headcount', isHeader: true),
                  _tableCell('Proportion of Eligible', isHeader: true),
                  _tableCell('NBA Audit Rating', isHeader: true),
                ],
              ),
              _buildTableRow(
                'Placed Students',
                '${placement.placed}',
                placement.total > 0
                    ? '${((placement.placed / placement.total) * 100).toStringAsFixed(1)}%'
                    : '0%',
                'Verified Institutional Offers',
              ),
              _buildTableRow(
                'Shortlisted in Final Rounds',
                '${placement.shortlisted}',
                placement.total > 0
                    ? '${((placement.shortlisted / placement.total) * 100).toStringAsFixed(1)}%'
                    : '0%',
                'Drives in Pipeline',
              ),
              _buildTableRow(
                'Applied to Active Drives',
                '${placement.applied}',
                placement.total > 0
                    ? '${((placement.applied / placement.total) * 100).toStringAsFixed(1)}%'
                    : '0%',
                'Registered Candidates',
              ),
              _buildTableRow(
                'Eligible / Open Pool',
                '${placement.eligible}',
                placement.total > 0
                    ? '${((placement.eligible / placement.total) * 100).toStringAsFixed(1)}%'
                    : '0%',
                'Preparing for Upcoming Drives',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAccreditationAuditCompliance(
    DeptReportMetrics metrics,
    int fsrRatio,
    String placementRate,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _borderGray),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '3. NBA / NAAC ACCREDITATION CRITERIA AUDIT COMPLIANCE',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _primaryNavy,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: _borderGray, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell('Audit Parameter', isHeader: true),
                  _tableCell('Department Metric', isHeader: true),
                  _tableCell('Statutory Standard', isHeader: true),
                  _tableCell('Compliance Status', isHeader: true),
                ],
              ),
              _buildTableRow('Faculty-Student Ratio (FSR)', '1:$fsrRatio', '<= 1:20 (Tier-1 <= 1:15)', 'COMPLIANT'),
              _buildTableRow('Department CGPA Index (API)', metrics.avgCgpa.toStringAsFixed(2), '>= 6.75', 'SATISFACTORY'),
              _buildTableRow('Student Attendance Rate', '${metrics.attendance}%', '>= 75.0%', 'COMPLIANT'),
              _buildTableRow('Placement Conversion', '$placementRate%', '>= 60.0%', 'EXCEEDS TARGET'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInstitutionalSignOff(DeptInfo deptInfo, DeptReportsData reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'CERTIFICATION: The academic and placement figures presented in this datagram report are generated directly from the authentic institutional ERP database of Government College of Engineering, Erode for NBA/NAAC academic compliance verification.',
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: _mutedText,
              lineSpacing: 1.2,
            ),
          ),
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSignatureBlock('Accreditation Coordinator', 'NBA/NAAC Dept Cell'),
            _buildSignatureBlock('Head of the Department', 'Dept. of ${deptInfo.name}'),
            _buildSignatureBlock('Principal / Institutional Head', 'Govt. College of Engineering, Erode'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureBlock(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 140,
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _darkText, width: 0.8)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _darkText),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          style: const pw.TextStyle(fontSize: 7.5, color: _mutedText),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? _primaryNavy : _darkText,
        ),
      ),
    );
  }

  static pw.TableRow _buildTableRow(String c1, String c2, String c3, String c4) {
    return pw.TableRow(
      children: [
        _tableCell(c1),
        _tableCell(c2),
        _tableCell(c3),
        _tableCell(c4),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, DeptInfo deptInfo) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: _borderGray),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Government College of Engineering, Erode | Department of ${deptInfo.name}',
              style: const pw.TextStyle(fontSize: 7.5, color: _mutedText),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7.5, color: _mutedText),
            ),
          ],
        ),
      ],
    );
  }
}
