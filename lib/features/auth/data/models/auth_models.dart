class LoginRequest {
  final String correo;
  final String password;

  LoginRequest({
    required this.correo,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'correo': correo.trim(),
    'password': password,
  };
}

class RegisterRequest {
  final String nombres;
  final String apellidos;
  final String correo;
  final String password;
  final String? telefono;

  RegisterRequest({
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.password,
    this.telefono,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      'correo': correo.trim(),
      'password': password,
    };
    if (telefono != null && telefono!.trim().isNotEmpty) {
      map['telefono'] = telefono!.trim();
    }
    return map;
  }
}

class TokenResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;

  TokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'],
      tokenType: json['token_type'] ?? 'bearer',
    );
  }
}

class UserModel {
  final int idUsuario;
  final String nombres;
  final String apellidos;
  final String correo;
  final String? telefono;
  final int? idRol;
  final String? rolNombre;
  final dynamic estado;

  UserModel({
    required this.idUsuario,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    this.telefono,
    this.idRol,
    this.rolNombre,
    this.estado,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUsuario: json['id_usuario'] is int
          ? json['id_usuario']
          : int.tryParse(json['id_usuario']?.toString() ?? '0') ?? 0,
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      correo: json['correo'] ?? '',
      telefono: json['telefono'],
      idRol: json['id_rol'] is int
          ? json['id_rol']
          : int.tryParse(json['id_rol']?.toString() ?? ''),
      rolNombre: json['rol_nombre'] ?? json['rol']?['nombre'],
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'nombres': nombres,
    'apellidos': apellidos,
    'correo': correo,
    'telefono': telefono,
    'id_rol': idRol,
    'rol_nombre': rolNombre,
    'estado': estado,
  };
}

class ForgotPasswordRequest {
  final String correo;

  ForgotPasswordRequest({required this.correo});

  Map<String, dynamic> toJson() => {
    'correo': correo.trim(),
  };
}

class ResetPasswordRequest {
  final String correo;
  final String codigo;
  final String nuevaPassword;

  ResetPasswordRequest({
    required this.correo,
    required this.codigo,
    required this.nuevaPassword,
  });

  Map<String, dynamic> toJson() => {
    'correo': correo.trim(),
    'codigo': codigo,
    'nueva_password': nuevaPassword,
  };
}

class ForgotPasswordResponse {
  final String detail;
  final String? debugCode;

  ForgotPasswordResponse({
    required this.detail,
    this.debugCode,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      detail: json['detail'] ?? '',
      debugCode: json['debug_code'] ?? json['debugCode'],
    );
  }
}
