class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? companyId;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.companyId,
    required this.createdAt,
  });

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? companyId,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'companyId': companyId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      companyId: json['companyId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}