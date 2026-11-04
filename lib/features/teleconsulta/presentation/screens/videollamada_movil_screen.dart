import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/datasources/teleconsulta_remote_datasource.dart';
import 'chat_teleconsulta_screen.dart';

class VideollamadaMovilScreen extends StatefulWidget {
  final int idCita;
  final String codigoFicha;
  final String medicoNombre;
  final String especialidad;
  final String clinicaNombre;
  final String pacienteNombre;
  final String medicoIniciales;
  final String pacienteInicial;

  const VideollamadaMovilScreen({
    super.key,
    this.idCita = 14,
    this.codigoFicha = 'FICHA CAR-014',
    this.medicoNombre = 'Dra. Lucía Rojas',
    this.especialidad = 'Cardiología',
    this.clinicaNombre = 'Clínica Norte',
    this.pacienteNombre = 'Ana Gutiérrez',
    this.medicoIniciales = 'LR',
    this.pacienteInicial = 'A',
  });

  @override
  State<VideollamadaMovilScreen> createState() => _VideollamadaMovilScreenState();
}

class _VideollamadaMovilScreenState extends State<VideollamadaMovilScreen> {
  // Estado de llamada y periféricos sincronizados con el Doctor (Web)
  bool _microfonoActivo = true;
  bool _camaraActiva = true;
  bool _camaraFrontal = true;
  bool _doctorConectado = false;
  bool _doctorCamaraActiva = true;
  bool _doctorMicrofonoActivo = true;
  bool _doctorCompartiendoPantalla = false;
  bool _cerrandoPorDoctor = false;
  Uint8List? _doctorFrameBytes;
  int _contadorMensajesNuevos = 2;
  int _ultimoTotalMensajes = 0;
  final Set<String> _senalesProcesadas = {};

  int _segundosTranscurridos = 0;
  Timer? _temporizadorLlamada;
  Timer? _temporizadorSincronizacion;

  @override
  void initState() {
    super.initState();
    _iniciarTemporizador();
    _iniciarSincronizacionTiempoReal();
  }

  @override
  void dispose() {
    _detenerTemporizador();
    _temporizadorSincronizacion?.cancel();
    TeleconsultaRemoteDataSource.reportarPresencia(
      idCita: widget.idCita,
      rol: 'PACIENTE',
      conectado: false,
      nombre: widget.pacienteNombre,
    );
    super.dispose();
  }

