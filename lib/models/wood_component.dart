class WoodComponent {
  String woodType;
  double length;
  String lengthUnit; // 'ft' or 'inch'
  double width;
  String widthUnit; // 'ft' or 'inch'
  double thickness;
  String thicknessUnit; // 'ft' or 'inch'
  double ratePerCft; // Changed from unitCost to ratePerCft
  int quantity;

  WoodComponent({
    required this.woodType,
    required this.length,
    required this.lengthUnit,
    required this.width,
    required this.widthUnit,
    required this.thickness,
    required this.thicknessUnit,
    required this.ratePerCft, // Rate per CFT instead of unit cost
    required this.quantity,
  });

  // Calculate total cost: CFT * rate per CFT
  double get totalCost => cft * ratePerCft;

  // Get formatted size string
  String get formattedSize {
    return '${length}${lengthUnit} × ${width}${widthUnit} × ${thickness}${thicknessUnit}';
  }

  // Calculate CFT using the formula: (length (ft) x width (inch) x thickness (inch) / 144) * quantity
  double get cft {
    // Convert length to feet if it's in inches
    double lengthInFeet = lengthUnit == 'ft' ? length : length / 12;

    // Convert width to inches if it's in feet
    double widthInInches = widthUnit == 'inch' ? width : width * 12;

    // Convert thickness to inches if it's in feet
    double thicknessInInches = thicknessUnit == 'inch' ? thickness : thickness * 12;

    // CFT formula: (length in ft × width in inches × thickness in inches) / 144 × quantity
    double cftPerPiece = (lengthInFeet * widthInInches * thicknessInInches) / 144;
    return cftPerPiece * quantity;
  }

  // Get volume in cubic feet (for calculations if needed)
  double get volumeInCubicFeet {
    double lengthInFeet = lengthUnit == 'ft' ? length : length / 12;
    double widthInFeet = widthUnit == 'ft' ? width : width / 12;
    double thicknessInFeet = thicknessUnit == 'ft' ? thickness : thickness / 12;
    return lengthInFeet * widthInFeet * thicknessInFeet;
  }

  Map<String, dynamic> toJson() => {
    'woodType': woodType,
    'length': length,
    'lengthUnit': lengthUnit,
    'width': width,
    'widthUnit': widthUnit,
    'thickness': thickness,
    'thicknessUnit': thicknessUnit,
    'ratePerCft': ratePerCft, // Updated field name
    'quantity': quantity,
  };

  factory WoodComponent.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility for old unitCost field
    double rate = 0.0;
    if (json.containsKey('ratePerCft')) {
      rate = (json['ratePerCft'] as num).toDouble();
    } else if (json.containsKey('unitCost')) {
      // For backward compatibility, treat old unitCost as ratePerCft
      rate = (json['unitCost'] as num).toDouble();
    }

    // Handle backward compatibility for old size field
    if (json.containsKey('size') && !json.containsKey('length')) {
      // Parse old format (assuming it was in format like "3.5x1")
      String size = json['size'] ?? '1x1';
      List<String> dimensions = size.split('x');
      double length = dimensions.isNotEmpty ? double.tryParse(dimensions[0]) ?? 1.0 : 1.0;
      double width = dimensions.length > 1 ? double.tryParse(dimensions[1]) ?? 1.0 : 1.0;

      return WoodComponent(
        woodType: json['woodType'],
        length: length,
        lengthUnit: 'ft',
        width: width,
        widthUnit: 'ft',
        thickness: 1.0,
        thicknessUnit: 'inch',
        ratePerCft: rate,
        quantity: json['quantity'] as int,
      );
    }

    return WoodComponent(
      woodType: json['woodType'],
      length: (json['length'] as num).toDouble(),
      lengthUnit: json['lengthUnit'],
      width: (json['width'] as num).toDouble(),
      widthUnit: json['widthUnit'],
      thickness: (json['thickness'] as num).toDouble(),
      thicknessUnit: json['thicknessUnit'],
      ratePerCft: rate,
      quantity: json['quantity'] as int,
    );
  }
}