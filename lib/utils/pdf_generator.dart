import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';

class PDFGenerator {
  static Future<File> generate(Order order) async {
    final pdf = await _createPDF(order);

    // Save PDF to Downloads folder on Android
    String downloadsPath;
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        downloadsPath = '${directory.path}/Download';
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        downloadsPath = appDir.path;
      }
    } catch (e) {
      final appDir = await getApplicationDocumentsDirectory();
      downloadsPath = appDir.path;
    }

    // Create downloads directory if it doesn't exist
    final downloadsDir = Directory(downloadsPath);
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final file = File("$downloadsPath/order_${order.orderId}_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<Uint8List> generateBytes(Order order) async {
    final pdf = await _createPDF(order);
    return pdf.save();
  }

  static Future<pw.Document> _createPDF(Order order) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');

    // Use a more explicit currency formatter for better symbol display
    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

    String formatCurrency(double amount) {
      return 'Rs.${currencyFormat.format(amount)}';
    }

    // Calculate wood subtotal
    double woodSubtotal = order.woodTotal;
    double otherCosts = order.labour + order.hardware + order.factory + order.additionalChargesTotal;
    double subtotalBeforeProfit = woodSubtotal + otherCosts;

    // Calculate profit percentage from the stored profit amount
    double profitPercentage = subtotalBeforeProfit > 0 ? (order.profit / subtotalBeforeProfit) * 100 : 0;

    // Load item image if available
    pw.ImageProvider? itemImage;
    if (order.itemImagePath != null) {
      try {
        final imageFile = File(order.itemImagePath!);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          itemImage = pw.MemoryImage(imageBytes);
        }
      } catch (e) {
        // If image loading fails, continue without image
        itemImage = null;
      }
    }

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
                color: PdfColors.brown100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "MacWoodRate",
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.brown800,
                        ),
                      ),
                      pw.Text(
                        "COST ESTIMATE",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.brown600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Dining Table Manufacturing Cost Report",
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.brown700,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Order Information
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Order details column
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  "Order ID: ${order.orderId}",
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  "Date: ${dateFormat.format(order.date)}",
                                  style: const pw.TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.green100,
                                borderRadius: pw.BorderRadius.circular(15),
                                border: pw.Border.all(color: PdfColors.green300),
                              ),
                              child: pw.Text(
                                "CONFIRMED",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            borderRadius: pw.BorderRadius.circular(5),
                            border: pw.Border.all(color: PdfColors.blue200),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "Item Description:",
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue800,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                order.itemDescription,
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Item image column (if available)
                  if (itemImage != null) ...[
                    pw.SizedBox(width: 15),
                    pw.Container(
                      width: 120,
                      height: 120,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Image(
                        itemImage,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            pw.SizedBox(height: 25),

            // Wood Components Section
            pw.Text(
              "Wood Components",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.brown800,
              ),
            ),
            pw.SizedBox(height: 10),

            // Wood Components Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(0.8),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1.2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "Wood Type",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "Dimensions",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text("Rate/CFT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "Qty",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "CFT",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "Total",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                // Data Rows
                ...order.components.map((component) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(component.woodType, style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(component.formattedSize, style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(formatCurrency(component.ratePerCft), style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(component.quantity.toString(), style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(component.cft.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(formatCurrency(component.totalCost), style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                )).toList(),
                // Wood Subtotal Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "Wood Subtotal",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("")),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("")),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${order.totalCft.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        formatCurrency(woodSubtotal),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Summary Section
            pw.Text(
              "Cost Summary",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.brown800,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2)
                },
                children: [
                  _buildSummaryRow("Wood Components", woodSubtotal, formatCurrency),
                  _buildSummaryRow("Labour Charges", order.labour, formatCurrency),
                  _buildSummaryRow("Hardware Costs", order.hardware, formatCurrency),
                  _buildSummaryRow("Factory Overheads", order.factory, formatCurrency),

                  // Additional charges section
                  if (order.additionalCharges.isNotEmpty) ...[
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Container(
                            height: 1,
                            color: PdfColors.grey400,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Container(
                            height: 1,
                            color: PdfColors.grey400,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            "Other Charges",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.orange800,
                            ),
                          ),
                        ),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("")),
                      ],
                    ),
                    // Individual additional charges
                    ...order.additionalCharges.map((charge) => _buildSummaryRow(
                      charge['name'] as String,
                      charge['amount'] as double,
                      formatCurrency,
                    )).toList(),
                    // Additional charges subtotal
                    _buildSummaryRow(
                      "Additional Charges Total",
                      order.additionalChargesTotal,
                      formatCurrency,
                      isBold: true,
                      backgroundColor: PdfColors.orange100,
                    ),
                  ],

                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Container(
                          height: 1,
                          color: PdfColors.grey400,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Container(
                          height: 1,
                          color: PdfColors.grey400,
                        ),
                      ),
                    ],
                  ),
                  _buildSummaryRow("Subtotal Before Profit", subtotalBeforeProfit, formatCurrency, isBold: true),
                  _buildSummaryRow("Profit (${profitPercentage.toStringAsFixed(1)}%)", order.profit, formatCurrency),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Container(
                          height: 2,
                          color: PdfColors.brown800,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Container(
                          height: 2,
                          color: PdfColors.brown800,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.brown50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          "TOTAL ESTIMATED COST",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: PdfColors.brown800,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          formatCurrency(order.total),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: PdfColors.green800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Footer
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Notes:",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "• This is an estimated cost calculation for ${order.itemDescription}.",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    "• Actual costs may vary based on market conditions and specific requirements.",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    "• All prices are in Indian Rupees (₹).",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (order.additionalCharges.isNotEmpty) ...[
                    pw.Text(
                      "• Additional charges include custom fees and requirements.",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Generated by MacWoodRate App",
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        "Page 1 of 1",
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
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

    return pdf;
  }

  // Helper method to build summary rows
  static pw.TableRow _buildSummaryRow(
      String label,
      double amount,
      String Function(double) formatCurrency, {
        bool isBold = false,
        PdfColor? backgroundColor,
      }) {
    return pw.TableRow(
      decoration: backgroundColor != null ? pw.BoxDecoration(color: backgroundColor) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isBold ? 14 : 12,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            formatCurrency(amount),
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isBold ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }
}
