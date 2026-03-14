class Company {
  final String id;
  final String companyName;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String? gstin;
  final String? website;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.companyName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    this.gstin,
    this.website,
    required this.createdAt,
  });

  Company copyWith({
    String? id,
    String? companyName,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? gstin,
    String? website,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'ownerName': ownerName,
    'email': email,
    'phone': phone,
    'address': address,
    'gstin': gstin,
    'website': website,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      companyName: json['companyName'],
      ownerName: json['ownerName'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      gstin: json['gstin'],
      website: json['website'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}