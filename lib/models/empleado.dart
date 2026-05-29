class Empleado {
  final String id;
  final String? profileId;
  String firstName;
  String lastName;
  String position;
  String? hireDate;
  double? salary;
  bool active;
  String? notes;

  Empleado({
    required this.id,
    this.profileId,
    required this.firstName,
    required this.lastName,
    required this.position,
    this.hireDate,
    this.salary,
    this.active = true,
    this.notes,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: (json['id'] ?? '').toString(),
      profileId: json['profile_id']?.toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      position: json['position'] ?? 'Mesero',
      hireDate: json['hire_date']?.toString(),
      salary: (json['salary'] as num?)?.toDouble(),
      active: json['active'] as bool? ?? true,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'profile_id': profileId,
      'first_name': firstName,
      'last_name': lastName,
      'position': position,
      'hire_date': hireDate,
      'salary': salary,
      'active': active,
      'notes': notes,
    };
  }

  Empleado copyWith({
    String? id,
    String? profileId,
    String? firstName,
    String? lastName,
    String? position,
    String? hireDate,
    double? salary,
    bool? active,
    String? notes,
  }) {
    return Empleado(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      position: position ?? this.position,
      hireDate: hireDate ?? this.hireDate,
      salary: salary ?? this.salary,
      active: active ?? this.active,
      notes: notes ?? this.notes,
    );
  }
}