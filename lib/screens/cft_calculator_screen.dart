import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/wood_component.dart';
import '../widgets/wood_input_tile.dart';
import '../utils/cft_pdf_generator.dart';

class CftCalculatorScreen extends StatefulWidget {
  const CftCalculatorScreen({super.key});

  @override
  State<CftCalculatorScreen> createState() => _CftCalculatorScreenState();
}

class _CftCalculatorScreenState extends State<CftCalculatorScreen> {
  List<WoodComponent> woodComponents = [];
  final TextEditingController reportTitleController = TextEditingController();

  void addWoodComponent(WoodComponent component) {
    setState(() {
      woodComponents.add(component);
    });
  }

  void removeWoodComponent(int index) {
    setState(() {
      woodComponents.removeAt(index);
    });
  }

  double get totalCft {
    return woodComponents.fold<double>(0, (sum, item) => sum + item.cft);
  }

  void _clearAll() {
    setState(() {
      woodComponents.clear();
      reportTitleController.clear();
    });
  }

  Future<void> _generatePDF() async {
    if (woodComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one wood component'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating CFT Report..."),
            ],
          ),
        );
      },
    );

    try {
      // Generate PDF
      final pdfFile = await CftPdfGenerator.generate(
        components: woodComponents,
        reportTitle: reportTitleController.text.isEmpty
            ? 'CFT Calculation Report'
            : reportTitleController.text,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CFT Report saved successfully!\nLocation: ${pdfFile.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating CFT report: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _printPDF() async {
    if (woodComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one wood component'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Preparing CFT report for print..."),
            ],
          ),
        );
      },
    );

    try {
      // Generate PDF bytes for printing
      final pdfBytes = await CftPdfGenerator.generateBytes(
        components: woodComponents,
        reportTitle: reportTitleController.text.isEmpty
            ? 'CFT Calculation Report'
            : reportTitleController.text,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Open print dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'CFT_Report_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error preparing CFT report for print: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CFT Calculator'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printPDF,
            tooltip: 'Print CFT Report',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: 'Save CFT Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Title Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reportTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Report Title (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                        hintText: 'e.g., Wood Stock Calculation, Project XYZ CFT',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Wood Input Section
            WoodInputTile(onAddComponent: addWoodComponent),

            const SizedBox(height: 20),

            // CFT Summary Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calculate, color: Colors.blue, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Total CFT:',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${totalCft.toStringAsFixed(2)} CFT',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Added Components Section
            if (woodComponents.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Wood Components',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _clearAll,
                            icon: const Icon(Icons.clear_all, color: Colors.red),
                            label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...woodComponents.asMap().entries.map((entry) {
                        int index = entry.key;
                        WoodComponent component = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey[50],
                          child: ListTile(
                            title: Text('${component.woodType} - ${component.formattedSize}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantity: ${component.quantity} pieces',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'CFT: ${component.cft.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeWoodComponent(index),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _printPDF,
                      icon: const Icon(Icons.print),
                      label: const Text('Print Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generatePDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Save PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Empty State
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.forest,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No wood components added yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add wood components above to calculate CFT',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    reportTitleController.dispose();
    super.dispose();
  }
}