class PatientModel {
  final int idPaciente;
  final int? idUsuario;
  final String nombres;
  final String apellidos;
  final String ci;
  final String? complemento;
  final String fechaNacimiento;
  final String genero;
  final String telefono;
  final String? correo;
  final String? direccion;
  final String? ciudad;
  final String? tipoSangre;
  final String? alergias;
  final String? antecedentesPatologicos;
  final String? contactoEmergenciaNombre;
  final String? contactoEmergenciaTelefono;
  final String? contactoEmergenciaParentesco;
  final String? seguroMedico;
  final String? numeroSeguro;
  final String estado;
  final String? createdAt;
  final String? updatedAt;

  PatientModel({
    required this.idPaciente,
    this.idUsuario,
    required this.nombres,
    required this.apellidos,
    required this.ci,
    this.complemento,
    required this.fechaNacimiento,
    required this.genero,
    required this.telefono,
    this.correo,
    this.direccion,
    this.ciudad,
    this.tipoSangre,
    this.alergias,
    this.antecedentesPatologicos,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaTelefono,
    this.contactoEmergenciaParentesco,
    this.seguroMedico,
    this.numeroSeguro,
    required this.estado,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$nombres $apellidos';

  int get age {
    try {
      final birth = DateTime.parse(fechaNacimiento);
      final today = DateTime.now();
      int calculatedAge = today.year - birth.year;
      if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
        calculatedAge--;
      }
      return calculatedAge > 0 ? calculatedAge : 0;
    } catch (_) {
      return 0;
    }
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      idPaciente: json['id_paciente'] as int,
      idUsuario: json['id_usuario'] as int?,
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      ci: json['ci'] as String? ?? '',
      complemento: json['complemento'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] as String? ?? '',
      genero: json['genero'] as String? ?? 'M',
      telefono: json['telefono'] as String? ?? '',
      correo: json['correo'] as String?,
      direccion: json['direccion'] as String?,
      ciudad: json['ciudad'] as String? ?? 'Santa Cruz de la Sierra',
      tipoSangre: json['tipo_sangre'] as String?,
      alergias: json['alergias'] as String?,
      antecedentesPatologicos: json['antecedentes_patologicos'] as String?,
      contactoEmergenciaNombre: json['contacto_emergencia_nombre'] as String?,
      contactoEmergenciaTelefono: json['contacto_emergencia_telefono'] as String?,
      contactoEmergenciaParentesco: json['contacto_emergencia_parentesco'] as String?,
      seguroMedico: json['seguro_medico'] as String?,
      numeroSeguro: json['numero_seguro'] as String?,
      estado: json['estado'] as String? ?? 'ACTIVO',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_paciente': idPaciente,
      'id_usuario': idUsuario,
      'nombres': nombres,
      'apellidos': apellidos,
      'ci': ci,
      'complemento': complemento,
      'fecha_nacimiento': fechaNacimiento,
      'genero': genero,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'ciudad': ciudad,
      'tipo_sangre': tipoSangre,
      'alergias': alergias,
      'antecedentes_patologicos': antecedentesPatologicos,
      'contacto_emergencia_nombre': contactoEmergenciaNombre,
      'contacto_emergencia_telefono': contactoEmergenciaTelefono,
      'contacto_emergencia_parentesco': contactoEmergenciaParentesco,
      'seguro_medico': seguroMedico,
      'numero_seguro': numeroSeguro,
      'estado': estado,
    };
  }

  PatientModel copyWith({
    String? telefono,
    String? correo,
    String? direccion,
    String? ciudad,
    String? contactoEmergenciaNombre,
    String? contactoEmergenciaTelefono,
    String? contactoEmergenciaParentesco,
  }) {
    return PatientModel(
      idPaciente: idPaciente,
      idUsuario: idUsuario,
      nombres: nombres,
      apellidos: apellidos,
      ci: ci,
      complemento: complemento,
      fechaNacimiento: fechaNacimiento,
      genero: genero,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      tipoSangre: tipoSangre,
      alergias: alergias,
      antecedentesPatologicos: antecedentesPatologicos,
      contactoEmergenciaNombre: contactoEmergenciaNombre ?? this.contactoEmergenciaNombre,
      contactoEmergenciaTelefono: contactoEmergenciaTelefono ?? this.contactoEmergenciaTelefono,
      contactoEmergenciaParentesco: contactoEmergenciaParentesco ?? this.contactoEmergenciaParentesco,
      seguroMedico: seguroMedico,
      numeroSeguro: numeroSeguro,
      estado: estado,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
