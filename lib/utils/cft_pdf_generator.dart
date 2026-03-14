import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../models/wood_component.dart';
import '../utils/company_profile.dart';

class CftPdfGenerator {
  static Future<File> generate({
    required List<WoodComponent> components,
    required String reportTitle,
  }) async {
    final pdf = await _createPDF(components: components, reportTitle: reportTitle);

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        "${directory.path}/cft_report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<Uint8List> generateBytes({
    required List<WoodComponent> components,
    required String reportTitle,
  }) async {
    final pdf = await _createPDF(components: components, reportTitle: reportTitle);
    return pdf.save();
  }

  static Future<pw.Document> _createPDF({
    required List<WoodComponent> components,
    required String reportTitle,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');

    // Load dynamic company name
    final companyName =
        await CompanyProfile.getCompanyName() ?? 'WoodRate Pro';

    double totalCft =
    components.fold<double>(0, (sum, component) => sum + component.cft);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        "CFT REPORT",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    reportTitle,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Report Information
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Report Generated: ${dateFormat.format(DateTime.now())}",
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "Total Components: ${components.length}",
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.blue300),
                    ),
                    child: pw.Text(
                      "Total CFT: ${totalCft.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 25),

            pw.Text(
              "Wood Components Breakdown",
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Wood Type",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Dimensions",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Quantity",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("CFT",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...components
                    .map((component) => pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(component.woodType)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(component.formattedSize)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                            "${component.quantity} pcs")),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        component.cft.toStringAsFixed(2),
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ))
                    .toList(),
                pw.TableRow(
                  decoration:
                  const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("TOTAL",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("")),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        "${components.fold<int>(0, (sum, c) => sum + c.quantity)} pcs",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        "${totalCft.toStringAsFixed(2)} CFT",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                            color: PdfColors.blue800),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Formula Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("CFT Calculation Formula:",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                      "CFT = (Length in ft × Width in inches × Thickness in inches) ÷ 144 × Quantity",
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 8),
                  pw.Text("Notes:",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                      "• Units are automatically converted for accurate CFT calculation.",
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                      "• CFT (Cubic Feet Timber) is the standard measurement for wood volume.",
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Generated by $companyName • WoodRate Pro",
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  "Powered by NishantCreation",
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }
}