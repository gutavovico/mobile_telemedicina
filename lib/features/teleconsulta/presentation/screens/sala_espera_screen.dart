import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasources/teleconsulta_remote_datasource.dart';
import 'videollamada_movil_screen.dart';

String _extraerIniciales(String nombre) {
  if (nombre.isEmpty) return 'DR';
  final limpio = nombre.replaceAll(RegExp(r'^(Dr\(a\)\.?|Dr\.|Dra\.)\s*', caseSensitive: false), '').trim();
  final partes = limpio.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.length >= 2) {
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }
  return partes.isNotEmpty && partes[0].length >= 2
      ? partes[0].substring(0, 2).toUpperCase()
      : (partes.isNotEmpty ? partes[0][0].toUpperCase() : 'DR');
}

class SalaEsperaScreen extends StatefulWidget {
  final int idCita;
  final String codigoFicha;
  final String medicoNombre;
  final String especialidad;
  final String clinicaNombre;
  final String clinicaIniciales;
  final String horaTeleconsulta;
  final int posicionEnFila;
  final int pacientesAntes;
  final int tiempoEstimadoMinutos;
  final String pacienteNombre;

  const SalaEsperaScreen({
    super.key,
    this.idCita = 14,
    this.codigoFicha = 'FICHA CAR-014',
    this.medicoNombre = 'Dra. Lucía Rojas',
    this.especialidad = 'Cardiología · Teleconsulta',
    this.clinicaNombre = 'Clinica Norte',
    this.clinicaIniciales = 'CN',
    this.horaTeleconsulta = '10:30',
    this.posicionEnFila = 2,
    this.pacientesAntes = 1,
    this.tiempoEstimadoMinutos = 8,
    this.pacienteNombre = 'Ana Gutiérrez',
  });

  @override
  State<SalaEsperaScreen> createState() => _SalaEsperaScreenState();
}

class _SalaEsperaScreenState extends State<SalaEsperaScreen> {
  // Verificación de periféricos y presencia del doctor en tiempo real
  final bool _camaraLista = true;
  final bool _microfonoListo = true;
  final bool _conexionBuena = true;
  bool _doctorConectado = false;
  Timer? _presenciaTimer;

