import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../models/wood_component.dart';
import '../models/order.dart';
import '../widgets/wood_input_tile.dart';
import '../utils/pdf_generator.dart';
import '../utils/order_storage.dart';
import 'result_screen.dart';
import 'order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WoodComponent> woodComponents = [];
  final TextEditingController orderIdController = TextEditingController();
  final TextEditingController itemDescriptionController = TextEditingController();
  final TextEditingController labourController = TextEditingController();
  final TextEditingController hardwareController = TextEditingController();
  final TextEditingController factoryController = TextEditingController();
  final TextEditingController profitController = TextEditingController();

  // Additional charges functionality
  List<Map<String, TextEditingController>> additionalCharges = [];

  final _formKey = GlobalKey<FormState>();
  final GlobalKey<WoodInputTileState> _woodInputKey = GlobalKey<WoodInputTileState>();
  String? selectedImagePath;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      try {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String imageDirPath = '${appDir.path}/item_images';
        final Directory imageDir = Directory(imageDirPath);

        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        final String fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String savedImagePath = '$imageDirPath/$fileName';

        await File(image.path).copy(savedImagePath);

        setState(() {
          selectedImagePath = savedImagePath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      selectedImagePath = null;
    });
  }

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

  // Additional charges methods
  void _addAdditionalCharge() {
    setState(() {
      additionalCharges.add({
        'name': TextEditingController(),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeAdditionalCharge(int index) {
    setState(() {
      // Dispose controllers to prevent memory leaks
      additionalCharges[index]['name']?.dispose();
      additionalCharges[index]['amount']?.dispose();
      additionalCharges.removeAt(index);
    });
  }

  double get totalAdditionalCharges {
    return additionalCharges.fold<double>(0, (sum, charge) {
      final amount = double.tryParse(charge['amount']?.text ?? '0') ?? 0;
      return sum + amount;
    });
  }

  void calculateAndNavigate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (woodComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one wood component'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double labour = double.tryParse(labourController.text) ?? 0;
    double hardware = double.tryParse(hardwareController.text) ?? 0;
    double factory = double.tryParse(factoryController.text) ?? 0;
    double profit = double.tryParse(profitController.text) ?? 0;

    double woodTotal = woodComponents.fold<double>(0, (sum, item) => sum + item.totalCost);
    double otherCosts = labour + hardware + factory + totalAdditionalCharges;
    double subtotal = woodTotal + otherCosts;
    double profitAmount = subtotal * (profit / 100);
    double finalAmount = subtotal + profitAmount;

    // Convert additional charges to the format expected by Order model
    List<Map<String, dynamic>> orderAdditionalCharges = additionalCharges.map((charge) {
      return {
        'name': charge['name']!.text,
        'amount': double.tryParse(charge['amount']!.text) ?? 0.0,
      };
    }).toList();

    final order = Order(
      orderId: orderIdController.text,
      itemDescription: itemDescriptionController.text,
      itemImagePath: selectedImagePath,
      components: List.from(woodComponents),
      labour: labour,
      hardware: hardware,
      factory: factory,
      additionalCharges: orderAdditionalCharges, // Include additional charges
      profit: profitAmount,
      total: finalAmount,
      date: DateTime.now(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text("Saving order...")),
            ],
          ),
        );
      },
    );

    try {
      // Save to local storage
      await OrderStorage.saveOrder(order);

      // Save to Firestore
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentCompany != null) {
        final orderService = OrderService();
        await orderService.saveOrder(order, authProvider.currentCompany!.id);
      }

      Navigator.of(context).pop();

      // Reset wood type after saving order
      _woodInputKey.currentState?.resetWoodType();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(order: order),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double get totalWoodCost {
    return woodComponents.fold<double>(0, (sum, item) => sum + item.totalCost);
  }

  double get totalCft {
    return woodComponents.fold<double>(0, (sum, item) => sum + item.cft);
  }

  void _generateSampleOrderId() {
    final now = DateTime.now();
    final orderId = 'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    setState(() {
      orderIdController.text = orderId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          child: Text(
            'Wood Cost Estimator',
            style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
          ),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Information Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Information',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Order ID Section
                        isSmallScreen
                            ? Column(
                          children: [
                            TextFormField(
                              controller: orderIdController,
                              decoration: const InputDecoration(
                                labelText: 'Order ID',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                                hintText: 'Enter unique order ID',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an order ID';
                                }
                                if (value.trim().length < 3) {
                                  return 'Order ID must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _generateSampleOrderId,
                                icon: const Icon(Icons.auto_awesome, size: 16),
                                label: const Text('Auto Generate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                            : Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: orderIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Order ID',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.numbers),
                                  hintText: 'Enter unique order ID',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter an order ID';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Order ID must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: ElevatedButton.icon(
                                onPressed: _generateSampleOrderId,
                                icon: const Icon(Icons.auto_awesome, size: 16),
                                label: const Text('Auto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Item Description
                        TextFormField(
                          controller: itemDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Item Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                            hintText: 'e.g., Dining Table 6-seater, Office Desk, etc.',
                          ),
                          maxLines: isSmallScreen ? 2 : 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter item description';
                            }
                            if (value.trim().length < 5) {
                              return 'Description must be at least 5 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Image Section
                        Text(
                          'Item Photo (Optional)',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (selectedImagePath != null) ...[
                          Container(
                            height: isSmallScreen ? 150 : 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          isSmallScreen
                              ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Retake Photo'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text('Remove Photo'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ),
                            ],
                          )
                              : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Retake Photo'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text('Remove Photo'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            height: isSmallScreen ? 100 : 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                              color: Colors.grey[50],
                            ),
                            child: InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: isSmallScreen ? 30 : 40,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to capture item photo',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Wood Input Section
                WoodInputTile(key: _woodInputKey, onAddComponent: addWoodComponent),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Added Components Section
                if (woodComponents.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isSmallScreen
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Added Components',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total: ₹${totalWoodCost.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'CFT: ${totalCft.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Added Components',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total: ₹${totalWoodCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Total CFT: ${totalCft.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          ...woodComponents.asMap().entries.map((entry) {
                            int index = entry.key;
                            WoodComponent component = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                                title: Text(
                                  '${component.woodType} - ${component.formattedSize}',
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CFT: ${component.cft.toStringAsFixed(2)} × ₹${component.ratePerCft} = ₹${component.totalCost.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                    ),
                                    Text(
                                      'Quantity: ${component.quantity} pieces',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: isSmallScreen ? 11 : 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                  onPressed: () => removeWoodComponent(index),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                ],

                // Costs Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Costs',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Standard Charges
                        if (isTablet) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: labourController,
                                  decoration: const InputDecoration(
                                    labelText: 'Labour Cost (₹)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.build),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      if (double.parse(value) < 0) {
                                        return 'Labour cost cannot be negative';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: hardwareController,
                                  decoration: const InputDecoration(
                                    labelText: 'Hardware Cost (₹)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.hardware),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      if (double.parse(value) < 0) {
                                        return 'Hardware cost cannot be negative';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: factoryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Factory Charges (₹)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.factory),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      if (double.parse(value) < 0) {
                                        return 'Factory charges cannot be negative';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ] else ...[
                          TextFormField(
                            controller: labourController,
                            decoration: const InputDecoration(
                              labelText: 'Labour Cost (₹)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.build),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                if (double.parse(value) < 0) {
                                  return 'Labour cost cannot be negative';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: hardwareController,
                            decoration: const InputDecoration(
                              labelText: 'Hardware Cost (₹)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.hardware),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                if (double.parse(value) < 0) {
                                  return 'Hardware cost cannot be negative';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: factoryController,
                            decoration: const InputDecoration(
                              labelText: 'Factory Charges (₹)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.factory),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                if (double.parse(value) < 0) {
                                  return 'Factory charges cannot be negative';
                                }
                              }
                              return null;
                            },
                          ),
                        ],

                        // Additional Charges Section
                        if (additionalCharges.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Other Charges',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 8),

                          ...additionalCharges.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, TextEditingController> charge = entry.value;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: isSmallScreen
                                    ? Column(
                                  children: [
                                    TextFormField(
                                      controller: charge['name'],
                                      decoration: const InputDecoration(
                                        labelText: 'Charge Name',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.label),
                                        isDense: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Enter charge name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: charge['amount'],
                                            decoration: const InputDecoration(
                                              labelText: 'Amount (₹)',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.currency_rupee),
                                              isDense: true,
                                            ),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            validator: (value) {
                                              if (value != null && value.isNotEmpty) {
                                                if (double.tryParse(value) == null) {
                                                  return 'Invalid number';
                                                }
                                                if (double.parse(value) < 0) {
                                                  return 'Cannot be negative';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeAdditionalCharge(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                                    : Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: charge['name'],
                                        decoration: const InputDecoration(
                                          labelText: 'Charge Name',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.label),
                                          isDense: true,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Enter charge name';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: charge['amount'],
                                        decoration: const InputDecoration(
                                          labelText: 'Amount (₹)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.currency_rupee),
                                          isDense: true,
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        validator: (value) {
                                          if (value != null && value.isNotEmpty) {
                                            if (double.tryParse(value) == null) {
                                              return 'Invalid number';
                                            }
                                            if (double.parse(value) < 0) {
                                              return 'Cannot be negative';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeAdditionalCharge(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                          if (additionalCharges.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Additional Charges Total:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₹${totalAdditionalCharges.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 12),

                        // Add Other Charges Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addAdditionalCharge,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Other Charges'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                              side: BorderSide(color: Colors.orange[300]!),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Profit Field
                        TextFormField(
                          controller: profitController,
                          decoration: const InputDecoration(
                            labelText: 'Profit Percentage (%)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.percent),
                            hintText: 'e.g., 20 for 20%',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              double profit = double.parse(value);
                              if (profit < 0 || profit > 100) {
                                return 'Profit should be between 0-100%';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 24 : 30),

                // Calculate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: calculateAndNavigate,
                    icon: const Icon(Icons.save_alt),
                    label: Text(
                      isSmallScreen ? 'Save & Calculate' : 'Save Order & Calculate',
                      style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    orderIdController.dispose();
    itemDescriptionController.dispose();
    labourController.dispose();
    hardwareController.dispose();
    factoryController.dispose();
    profitController.dispose();

    // Dispose additional charges controllers
    for (var charge in additionalCharges) {
      charge['name']?.dispose();
      charge['amount']?.dispose();
    }

    super.dispose();
  }
}