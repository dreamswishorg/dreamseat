import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dreameats/features/merchant/services/merchant_export_service.dart';

void main() {
  group('MerchantExportService Tests', () {
    final sampleDataset = ExportDataset(
      title: 'Surplus Inventory Statement',
      merchantName: 'Garden Kitchen Accra',
      headers: ['Deal Title', 'Category', 'Price (GHS)', 'Units Rescued'],
      rows: [
        ['Lunch Rescue Pack', 'Restaurant Meal', 15.0, 8],
        ['Bakery Pastry Box', 'Bakery', 8.50, 12],
      ],
      summaryMetrics: {
        'Total Items': '2',
        'Total Units Rescued': '20',
        'Revenue Generated': 'GHS 222.00',
      },
      fileNamePrefix: 'inventory_statement',
    );

    test('generateExcel produces genuine valid .xlsx file bytes', () {
      final bytes = MerchantExportService.generateExcel(sampleDataset);
      expect(bytes.isNotEmpty, isTrue);
      // Valid Excel files are zip archives starting with 'PK' (0x50, 0x4B)
      expect(bytes[0], equals(0x50));
      expect(bytes[1], equals(0x4B));
      expect(bytes.length, greaterThan(1000));
    });

    test('generatePdf produces genuine valid .pdf file bytes', () async {
      final bytes = await MerchantExportService.generatePdf(sampleDataset);
      expect(bytes.isNotEmpty, isTrue);
      // Valid PDF documents start with '%PDF'
      final header = ascii.decode(bytes.sublist(0, 4));
      expect(header, equals('%PDF'));
      expect(bytes.length, greaterThan(1000));
    });

    test('generateCsv produces valid UTF-8 BOM CSV with headers and rows', () {
      final csv = MerchantExportService.generateCsv(sampleDataset);
      // Verify UTF-8 BOM
      expect(csv.startsWith('\uFEFF'), isTrue);
      // Verify headers
      expect(csv.contains('Deal Title,Category,Price (GHS),Units Rescued'), isTrue);
      // Verify rows
      expect(csv.contains('Lunch Rescue Pack,Restaurant Meal,15.0,8'), isTrue);
      expect(csv.contains('Bakery Pastry Box,Bakery,8.5,12'), isTrue);
    });

    test('CSV properly escapes special characters, quotes and commas', () {
      final specialDataset = ExportDataset(
        title: 'Special Characters Report',
        merchantName: 'A, B & "C" Kitchen',
        headers: ['Item Name', 'Notes'],
        rows: [
          ['Jollof, Fried Plantain & Chicken', 'Contains "Hot Pepper"\nFreshly prepared'],
        ],
        fileNamePrefix: 'special_report',
      );

      final csv = MerchantExportService.generateCsv(specialDataset);
      expect(csv.contains('"Jollof, Fried Plantain & Chicken"'), isTrue);
      expect(csv.contains('""Hot Pepper""'), isTrue);
    });
  });
}
