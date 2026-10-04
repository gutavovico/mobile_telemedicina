class UserEntity {
  final int idUsuario;
  final String nombres;
  final String apellidos;
  final String correo;
  final String? telefono;
  final int? idRol;
  final String? rolNombre;
  final String? estado;

  const UserEntity({
    required this.idUsuario,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    this.telefono,
    this.idRol,
    this.rolNombre,
    this.estado,
  });
}