  void _iniciarTemporizador() {
    _temporizadorLlamada = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _segundosTranscurridos++;
        });
      }
    });
  }

  void _detenerTemporizador() {
    _temporizadorLlamada?.cancel();
    _temporizadorLlamada = null;
  }

  void _iniciarSincronizacionTiempoReal() {
    _sincronizarConDoctor();
    _temporizadorSincronizacion = Timer.periodic(const Duration(milliseconds: 650), (_) {
      _sincronizarConDoctor();
    });
  }

  void _cerrarPorFinalizacionDelDoctor() {
    if (_cerrandoPorDoctor || !mounted) return;
    _cerrandoPorDoctor = true;
    _detenerTemporizador();
    _temporizadorSincronizacion?.cancel();
    TeleconsultaRemoteDataSource.reportarPresencia(
      idCita: widget.idCita,
      rol: 'PACIENTE',
      conectado: false,
      nombre: widget.pacienteNombre,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El médico ha finalizado la teleconsulta. Redirigiendo a tus documentos...'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
    if (mounted) {
      Navigator.of(context).pushNamed('/documentos');
    }
  }

  Future<void> _sincronizarConDoctor() async {
    if (_cerrandoPorDoctor) return;

    // 1. Reportar presencia del paciente móvil y verificar estado de la sesión
    final presencia = await TeleconsultaRemoteDataSource.reportarPresencia(
      idCita: widget.idCita,
      rol: 'PACIENTE',
      conectado: true,
      nombre: widget.pacienteNombre,
    );

    if (mounted && presencia != null) {
      if (presencia['estado'] == 'FINALIZADA') {
        _cerrarPorFinalizacionDelDoctor();
        return;
      }
      final docOnline = presencia['doctor_conectado'] == true;
      if (docOnline != _doctorConectado) {
        setState(() {
          _doctorConectado = docOnline;
        });
      }
    }

    // 2. Consultar señales de audio, video en vivo, pantalla y cierre del doctor
    final senales = await TeleconsultaRemoteDataSource.obtenerSenalesWebrtc(
      idCita: widget.idCita,
      para: 'PACIENTE',
    );
    if (mounted && senales.isNotEmpty) {
      for (final s in senales) {
        final sid = (s['id'] ?? '').toString();
        if (sid.isEmpty || _senalesProcesadas.contains(sid)) continue;
        _senalesProcesadas.add(sid);

        final tipo = (s['tipo'] ?? '').toString().toUpperCase();
        final data = s['data'];

        if (tipo == 'FINALIZAR_CONSULTA') {
          _cerrarPorFinalizacionDelDoctor();
          return;
        }

        if (tipo == 'VIDEO_FRAME' && data is Map && data['frame'] is String) {
          final frameStr = data['frame'] as String;
          final commaIdx = frameStr.indexOf(',');
          final b64 = commaIdx >= 0 ? frameStr.substring(commaIdx + 1) : frameStr;
          try {
            final bytes = base64Decode(b64);
            if (bytes.isNotEmpty && mounted) {
              setState(() {
                _doctorFrameBytes = bytes;
                _doctorConectado = true;
                _doctorCamaraActiva = true;
              });
            }
          } catch (_) {}
          continue;
        }

        setState(() {
          if (tipo == 'OFFER') {
            _doctorConectado = true;
          } else if (tipo == 'CAMARA_ESTADO' && data is Map) {
            _doctorCamaraActiva = data['activa'] == true;
            if (!_doctorCamaraActiva) {
              _doctorFrameBytes = null;
            }
          } else if (tipo == 'MICROFONO_ESTADO' && data is Map) {
            _doctorMicrofonoActivo = data['activo'] == true;
          } else if (tipo == 'PANTALLA_COMPARTIDA') {
            _doctorCompartiendoPantalla = true;
            _doctorConectado = true;
          } else if (tipo == 'DETENER_PANTALLA') {
            _doctorCompartiendoPantalla = false;
          }
        });
      }
    }

    // 3. Sincronizar contador de mensajes nuevos enviados por el doctor
    final mensajes = await TeleconsultaRemoteDataSource.obtenerMensajesRealtime(widget.idCita);
    if (mounted && mensajes.isNotEmpty) {
      final totalDoc = mensajes.where((m) => m['esDoctor'] == true).length;
      if (_ultimoTotalMensajes > 0 && totalDoc > _ultimoTotalMensajes) {
        setState(() {
          _contadorMensajesNuevos += (totalDoc - _ultimoTotalMensajes);
        });
      }
      _ultimoTotalMensajes = totalDoc;
    }
  }

  String _formatearTiempo(int totalSegundos) {
    final minutos = totalSegundos ~/ 60;
    final segundos = totalSegundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  void _alternarMicrofono() {
    setState(() {
      _microfonoActivo = !_microfonoActivo;
    });
    TeleconsultaRemoteDataSource.enviarSenalWebrtc(
      idCita: widget.idCita,
      de: 'PACIENTE',
      para: 'DOCTOR',
      tipo: 'MICROFONO_ESTADO',
      data: {'activo': _microfonoActivo},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_microfonoActivo ? 'Micrófono activado' : 'Micrófono silenciado'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _alternarCamara() {
    setState(() {
      _camaraActiva = !_camaraActiva;
    });
    TeleconsultaRemoteDataSource.enviarSenalWebrtc(
      idCita: widget.idCita,
      de: 'PACIENTE',
      para: 'DOCTOR',
      tipo: 'CAMARA_ESTADO',
      data: {'activa': _camaraActiva},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_camaraActiva ? 'Cámara activada' : 'Cámara desactivada'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cambiarCamara() {
    setState(() {
      _camaraFrontal = !_camaraFrontal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_camaraFrontal ? 'Cámara frontal seleccionada' : 'Cámara trasera seleccionada'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _abrirChatModal() {
    setState(() {
      _contadorMensajesNuevos = 0;
    });

    ChatTeleconsultaScreen.showAsModal(
      context,
      idCita: widget.idCita,
      medicoNombre: widget.medicoNombre,
      especialidadNombre: widget.especialidad,
      clinicaNombre: widget.clinicaNombre,
    );
  }

  Future<void> _colgarYLlamar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Finalizar videollamada?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Deseas salir de la sesión médica actual? Podrás consultar tus documentos, exámenes y recetas generadas.',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar en llamada', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir de la sala', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      _detenerTemporizador();
      _temporizadorSincronizacion?.cancel();
      await TeleconsultaRemoteDataSource.reportarPresencia(
        idCita: widget.idCita,
        rol: 'PACIENTE',
        conectado: false,
        nombre: widget.pacienteNombre,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (mounted) {
        Navigator.of(context).pushNamed('/documentos');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mostrarVideoEnVivo = _doctorFrameBytes != null && (_doctorCamaraActiva || _doctorCompartiendoPantalla);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1528),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. VISTA PRINCIPAL DEL DOCTOR (VIDEO EN VIVO O AVATAR SI LA CÁMARA ESTÁ APAGADA)
            if (mostrarVideoEnVivo)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Image.memory(
                    _doctorFrameBytes!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _doctorConectado
                              ? const Color(0xFF10B981).withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.15),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_doctorConectado ? const Color(0xFF10B981) : const Color(0xFF1E3A5F))
                                .withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.medicoIniciales,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.medicoNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.especialidad,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_doctorConectado) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _doctorCompartiendoPantalla
                                  ? Icons.screen_share_rounded
                                  : (_doctorMicrofonoActivo ? Icons.graphic_eq_rounded : Icons.mic_off_rounded),
                              color: const Color(0xFF34D399),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _doctorCompartiendoPantalla
                                  ? 'Médico compartiendo pantalla'
                                  : (_doctorCamaraActiva
                                      ? 'En línea · Audio y Video activos'
                                      : 'En línea · Solo Audio'),
                              style: const TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // 2. INDICADORES SUPERIORES (DURACIÓN, HD, CIFRADO)
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatearTiempo(_segundosTranscurridos),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_rounded, color: Color(0xFF10B981), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'HD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: Color(0xFF60A5FA), size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Cifrado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. PICTURE IN PICTURE: TÚ (PACIENTE) - ESQUINA SUPERIOR DERECHA
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 90,
                height: 125,
                decoration: BoxDecoration(
                  color: const Color(0xFF24334A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _camaraActiva
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.pacienteInicial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tú',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Cámara off',
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
              ),
            ),

            // 4. BARRA DE CONTROLES INFERIOR FLOTANTE
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _construirBotonControl(
                    icono: _microfonoActivo ? Icons.mic_rounded : Icons.mic_off_rounded,
                    colorFondo: _microfonoActivo ? const Color(0xFF1E293B) : const Color(0xFFEF4444),
                    onTap: _alternarMicrofono,
                  ),
                  _construirBotonControl(
                    icono: _camaraActiva ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    colorFondo: _camaraActiva ? const Color(0xFF1E293B) : const Color(0xFFEF4444),
                    onTap: _alternarCamara,
                  ),
                  _construirBotonControl(
                    icono: Icons.cameraswitch_outlined,
                    colorFondo: const Color(0xFF1E293B),
                    onTap: _cambiarCamara,
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _construirBotonControl(
                        icono: Icons.chat_bubble_outline_rounded,
                        colorFondo: const Color(0xFF1E293B),
                        onTap: _abrirChatModal,
                      ),
                      if (_contadorMensajesNuevos > 0)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$_contadorMensajesNuevos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  _construirBotonControl(
                    icono: Icons.call_end_rounded,
                    colorFondo: const Color(0xFFDC2626),
                    onTap: _colgarYLlamar,
                    esBotonPeligro: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotonControl({
    required IconData icono,
    required Color colorFondo,
    required VoidCallback onTap,
    bool esBotonPeligro = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: colorFondo,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: esBotonPeligro ? 0.3 : 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            icono,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
