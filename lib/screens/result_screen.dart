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
                child: Text('PDF saved to Downloads!\n${pdfFile.path}'),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'In Progress':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printPDF(context),
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.download),
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

            // ═══════════════════════════════
            // ORDER DETAILS CARD
            // ═══════════════════════════════
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                        Row(
                          children: [
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                    order.status ?? 'Pending'),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status ?? 'Pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5),
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
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _infoRow(Icons.numbers, Colors.brown,
                        'Order ID: ${order.orderId}'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.description, Colors.brown,
                        'Item: ${order.itemDescription}',
                        color: Colors.blue),
                    const SizedBox(height: 8),
                    _infoRow(Icons.access_time, Colors.brown,
                        'Date: ${dateFormat.format(order.date)}'),

                    // Client Info
                    if (order.clientName != null &&
                        order.clientName!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow(Icons.person_outline,
                          Colors.blue,
                          'Client: ${order.clientName}'),
                    ],
                    if (order.clientCompany != null &&
                        order.clientCompany!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow(Icons.business_outlined,
                          Colors.blue,
                          'Company: ${order.clientCompany}'),
                    ],

                    // Notes
                    if (order.notes != null &&
                        order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius:
                          BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.purple[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_outlined,
                                    size: 16,
                                    color: Colors.purple[700]),
                                const SizedBox(width: 6),
                                Text(
                                  'Notes:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.notes!,
                              style: TextStyle(
                                color: Colors.purple[800],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                                  mainAxisSize:
                                  MainAxisSize.min,
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
                                        File(order
                                            .itemImagePath!),
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
                              errorBuilder: (context, error,
                                  stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey),
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

            // ═══════════════════════════════
            // WOOD COMPONENTS CARD
            // ═══════════════════════════════
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                      margin: const EdgeInsets.only(
                          bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  '${component.woodType} (${component.formattedSize})',
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'CFT: ${component.cft.toStringAsFixed(2)} × Rs.${component.ratePerCft}/CFT',
                                  style: TextStyle(
                                    color:
                                    Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Qty: ${component.quantity} pcs',
                                  style:
                                  const TextStyle(
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
                            'Rs.${component.totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight:
                              FontWeight.bold,
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
                        const Text('Wood Subtotal:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(
                          'Rs.${order.woodTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total CFT:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(
                          '${order.totalCft.toStringAsFixed(2)} CFT',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════
            // ADDITIONAL COSTS CARD
            // ═══════════════════════════════
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                    _buildCostRow('Hardware', order.hardware,
                        Icons.hardware),
                    _buildCostRow('Factory Charges',
                        order.factory, Icons.factory),
                    if (order.additionalCharges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
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

            // ═══════════════════════════════
            // TOTAL CARD
            // ═══════════════════════════════
            Card(
              color: Colors.brown[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                            Colors.brown.withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.summarize,
                              color: Colors.brown, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Total Estimated Cost',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Rs.${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════
            // ACTION BUTTONS
            // ═══════════════════════════════
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _sharePDF(context),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share via WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _printPDF(context),
                        icon: const Icon(Icons.print,
                            size: 18),
                        label: const Text('Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _generatePDF(context),
                        icon: const Icon(Icons.download,
                            size: 18),
                        label: const Text('Save PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).popUntil(
                                (route) => route.isFirst),
                    icon: const Icon(Icons.home),
                    label: const Text('Back to Home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, Color iconColor, String text,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(
      String label, double amount, IconData icon,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: isHighlighted
            ? const EdgeInsets.all(8)
            : EdgeInsets.zero,
        decoration: isHighlighted
            ? BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(6),
          border:
          Border.all(color: Colors.orange[200]!),
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
                  color: isHighlighted
                      ? Colors.orange[800]
                      : null,
                ),
              ),
            ),
            Text(
              'Rs.${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isHighlighted
                    ? Colors.orange[800]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}