  @override
  void initState() {
    super.initState();
    _sincronizarPresencia();
    _presenciaTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _sincronizarPresencia();
    });
  }

  @override
  void dispose() {
    _presenciaTimer?.cancel();
    super.dispose();
  }

  Future<void> _sincronizarPresencia() async {
    final res = await TeleconsultaRemoteDataSource.reportarPresencia(
      idCita: widget.idCita,
      rol: 'PACIENTE',
      conectado: true,
      nombre: widget.pacienteNombre,
    );
    if (mounted && res != null) {
      final docCon = res['doctor_conectado'] == true;
      if (docCon != _doctorConectado) {
        setState(() {
          _doctorConectado = docCon;
        });
      }
    }
  }

  void _entrarAVideollamada() {
    final espLimpia = widget.especialidad.replaceAll('· Teleconsulta', '').replaceAll('· Control', '').trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideollamadaMovilScreen(
          idCita: widget.idCita,
          codigoFicha: widget.codigoFicha,
          medicoNombre: widget.medicoNombre,
          especialidad: espLimpia.isNotEmpty ? espLimpia : 'Medicina General',
          clinicaNombre: widget.clinicaNombre,
          pacienteNombre: widget.pacienteNombre,
          medicoIniciales: _extraerIniciales(widget.medicoNombre),
          pacienteInicial: widget.pacienteNombre.isNotEmpty
              ? widget.pacienteNombre.substring(0, 1).toUpperCase()
              : 'A',
        ),
      ),
    );
  }

  void _abrirDocumentos() {
    Navigator.of(context).pushNamed('/documentos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sala de espera',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Teleconsulta · ${widget.horaTeleconsulta}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. TARJETA PRINCIPAL: DOCTOR Y POSICIÓN EN FILA
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ficha y Badge de estado en tiempo real
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.codigoFicha,
                        style: const TextStyle(
                          color: Color(0xFF006B5F),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCEEAD6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF137333),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _doctorConectado ? 'Médico en sala' : 'Eres el siguiente',
                              style: const TextStyle(
                                color: Color(0xFF137333),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Nombre del Doctor Dinámico
                  Text(
                    widget.medicoNombre,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Especialidad Dinámica
                  Text(
                    widget.especialidad,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tag de Institución / Clínica Dinámica
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8E6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC5221F),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.clinicaIniciales,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.clinicaNombre,
                          style: const TextStyle(
                            color: Color(0xFFC5221F),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2 Cajas de Métricas Dinámicas: Posición y Tiempo Estimado
                  Row(
                    children: [
                      // Caja 1: Tu Posición
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TU POSICIÓN',
                                style: TextStyle(
                                  color: Color(0xFF174EA6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _doctorConectado ? '1°' : '${widget.posicionEnFila}°',
                                style: const TextStyle(
                                  color: Color(0xFF174EA6),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _doctorConectado ? 'Turno activo' : '${widget.pacientesAntes} paciente antes',
                                style: const TextStyle(
                                  color: Color(0xFF5F6368),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Caja 2: Tiempo Estimado
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIEMPO ESTIMADO',
                                style: TextStyle(
                                  color: Color(0xFF0D652D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _doctorConectado ? 'Ahora' : '${widget.tiempoEstimadoMinutos} min',
                                style: const TextStyle(
                                  color: Color(0xFF0D652D),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Se actualiza en tiempo real',
                                style: TextStyle(
                                  color: Color(0xFF5F6368),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Indicador de Progreso en 4 Pasos (Check-in, En fila, Tu turno, En consulta)
                  Column(
                    children: [
                      Row(
                        children: [
                          _construirBarraProgreso(color: const Color(0xFF006B5F)),
                          const SizedBox(width: 6),
                          _construirBarraProgreso(color: const Color(0xFF006B5F)),
                          const SizedBox(width: 6),
                          _construirBarraProgreso(color: const Color(0xFF006B5F)),
                          const SizedBox(width: 6),
                          _construirBarraProgreso(
                            color: _doctorConectado ? const Color(0xFF006B5F) : const Color(0xFFE2E8F0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Check-in', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('En fila', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('Tu turno', style: TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w800)),
                          Text('En consulta', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // 2. TARJETA: REVISA TU EQUIPO
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revisa tu equipo',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cámara frontal
                  _construirFilaVerificacion(
                    icono: Icons.videocam_outlined,
                    titulo: 'Cámara frontal',
                    ok: _camaraLista,
                    textoActivo: '✓ Lista',
                    textoInactivo: '✗ Desconectada',
                  ),
                  const Divider(height: 22, color: Color(0xFFF1F5F9)),

                  // Micrófono
                  _construirFilaVerificacion(
                    icono: Icons.mic_none_outlined,
                    titulo: 'Micrófono',
                    ok: _microfonoListo,
                    textoActivo: '✓ Listo',
                    textoInactivo: '✗ Silenciado',
                  ),
                  const Divider(height: 22, color: Color(0xFFF1F5F9)),

                  // Conexión
                  _construirFilaVerificacion(
                    icono: Icons.wifi_rounded,
                    titulo: 'Conexión',
                    ok: _conexionBuena,
                    textoActivo: '✓ Buena',
                    textoInactivo: '✗ Débil',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ==========================================
            // 3. BANNER: ¿TIENES EXÁMENES RECIENTES?
            // ==========================================
            InkWell(
              onTap: _abrirDocumentos,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD2E3FC), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.attach_file_rounded,
                        color: Color(0xFF1A73E8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Tienes exámenes recientes?',
                            style: TextStyle(
                              color: Color(0xFF174EA6),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Compártelos con tu médico antes de entrar.',
                            style: TextStyle(
                              color: Color(0xFF3C4043),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ==========================================
            // 4. BOTÓN PRINCIPAL: ENTRAR A LA VIDEOLLAMADA
            // ==========================================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _entrarAVideollamada,
                icon: const Icon(Icons.videocam_rounded, size: 22, color: Colors.white),
                label: const Text(
                  'Entrar a la videollamada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2948),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _construirBarraProgreso({required Color color}) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _construirFilaVerificacion({
    required IconData icono,
    required String titulo,
    required bool ok,
    required String textoActivo,
    required String textoInactivo,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: const Color(0xFF475569)),
            const SizedBox(width: 10),
            Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ok ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            ok ? textoActivo : textoInactivo,
            style: TextStyle(
              color: ok ? const Color(0xFF137333) : const Color(0xFFC5221F),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
