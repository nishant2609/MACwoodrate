import 'package:flutter/material.dart';
import '../models/wood_component.dart';

class WoodInputTile extends StatefulWidget {
  final Function(WoodComponent) onAddComponent;

  const WoodInputTile({super.key, required this.onAddComponent});

  @override
  State<WoodInputTile> createState() => WoodInputTileState();
}

class WoodInputTileState extends State<WoodInputTile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController woodTypeController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController thicknessController = TextEditingController();
  final TextEditingController ratePerCftController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  String? selectedWoodType;
  String lengthUnit = 'ft';
  String widthUnit = 'inch';
  String thicknessUnit = 'inch';

  final List<String> woodTypes = [
    'Teak',
    'Rosewood',
    'Sal',
    'Mango',
    'Pine',
    'Oak',
    'Plywood',
    'MDF',
    'Other'
  ];

  void _addComponent() {
    if (_formKey.currentState!.validate()) {
      final component = WoodComponent(
        woodType: selectedWoodType == 'Other' ? woodTypeController.text : selectedWoodType!,
        length: double.parse(lengthController.text),
        lengthUnit: lengthUnit,
        width: double.parse(widthController.text),
        widthUnit: widthUnit,
        thickness: double.parse(thicknessController.text),
        thicknessUnit: thicknessUnit,
        ratePerCft: double.parse(ratePerCftController.text),
        quantity: int.parse(quantityController.text),
      );

      widget.onAddComponent(component);
      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${component.woodType} component added! Wood type kept for next entry.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    lengthController.clear();
    widthController.clear();
    thicknessController.clear();
    ratePerCftController.clear();
    quantityController.clear();

    // Only clear custom wood type if "Other" is selected
    if (selectedWoodType == 'Other') {
      woodTypeController.clear();
    }

    setState(() {
      // Keep selectedWoodType - don't reset it
      lengthUnit = 'ft';
      widthUnit = 'inch';
      thicknessUnit = 'inch';
    });
  }

  // Public method to reset wood type when order is saved
  void resetWoodType() {
    setState(() {
      selectedWoodType = null;
      woodTypeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Wood Component',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (selectedWoodType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.brown[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.brown[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: Colors.brown[600]),
                          const SizedBox(width: 4),
                          Text(
                            selectedWoodType == 'Other'
                                ? (woodTypeController.text.isNotEmpty ? woodTypeController.text : 'Other')
                                : selectedWoodType!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.brown[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Wood Type Selection
              DropdownButtonFormField<String>(
                value: selectedWoodType,
                decoration: InputDecoration(
                  labelText: selectedWoodType != null ? 'Wood Type (Pinned)' : 'Wood Type',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    selectedWoodType != null ? Icons.push_pin : Icons.forest,
                    color: selectedWoodType != null ? Colors.brown[600] : null,
                  ),
                ),
                items: woodTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedWoodType = newValue;
                    if (newValue != 'Other') {
                      woodTypeController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a wood type';
                  }
                  return null;
                },
              ),

              if (selectedWoodType == 'Other') ...[
                SizedBox(height: isSmallScreen ? 8 : 12),
                TextFormField(
                  controller: woodTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Wood Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                    hintText: 'e.g., Bamboo, Mahogany, etc.',
                  ),
                  validator: (value) {
                    if (selectedWoodType == 'Other' && (value == null || value.trim().isEmpty)) {
                      return 'Please enter the wood type';
                    }
                    return null;
                  },
                ),
              ],

              SizedBox(height: isSmallScreen ? 12 : 16),

              Text(
                'Dimensions',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),

              // Responsive Dimensions Layout
              if (isSmallScreen) ...[
                // Mobile Layout - Stacked
                _buildDimensionField(
                  'Length',
                  lengthController,
                  lengthUnit,
                      (value) => setState(() => lengthUnit = value!),
                  isSmallScreen,
                ),
                const SizedBox(height: 12),
                _buildDimensionField(
                  'Width',
                  widthController,
                  widthUnit,
                      (value) => setState(() => widthUnit = value!),
                  isSmallScreen,
                ),
                const SizedBox(height: 12),
                _buildDimensionField(
                  'Thickness',
                  thicknessController,
                  thicknessUnit,
                      (value) => setState(() => thicknessUnit = value!),
                  isSmallScreen,
                ),
              ] else ...[
                // Desktop Layout - 3 columns
                Row(
                  children: [
                    Expanded(
                      child: _buildDimensionField(
                        'Length',
                        lengthController,
                        lengthUnit,
                            (value) => setState(() => lengthUnit = value!),
                        isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDimensionField(
                        'Width',
                        widthController,
                        widthUnit,
                            (value) => setState(() => widthUnit = value!),
                        isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDimensionField(
                        'Thickness',
                        thicknessController,
                        thicknessUnit,
                            (value) => setState(() => thicknessUnit = value!),
                        isSmallScreen,
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Rate and Quantity
              if (isSmallScreen) ...[
                TextFormField(
                  controller: ratePerCftController,
                  decoration: const InputDecoration(
                    labelText: 'Rate per CFT (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                    hintText: 'Rate per cubic feet',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter rate per CFT';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Rate must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                    hintText: 'Number of pieces',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (int.parse(value) <= 0) {
                      return 'Quantity must be greater than 0';
                    }
                    return null;
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: ratePerCftController,
                        decoration: const InputDecoration(
                          labelText: 'Rate per CFT (₹)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee),
                          hintText: 'Rate per cubic feet',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter rate per CFT';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Rate must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                          hintText: 'Number of pieces',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) <= 0) {
                            return 'Quantity must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _addComponent,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Component'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionField(
      String label,
      TextEditingController controller,
      String currentUnit,
      Function(String?) onUnitChanged,
      bool isSmallScreen,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: isSmallScreen,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Must > 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: currentUnit,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: isSmallScreen,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                ),
                items: ['ft', 'inch'].map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(
                      unit,
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  );
                }).toList(),
                onChanged: onUnitChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Unit';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    woodTypeController.dispose();
    lengthController.dispose();
    widthController.dispose();
    thicknessController.dispose();
    ratePerCftController.dispose();
    quantityController.dispose();
    super.dispose();
  }
}