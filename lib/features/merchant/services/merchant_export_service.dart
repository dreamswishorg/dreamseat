import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/web_utils.dart';
import '../merchant_kit.dart';
import '../theme/merchant_theme.dart';

enum ExportFormat {
  excel,
  pdf,
  csv,
}

class ExportDataset {
  final String title;
  final String merchantName;
  final String? subtitle;
  final List<String> headers;
  final List<List<dynamic>> rows;
  final Map<String, String> summaryMetrics;
  final String fileNamePrefix;

  const ExportDataset({
    required this.title,
    required this.merchantName,
    this.subtitle,
    required this.headers,
    required this.rows,
    this.summaryMetrics = const {},
    required this.fileNamePrefix,
  });

  int get rowCount => rows.length;
}

class MerchantExportService {
  MerchantExportService._();

  /// Generates a genuine Excel (.xlsx) file with styled headers and summary section.
  static Uint8List generateExcel(ExportDataset dataset) {
    final excel = Excel.createExcel();
    const sheetName = 'Report';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Title Row
    sheet.appendRow([
      TextCellValue('DREAMEATS — ${dataset.title.toUpperCase()}'),
    ]);
    sheet.appendRow([
      TextCellValue('Merchant: ${dataset.merchantName} | Exported: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
    ]);
    if (dataset.subtitle != null && dataset.subtitle!.isNotEmpty) {
      sheet.appendRow([TextCellValue(dataset.subtitle!)]);
    }
    sheet.appendRow([TextCellValue('')]); // Blank line

    // Summary Metrics
    if (dataset.summaryMetrics.isNotEmpty) {
      sheet.appendRow([TextCellValue('--- EXECUTIVE SUMMARY ---')]);
      for (final entry in dataset.summaryMetrics.entries) {
        sheet.appendRow([
          TextCellValue(entry.key),
          TextCellValue(entry.value),
        ]);
      }
      sheet.appendRow([TextCellValue('')]); // Blank line
    }

    // Data Headers
    final headerCells = dataset.headers.map((h) => TextCellValue(h)).toList();
    sheet.appendRow(headerCells);

    // Data Rows
    for (final row in dataset.rows) {
      final cells = <CellValue>[];
      for (final cell in row) {
        if (cell == null) {
          cells.add(TextCellValue('-'));
        } else if (cell is num) {
          cells.add(DoubleCellValue(cell.toDouble()));
        } else if (cell is bool) {
          cells.add(TextCellValue(cell ? 'Yes' : 'No'));
        } else if (cell is DateTime) {
          cells.add(TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(cell)));
        } else {
          cells.add(TextCellValue(cell.toString()));
        }
      }
      sheet.appendRow(cells);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  /// Generates a genuine PDF document with a professional food-commerce design.
  static Future<Uint8List> generatePdf(ExportDataset dataset) async {
    final doc = pw.Document();
    final nowStr = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Top Branded Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#2E7D32'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DREAMEATS MERCHANT PORTAL',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        dataset.title,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        dataset.merchantName,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Generated: $nowStr',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#E8F5E9'),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Summary Metrics Cards
            if (dataset.summaryMetrics.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: dataset.summaryMetrics.entries.map((entry) {
                    return pw.Column(
                      children: [
                        pw.Text(
                          entry.value,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1E293B'),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          entry.key,
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColor.fromHex('#64748B'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            // Data Table
            pw.TableHelper.fromTextArray(
              headers: dataset.headers,
              data: dataset.rows.map((row) {
                return row.map((cell) {
                  if (cell == null) return '-';
                  if (cell is DateTime) return DateFormat('dd/MM HH:mm').format(cell);
                  return cell.toString();
                }).toList();
              }).toList(),
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8.5,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#2E7D32'),
              ),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.black,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            ),
            pw.SizedBox(height: 16),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Confidential financial report for ${dataset.merchantName}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#64748B')),
                ),
                pw.Text(
                  'DreamEats Surplus Food Rescue Platform',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#64748B')),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  /// Generates clean CSV content with UTF-8 BOM for universal Excel compatibility.
  static String generateCsv(ExportDataset dataset) {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');

    // Headers
    buffer.writeln(dataset.headers.map(_escapeCsvCell).join(','));

    // Rows
    for (final row in dataset.rows) {
      buffer.writeln(row.map((cell) {
        if (cell == null) return '';
        if (cell is DateTime) return _escapeCsvCell(DateFormat('yyyy-MM-dd HH:mm').format(cell));
        return _escapeCsvCell(cell.toString());
      }).join(','));
    }

    return buffer.toString();
  }

  static String _escapeCsvCell(dynamic value) {
    final str = value?.toString() ?? '';
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Dispatches the generated file to the user's browser, mobile share sheet, or print driver.
  static Future<void> exportAndDownload(
    BuildContext context, {
    required ExportDataset dataset,
    required ExportFormat format,
  }) async {
    final dateTag = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final sanitizedMerchant = dataset.merchantName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').toLowerCase();
    final baseName = '${sanitizedMerchant}_${dataset.fileNamePrefix}_$dateTag';

    try {
      if (format == ExportFormat.excel) {
        final fileName = '$baseName.xlsx';
        final bytes = generateExcel(dataset);

        if (kIsWeb) {
          downloadBytes(
            bytes: bytes,
            fileName: fileName,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          if (context.mounted) MToast.ok(context, 'Excel file saved as $fileName');
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          // ignore: deprecated_member_use
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
            subject: dataset.title,
            text: '${dataset.title} from DreamEats',
          );
          if (context.mounted) MToast.ok(context, 'Excel report ready for sharing');
        }
      } else if (format == ExportFormat.pdf) {
        final fileName = '$baseName.pdf';
        final bytes = await generatePdf(dataset);

        if (kIsWeb) {
          downloadBytes(
            bytes: bytes,
            fileName: fileName,
            mimeType: 'application/pdf',
          );
          if (context.mounted) MToast.ok(context, 'PDF document saved as $fileName');
        } else {
          await Printing.sharePdf(bytes: bytes, filename: fileName);
          if (context.mounted) MToast.ok(context, 'PDF report ready for sharing or printing');
        }
      } else if (format == ExportFormat.csv) {
        final fileName = '$baseName.csv';
        final csv = generateCsv(dataset);

        if (kIsWeb) {
          downloadBytes(
            bytes: utf8.encode(csv),
            fileName: fileName,
            mimeType: 'text/csv;charset=utf-8',
          );
          if (context.mounted) MToast.ok(context, 'CSV file saved as $fileName');
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsString(csv, encoding: utf8);
          // ignore: deprecated_member_use
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'text/csv')],
            subject: dataset.title,
            text: '${dataset.title} from DreamEats',
          );
          if (context.mounted) MToast.ok(context, 'CSV data file ready for sharing');
        }
      }
    } catch (e) {
      if (context.mounted) {
        MToast.err(context, 'Export failed: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
  }

  /// Displays the interactive Format Picker Dialog with real-time feedback.
  static Future<void> showExportDialog(
    BuildContext context, {
    required ExportDataset dataset,
  }) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExportModalContent(dataset: dataset),
    );
  }
}

class _ExportModalContent extends StatefulWidget {
  final ExportDataset dataset;
  const _ExportModalContent({required this.dataset});

  @override
  State<_ExportModalContent> createState() => _ExportModalContentState();
}

class _ExportModalContentState extends State<_ExportModalContent> {
  ExportFormat _selectedFormat = ExportFormat.excel;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: MerchantTheme.navBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MerchantTheme.brandTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.file_download_outlined, color: MerchantTheme.brandGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dataset.title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: MerchantTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.dataset.rowCount} record${widget.dataset.rowCount == 1 ? '' : 's'} available to export',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MerchantTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: MerchantTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Format Selection Cards
          _buildFormatOption(
            format: ExportFormat.excel,
            title: 'Excel Workbook (.xlsx)',
            subtitle: 'Rich spreadsheet with formatted headers and summary metrics',
            icon: Icons.table_chart_rounded,
            color: MerchantTheme.brandGreen,
          ),
          const SizedBox(height: 10),
          _buildFormatOption(
            format: ExportFormat.pdf,
            title: 'PDF Document (.pdf)',
            subtitle: 'Print-ready formatted document with store header & page layout',
            icon: Icons.picture_as_pdf_rounded,
            color: MerchantTheme.roseDanger,
          ),
          const SizedBox(height: 10),
          _buildFormatOption(
            format: ExportFormat.csv,
            title: 'CSV Data File (.csv)',
            subtitle: 'Standard comma-delimited data with UTF-8 BOM encoding',
            icon: Icons.data_array_rounded,
            color: MerchantTheme.skyInfo,
          ),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantTheme.brandGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isExporting
                  ? null
                  : () async {
                      setState(() => _isExporting = true);
                      Navigator.pop(context);
                      await MerchantExportService.exportAndDownload(
                        context,
                        dataset: widget.dataset,
                        format: _selectedFormat,
                      );
                    },
              child: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Export ${_formatName(_selectedFormat)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.excel:
        return 'Excel (.xlsx)';
      case ExportFormat.pdf:
        return 'PDF (.pdf)';
      case ExportFormat.csv:
        return 'CSV (.csv)';
    }
  }

  Widget _buildFormatOption({
    required ExportFormat format,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedFormat == format;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFormat = format),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.14) : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? color : MerchantTheme.textMuted, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? MerchantTheme.textDark : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: MerchantTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : MerchantTheme.textTertiary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
