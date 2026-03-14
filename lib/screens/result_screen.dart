import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import '../models/order.dart';
import '../utils/pdf_generator.dart';

class ResultScreen extends StatelessWidget {
  final Order order;

  const ResultScreen({
    super.key,
    required this.order,
  });

  Future<void> _generatePDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Saving to Downloads..."),
            ],
          ),
        );
      },
    );

    try {
      final pdfFile =
      await PDFGenerator.generate(order, context: context);
      if (!context.mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'PDF saved to Downloads!\n${pdfFile.path}'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printPDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Preparing for print..."),
            ],
          ),
        );
      },
    );

    try {
      final pdfBytes =
      await PDFGenerator.generateBytes(order, context: context);
      if (!context.mounted) return;
      Navigator.of(context).pop();

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'WoodRatePro_${order.orderId}',
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error preparing print: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Preparing to share..."),
            ],
          ),
        );
      },
    );

    try {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await PDFGenerator.shareOrder(order, context: context);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePDF(context),
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printPDF(context),
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePDF(context),
            tooltip: 'Save PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SAVED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.numbers,
                            color: Colors.brown),
                        const SizedBox(width: 8),
                        Text(
                          'Order ID: ${order.orderId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.description,
                            color: Colors.brown),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Item: ${order.itemDescription}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.brown),
                        const SizedBox(width: 8),
                        Text(
                          'Date: ${dateFormat.format(order.date)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    // Item Image
                    if (order.itemImagePath != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Item Photo:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight:
                                  MediaQuery.of(context)
                                      .size
                                      .height *
                                      0.8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      title: const Text(
                                          'Item Photo'),
                                      automaticallyImplyLeading:
                                      false,
                                      actions: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.close),
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Image.file(
                                        File(order.itemImagePath!),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(8),
                            child: Image.file(
                              File(order.itemImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                      children: [
                                        Icon(Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey),
                                        Text('Image not found',
                                            style: TextStyle(
                                                color:
                                                Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Wood Components
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.forest, color: Colors.brown),
                        SizedBox(width: 8),
                        Text(
                          'Wood Components',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...order.components
                        .map((component) => Container(
                      margin:
                      const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${component.woodType} (${component.formattedSize})',
                                  style: const TextStyle(
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'CFT: ${component.cft.toStringAsFixed(2)} × ₹${component.ratePerCft}/CFT',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Quantity: ${component.quantity} pieces',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${component.totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ))
                        .toList(),
                    const Divider(thickness: 2),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Wood Subtotal:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '₹${order.woodTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total CFT:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${order.totalCft.toStringAsFixed(2)} CFT',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Additional Costs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.attach_money,
                            color: Colors.brown),
                        SizedBox(width: 8),
                        Text(
                          'Additional Costs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCostRow(
                        'Labour', order.labour, Icons.build),
                    _buildCostRow(
                        'Hardware', order.hardware, Icons.hardware),
                    _buildCostRow('Factory Charges', order.factory,
                        Icons.factory),
                    if (order.additionalCharges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Other Charges:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.additionalCharges
                          .map((charge) => _buildCostRow(
                        charge['name'] as String,
                        charge['amount'] as double,
                        Icons.payment,
                      ))
                          .toList(),
                      const SizedBox(height: 8),
                      _buildCostRow(
                        'Additional Total',
                        order.additionalChargesTotal,
                        Icons.calculate,
                        isHighlighted: true,
                      ),
                    ],
                    const Divider(),
                    _buildCostRow(
                        'Profit', order.profit, Icons.trending_up),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Total
            Card(
              color: Colors.brown[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.summarize,
                            color: Colors.brown, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Total Cost:',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            // Action Buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sharePDF(context),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share via WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _printPDF(context),
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generatePDF(context),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Save to Downloads'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // New Order Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, IconData icon,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding:
        isHighlighted ? const EdgeInsets.all(8) : EdgeInsets.zero,
        decoration: isHighlighted
            ? BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange[200]!),
        )
            : null,
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isHighlighted
                    ? Colors.orange[700]
                    : Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isHighlighted
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color:
                  isHighlighted ? Colors.orange[800] : null,
                ),
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                isHighlighted ? Colors.orange[800] : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}