import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/chat_message_model.dart';
import '../providers/teleconsulta_provider.dart';

class ChatTeleconsultaScreen extends StatefulWidget {
  final int idCita;
  final String? medicoNombre;
  final String? especialidadNombre;
  final String? fechaCita;
  final String? horaCita;
  final String? clinicaNombre;
  final bool isModal;

  const ChatTeleconsultaScreen({
    super.key,
    required this.idCita,
    this.medicoNombre,
    this.especialidadNombre,
    this.fechaCita,
    this.horaCita,
    this.clinicaNombre,
    this.isModal = false,
  });

  static Future<void> showAsModal(
    BuildContext context, {
    required int idCita,
    String? medicoNombre,
    String? especialidadNombre,
    String? fechaCita,
    String? horaCita,
    String? clinicaNombre,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ChatTeleconsultaScreen(
          idCita: idCita,
          medicoNombre: medicoNombre,
          especialidadNombre: especialidadNombre,
          fechaCita: fechaCita,
          horaCita: horaCita,
          clinicaNombre: clinicaNombre,
          isModal: true,
        ),
      ),
    );
  }

  @override
  State<ChatTeleconsultaScreen> createState() => _ChatTeleconsultaScreenState();
}

class _ChatTeleconsultaScreenState extends State<ChatTeleconsultaScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TeleconsultaProvider>(context, listen: false);
      provider.cargarTeleconsulta(widget.idCita);
      provider.iniciarPolling(widget.idCita);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    // Detener polling al salir de la pantalla
    final provider = Provider.of<TeleconsultaProvider>(context, listen: false);
    provider.detenerPolling();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _limpiarTituloMedico(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return 'Dr. Especialista';
    var limpio = nombre.trim();
    limpio = limpio.replaceAll(RegExp(r'^(Dr\(a\)\.?\s*)+', caseSensitive: false), '');
    limpio = limpio.replaceAll(RegExp(r'^(Dr\.?\s*)+', caseSensitive: false), '');
    limpio = limpio.replaceAll(RegExp(r'^(Dra\.?\s*)+', caseSensitive: false), '');
    return 'Dr. $limpio';
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final provider = Provider.of<TeleconsultaProvider>(context, listen: false);

    _scrollToBottom();
    final ok = await provider.enviarMensaje(
      idCita: widget.idCita,
      contenido: text,
    );

    if (ok) {
      _scrollToBottom();
    }
  }

  void _mostrarSelectorAdjuntos() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adjuntar archivo a la consulta',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                ),
                title: const Text('Estudio / Laboratorio (PDF)'),
                subtitle: const Text('Resultados_Analisis_Clinico.pdf (1.2 MB)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _adjuntarArchivoSimulado(
                    nombre: 'Resultados_Laboratorio_SJD.pdf',
                    tamano: '1.2 MB',
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.successContainer,
                  child: Icon(Icons.image_outlined, color: AppColors.success),
                ),
                title: const Text('Fotografía / Imagen Médica'),
                subtitle: const Text('Foto_Sintoma_01.jpg (850 KB)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _adjuntarArchivoSimulado(
                    nombre: 'Foto_Examen_Fisico.jpg',
                    tamano: '850 KB',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _adjuntarArchivoSimulado({
    required String nombre,
    required String tamano,
  }) async {
    final provider = Provider.of<TeleconsultaProvider>(context, listen: false);
    await provider.enviarMensaje(
      idCita: widget.idCita,
      contenido: 'Adjunto documento para revisión en consulta: $nombre',
      adjuntoNombre: nombre,
      adjuntoTamano: tamano,
      adjuntoUrl: 'https://backend-telemedicina.onrender.com/media/$nombre',
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final teleconsultaProvider = Provider.of<TeleconsultaProvider>(context);
    final vm = teleconsultaProvider.teleconsulta;

    final nombreMedicoReal = _limpiarTituloMedico(
      vm?.medico?.nombreCompleto ?? widget.medicoNombre,
    );
    final especialidadReal = vm?.cita?.especialidad ?? widget.especialidadNombre ?? 'Medicina General';
    final fechaReal = vm?.cita?.rangoFechas ?? widget.fechaCita ?? '03 Octubre 2026';
    final horaReal = vm?.cita?.horaTeleconsulta ?? widget.horaCita ?? '17:00 h';
    final clinicaReal = vm?.nombreClinica ?? widget.clinicaNombre ?? 'Hospital San Juan de Dios';

    final mensajes = teleconsultaProvider.mensajes;

    // Escuchar cambios para scrollear suavemente
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    Widget content = Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      widget.isModal ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // Avatar del médico
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        backgroundImage: vm?.medico?.fotoUrl != null && vm!.medico!.fotoUrl!.isNotEmpty
                            ? NetworkImage(vm.medico!.fotoUrl!)
                            : null,
                        child: vm?.medico?.fotoUrl == null || vm!.medico!.fotoUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 24)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Datos del médico y tiempo de respuesta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          nombreMedicoReal,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              especialidadReal,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                            Text(
                              'Suele responder en 2 h',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chip de contexto de cita
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$fechaReal • $horaReal • $clinicaReal',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Cita activa',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSuccessContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mensajes o indicador de carga
            Expanded(
              child: teleconsultaProvider.isLoading && mensajes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : mensajes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Inicia la conversación',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Envía un saludo o consulta al especialista sobre tus síntomas o tratamientos.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: mensajes.length,
                          itemBuilder: (ctx, index) {
                            final msg = mensajes[index];
                            return _buildMessageBubble(msg);
                          },
                        ),
            ),

            // Input inferior para escribir y enviar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary),
                    onPressed: _mostrarSelectorAdjuntos,
                    tooltip: 'Adjuntar archivo',
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendMessage(),
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Escribe a $nombreMedicoReal...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _handleSendMessage,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isModal) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: content,
      );
    }

    return content;
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final esPropio = msg.esPropio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: esPropio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esPropio) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: esPropio ? AppColors.primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esPropio ? 16 : 4),
                  bottomRight: Radius.circular(esPropio ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    esPropio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.contenido,
                    style: AppTypography.bodyMedium.copyWith(
                      color: esPropio ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  if (msg.adjuntoNombre != null && msg.adjuntoNombre!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: esPropio
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: esPropio
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            size: 16,
                            color: esPropio ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${msg.adjuntoNombre} (${msg.adjuntoTamano ?? "Archivo"})',
                              style: AppTypography.bodySmall.copyWith(
                                color: esPropio ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.horaDisplay,
                        style: AppTypography.bodySmall.copyWith(
                          color: esPropio
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      if (esPropio) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.idMensaje < 0
                              ? Icons.access_time_rounded
                              : Icons.done_all_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
