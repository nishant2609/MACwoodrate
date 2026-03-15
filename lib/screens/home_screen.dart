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
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientCompanyController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController labourController = TextEditingController();
  final TextEditingController hardwareController = TextEditingController();
  final TextEditingController factoryController = TextEditingController();
  final TextEditingController profitController = TextEditingController();
  String _selectedStatus = 'Pending';

  List<Map<String, TextEditingController>> additionalCharges = [];

  final _formKey = GlobalKey<FormState>();
  final GlobalKey<WoodInputTileState> _woodInputKey =
  GlobalKey<WoodInputTileState>();
  String? selectedImagePath;

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

        final String fileName =
            'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      additionalCharges[index]['name']?.dispose();
      additionalCharges[index]['amount']?.dispose();
      additionalCharges.removeAt(index);
    });
  }

  double get totalAdditionalCharges {
    return additionalCharges.fold<double>(0, (sum, charge) {
      final amount =
          double.tryParse(charge['amount']?.text ?? '0') ?? 0;
      return sum + amount;
    });
  }

  void calculateAndNavigate() async {
    if (!_formKey.currentState!.validate()) return;

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

    double woodTotal = woodComponents.fold<double>(
        0, (sum, item) => sum + item.totalCost);
    double otherCosts =
        labour + hardware + factory + totalAdditionalCharges;
    double subtotal = woodTotal + otherCosts;
    double profitAmount = subtotal * (profit / 100);
    double finalAmount = subtotal + profitAmount;

    List<Map<String, dynamic>> orderAdditionalCharges =
    additionalCharges.map((charge) {
      return {
        'name': charge['name']!.text,
        'amount': double.tryParse(charge['amount']!.text) ?? 0.0,
      };
    }).toList();

    final order = Order(
      orderId: orderIdController.text,
      itemDescription: itemDescriptionController.text,
      itemImagePath: selectedImagePath,
      clientName: clientNameController.text.trim().isEmpty
          ? null
          : clientNameController.text.trim(),
      clientCompany: clientCompanyController.text.trim().isEmpty
          ? null
          : clientCompanyController.text.trim(),
      status: _selectedStatus,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      components: List.from(woodComponents),
      labour: labour,
      hardware: hardware,
      factory: factory,
      additionalCharges: orderAdditionalCharges,
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
      await OrderStorage.saveOrder(order);

      if (!mounted) return;
      final authProvider =
      Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentCompany != null) {
        final orderService = OrderService();
        await orderService.saveOrder(
            order, authProvider.currentCompany!.id);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      _woodInputKey.currentState?.resetWoodType();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
    return woodComponents.fold<double>(
        0, (sum, item) => sum + item.totalCost);
  }

  double get totalCft {
    return woodComponents.fold<double>(
        0, (sum, item) => sum + item.cft);
  }

  void _generateSampleOrderId() {
    final now = DateTime.now();
    final orderId =
        'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    setState(() {
      orderIdController.text = orderId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet =
        screenSize.width >= 600 && screenSize.width < 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wood Cost Estimator'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                    const OrderHistoryScreen()),
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
                // ═══════════════════════════════
                // ORDER INFORMATION CARD
                // ═══════════════════════════════
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                    EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.brown
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.brown,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Order Information',
                              style: TextStyle(
                                fontSize:
                                isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                            height: isSmallScreen ? 16 : 20),

                        // Order ID
                        isSmallScreen
                            ? Column(
                          children: [
                            TextFormField(
                              controller: orderIdController,
                              decoration:
                              const InputDecoration(
                                labelText: 'Order ID',
                                border: OutlineInputBorder(),
                                prefixIcon:
                                Icon(Icons.numbers),
                                hintText:
                                'Enter unique order ID',
                                contentPadding:
                                EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter an order ID';
                                }
                                if (value.trim().length<3) {
                                  return 'Order ID must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                _generateSampleOrderId,
                                icon: const Icon(
                                    Icons.auto_awesome,
                                    size: 16),
                                label: const Text(
                                    'Auto Generate'),
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Colors.grey[600],
                                  foregroundColor:
                                  Colors.white,
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
                                decoration:
                                const InputDecoration(
                                  labelText: 'Order ID',
                                  border:
                                  OutlineInputBorder(),
                                  prefixIcon:
                                  Icon(Icons.numbers),
                                  hintText:
                                  'Enter unique order ID',
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Please enter an order ID';
                                  }
                                  if (value.trim().length<
                                  3) {
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
                                onPressed:
                                _generateSampleOrderId,
                                icon: const Icon(
                                    Icons.auto_awesome,
                                    size: 16),
                                label: const Text('Auto'),
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Colors.grey[600],
                                  foregroundColor:
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                            height: isSmallScreen ? 12 : 16),

                        // Item Description
                        TextFormField(
                          controller: itemDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Item Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                            hintText:
                            'e.g., Dining Table 6-seater, Office Desk',
                          ),
                          maxLines: isSmallScreen ? 2 : 3,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter item description';
                            }
                            if (value.trim().length < 5) {
                              return 'Description must be at least 5 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(
                            height: isSmallScreen ? 12 : 16),

                        // Order Status
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Order Status',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.flag_outlined,
                              color:
                              _getStatusColor(_selectedStatus),
                            ),
                          ),
                          items: [
                            'Pending',
                            'Confirmed',
                            'In Progress',
                            'Delivered',
                            'Cancelled'
                          ]
                              .map((status) =>
                              DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(status),
                                  ],
                                ),
                              ))
                              .toList(),
                          onChanged: (value) {
                            setState(
                                    () => _selectedStatus = value!);
                          },
                        ),

                        SizedBox(
                            height: isSmallScreen ? 12 : 16),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // ═══════════════════════════════
                // CLIENT INFORMATION CARD
                // ═══════════════════════════════
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                    EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Client Information',
                              style: TextStyle(
                                fontSize:
                                isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                            height: isSmallScreen ? 16 : 20),

                        // Client Name
                        TextFormField(
                          controller: clientNameController,
                          textCapitalization:
                          TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Client Name',
                            border: OutlineInputBorder(),
                            prefixIcon:
                            Icon(Icons.person_outline),
                            hintText: 'e.g., Rajesh Kumar',
                          ),
                        ),

                        SizedBox(
                            height: isSmallScreen ? 12 : 16),

                        // Client Company
                        TextFormField(
                          controller: clientCompanyController,
                          textCapitalization:
                          TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Client Company',
                            border: OutlineInputBorder(),
                            prefixIcon:
                            Icon(Icons.business_outlined),
                            hintText:
                            'e.g., Kumar Furniture House',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // ═══════════════════════════════
                // ITEM PHOTO CARD
                // ═══════════════════════════════
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                    EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Item Photo',
                              style: TextStyle(
                                fontSize:
                                isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[600],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (selectedImagePath != null) ...[
                          Container(
                            height: isSmallScreen ? 150 : 200,
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
                                File(selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(
                                      Icons.camera_alt),
                                  label: const Text(
                                      'Retake Photo'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  label: const Text(
                                      'Remove Photo'),
                                  style:
                                  OutlinedButton.styleFrom(
                                      foregroundColor:
                                      Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            height: isSmallScreen ? 100 : 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey[300]!),
                              color: Colors.grey[50],
                            ),
                            child: InkWell(
                              onTap: _pickImage,
                              borderRadius:
                              BorderRadius.circular(8),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      size: isSmallScreen
                                          ? 30
                                          : 40,
                                      color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to capture item photo',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize:
                                      isSmallScreen ? 12 : 14,
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
                WoodInputTile(
                    key: _woodInputKey,
                    onAddComponent: addWoodComponent),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Added Components Section
                if (woodComponents.isNotEmpty) ...[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                          isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Added Components',
                                style: TextStyle(
                                  fontSize:
                                  isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${totalWoodCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    '${totalCft.toStringAsFixed(2)} CFT',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...woodComponents
                              .asMap()
                              .entries
                              .map((entry) {
                            int index = entry.key;
                            WoodComponent component = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(
                                  bottom: 8),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(
                                    isSmallScreen ? 8 : 12),
                                title: Text(
                                  '${component.woodType} - ${component.formattedSize}',
                                  style: TextStyle(
                                      fontSize:
                                      isSmallScreen ? 14 : 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CFT: ${component.cft.toStringAsFixed(2)} × Rs.${component.ratePerCft} = Rs.${component.totalCost.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: isSmallScreen
                                              ? 12
                                              : 14),
                                    ),
                                    Text(
                                      'Qty: ${component.quantity} pcs',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize:
                                        isSmallScreen ? 11 : 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Colors.red,
                                      size:
                                      isSmallScreen ? 20 : 24),
                                  onPressed: () =>
                                      removeWoodComponent(index),
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

                // ═══════════════════════════════
                // COSTS CARD
                // ═══════════════════════════════
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                    EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.attach_money,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Additional Costs',
                              style: TextStyle(
                                fontSize:
                                isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(
                            height: isSmallScreen ? 12 : 16),

                        if (isTablet) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: labourController,
                                  decoration:
                                  const InputDecoration(
                                    labelText: 'Labour Cost (Rs.)',
                                    border: OutlineInputBorder(),
                                    prefixIcon:
                                    Icon(Icons.build),
                                  ),
                                  keyboardType: const TextInputType
                                      .numberWithOptions(
                                      decimal: true),
                                  validator: (value) {
                                    if (value != null &&
                                        value.isNotEmpty) {
                                      if (double.tryParse(value) ==
                                          null) {
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: hardwareController,
                                  decoration:
                                  const InputDecoration(
                                    labelText:
                                    'Hardware Cost (Rs.)',
                                    border: OutlineInputBorder(),
                                    prefixIcon:
                                    Icon(Icons.hardware),
                                  ),
                                  keyboardType: const TextInputType
                                      .numberWithOptions(
                                      decimal: true),
                                  validator: (value) {
                                    if (value != null &&
                                        value.isNotEmpty) {
                                      if (double.tryParse(value) ==
                                          null) {
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
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: factoryController,
                                  decoration:
                                  const InputDecoration(
                                    labelText:
                                    'Factory Charges (Rs.)',
                                    border: OutlineInputBorder(),
                                    prefixIcon:
                                    Icon(Icons.factory),
                                  ),
                                  keyboardType: const TextInputType
                                      .numberWithOptions(
                                      decimal: true),
                                  validator: (value) {
                                    if (value != null &&
                                        value.isNotEmpty) {
                                      if (double.tryParse(value) ==
                                          null) {
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
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ] else ...[
                          TextFormField(
                            controller: labourController,
                            decoration: const InputDecoration(
                              labelText: 'Labour Cost (Rs.)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.build),
                            ),
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty) {
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: hardwareController,
                            decoration: const InputDecoration(
                              labelText: 'Hardware Cost (Rs.)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.hardware),
                            ),
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty) {
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: factoryController,
                            decoration: const InputDecoration(
                              labelText: 'Factory Charges (Rs.)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.factory),
                            ),
                            keyboardType: const TextInputType
                                .numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty) {
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
                        ],

                        // Additional Charges
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
                          ...additionalCharges
                              .asMap()
                              .entries
                              .map((entry) {
                            int index = entry.key;
                            Map<String, TextEditingController>
                            charge = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(
                                  bottom: 8),
                              color: Colors.orange[50],
                              child: Padding(
                                padding:
                                const EdgeInsets.all(12),
                                child: isSmallScreen
                                    ? Column(
                                  children: [
                                    TextFormField(
                                      controller:
                                      charge['name'],
                                      decoration:
                                      const InputDecoration(
                                        labelText:
                                        'Charge Name',
                                        border:
                                        OutlineInputBorder(),
                                        prefixIcon: Icon(
                                            Icons.label),
                                        isDense: true,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value
                                                .trim()
                                                .isEmpty) {
                                          return 'Enter charge name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(
                                        height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                          TextFormField(
                                            controller: charge[
                                            'amount'],
                                            decoration:
                                            const InputDecoration(
                                              labelText:
                                              'Amount',
                                              border:
                                              OutlineInputBorder(),
                                              prefixIcon: Icon(
                                                  Icons
                                                      .currency_rupee),
                                              isDense: true,
                                            ),
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            validator: (value) {
                                              if (value !=
                                                  null &&
                                                  value
                                                      .isNotEmpty) {
                                                if (double.tryParse(
                                                    value) ==
                                                    null) {
                                                  return 'Invalid';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete,
                                              color:
                                              Colors.red),
                                          onPressed: () =>
                                              _removeAdditionalCharge(
                                                  index),
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
                                        controller:
                                        charge['name'],
                                        decoration:
                                        const InputDecoration(
                                          labelText:
                                          'Charge Name',
                                          border:
                                          OutlineInputBorder(),
                                          prefixIcon: Icon(
                                              Icons.label),
                                          isDense: true,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value
                                                  .trim()
                                                  .isEmpty) {
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
                                        controller:
                                        charge['amount'],
                                        decoration:
                                        const InputDecoration(
                                          labelText: 'Amount',
                                          border:
                                          OutlineInputBorder(),
                                          prefixIcon: Icon(Icons
                                              .currency_rupee),
                                          isDense: true,
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true),
                                        validator: (value) {
                                          if (value != null &&
                                              value
                                                  .isNotEmpty) {
                                            if (double.tryParse(
                                                value) ==
                                                null) {
                                              return 'Invalid';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _removeAdditionalCharge(
                                              index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Additional Total:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Rs.${totalAdditionalCharges.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addAdditionalCharge,
                            icon: const Icon(Icons.add),
                            label:
                            const Text('Add Other Charges'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                              side: BorderSide(
                                  color: Colors.orange[300]!),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: profitController,
                          decoration: const InputDecoration(
                            labelText: 'Profit Percentage (%)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.percent),
                            hintText: 'e.g., 20 for 20%',
                          ),
                          keyboardType: const TextInputType
                              .numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty) {
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              double p = double.parse(value);
                              if (p < 0 || p > 100) {
                                return 'Profit should be 0-100%';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // ═══════════════════════════════
                // NOTES CARD
                // ═══════════════════════════════
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                    EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.note_outlined,
                                color: Colors.purple,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Notes',
                              style: TextStyle(
                                fontSize:
                                isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Order Notes',
                            border: OutlineInputBorder(),
                            prefixIcon:
                            Icon(Icons.note_outlined),
                            hintText:
                            'Any special requirements or notes...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 24 : 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: calculateAndNavigate,
                    icon: const Icon(Icons.save_alt),
                    label: Text(
                      'Save & Calculate',
                      style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
    clientNameController.dispose();
    clientCompanyController.dispose();
    notesController.dispose();
    labourController.dispose();
    hardwareController.dispose();
    factoryController.dispose();
    profitController.dispose();
    for (var charge in additionalCharges) {
      charge['name']?.dispose();
      charge['amount']?.dispose();
    }
    super.dispose();
  }
}