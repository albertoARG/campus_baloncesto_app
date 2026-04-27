class StationDayModel {
  final String id;
  final String nombre;
  final DateTime? fecha;
  final bool isPublished;
  final DateTime createdAt;

  StationDayModel({
    required this.id,
    required this.nombre,
    this.fecha,
    this.isPublished = false,
    required this.createdAt,
  });

  factory StationDayModel.fromJson(Map<String, dynamic> json) {
    return StationDayModel(
      id: json['id'],
      nombre: json['nombre'],
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
      isPublished: json['is_published'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      if (fecha != null) 'fecha': fecha!.toIso8601String(),
      'is_published': isPublished,
    };
  }
}
