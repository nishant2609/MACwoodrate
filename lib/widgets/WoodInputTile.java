import 'package:flutter/material.dart';
import '../models/wood_component.dart';

class WoodInputTile extends StatefulWidget {
  final Function(WoodComponent) onAddComponent;

  const WoodInputTile({
    super.key,
    required this.onAddComponent,
  });

  @override
  State<WoodInputTile> createState() => _WoodInputTileState();
}

class _WoodInputTileState extends State<WoodInputTile> {
  final TextEditingController woodTypeController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController thicknessController = TextEditingController();
  final TextEditingController unitCostController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Common wood types for dropdown
  final List<String> woodTypes = [
    'Sheesham',
    'Teak',
    'Oak',
    'Pine',
    'Mango',
    'Sal',
    'Bamboo',
    'Plywood',
    'MDF',
    'Other'
  ];

  String? selectedWoodType;
  String lengthUnit = 'ft';
  String widthUnit = 'ft';
  String thicknessUnit = 'inch';

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
        unitCost: double.parse(unitCostController.text),
        quantity: int.parse(quantityController.text),
      );

      widget.onAddComponent(component);

      // Clear the form
      _clearForm();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wood component added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearForm() {
    woodTypeController.clear();
    lengthController.clear();
    widthController.clear();
    thicknessController.clear();
    unitCostController.clear();
    quantityController.clear();
    setState(() {
      selectedWoodType = null;
      lengthUnit = 'ft';
      widthUnit = 'ft';
      thicknessUnit = 'inch';
    });
  }

  Widget _buildDimensionField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required Function(String) onUnitChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) <= 0) {
                return '$label must be greater than 0';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: unit,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            ),
            items: const [
              DropdownMenuItem(value: 'ft', child: Text('ft')),
              DropdownMenuItem(value: 'inch', child: Text('inch')),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                onUnitChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Wood Component',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Wood Type Dropdown
              DropdownButtonFormField<String>(
                value: selectedWoodType,
                decoration: const InputDecoration(
                  labelText: 'Wood Type',
                  border: OutlineInputBorder(),
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
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a wood type';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Custom Wood Type field (shown only when "Other" is selected)
              if (selectedWoodType == 'Other')
                Column(
                  children: [
                    TextFormField(
                      controller: woodTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Wood Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (selectedWoodType == 'Other' && (value == null || value.isEmpty)) {
                          return 'Please enter wood type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Dimensions Section
              const Text(
                'Dimensions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 12),

              // Length Input
              _buildDimensionField(
                label: 'Length',
                controller: lengthController,
                unit: lengthUnit,
                onUnitChanged: (String newUnit) {
                  setState(() {
                    lengthUnit = newUnit;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Width Input
              _buildDimensionField(
                label: 'Width',
                controller: widthController,
                unit: widthUnit,
                onUnitChanged: (String newUnit) {
                  setState(() {
                    widthUnit = newUnit;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Thickness Input
              _buildDimensionField(
                label: 'Thickness',
                controller: thicknessController,
                unit: thicknessUnit,
                onUnitChanged: (String newUnit) {
                  setState(() {
                    thicknessUnit = newUnit;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Unit Cost Input
              TextFormField(
                controller: unitCostController,
                decoration: const InputDecoration(
                  labelText: 'Unit Cost (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Unit cost must be greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Quantity Input
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
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

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addComponent,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Component'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    woodTypeController.dispose();
    lengthController.dispose();
    widthController.dispose();
    thicknessController.dispose();
    unitCostController.dispose();
    quantityController.dispose();
    super.dispose();
  }
}