import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/clinical_documents_provider.dart';

/// Pantalla de visualización segura de un documento clínico (CU12).
/// Descarga el archivo autenticado y muestra sus metadatos e informe clínico.
class DocumentViewerScreen extends StatefulWidget {
  final int documentId;

  const DocumentViewerScreen({super.key, required this.documentId});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<ClinicalDocumentsProvider>();
    await provider.loadDetail(widget.documentId);
    final bytes = await provider.downloadDocument(widget.documentId);
    if (!mounted) return;
    setState(() => _pdfBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicalDocumentsProvider>();
    final doc = provider.selectedDocument;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          doc?.titulo ?? 'Documento Clínico',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _pdfBytes != null
          ? _buildDocumentPreview(doc, _pdfBytes!)
          : _buildEmptyOrLoading(context),
    );
  }

  Widget _buildDocumentPreview(dynamic doc, Uint8List bytes) {
    final kbSize = (bytes.lengthInBytes / 1024).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de estado de descarga
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.divider, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tealAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Documento Autenticado',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verificado por el servidor multitenant • $kbSize KB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hoja de Representación Clínica
          Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.divider, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado del documento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_hospital, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'CLÍNICA DIGITAL',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          doc?.tipoDocumento ?? 'DOCUMENTO',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Título y fecha
                  Text(
                    doc?.titulo ?? 'Documento Clínico Oficial',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (doc?.fechaDocumento != null)
                    Text(
                      'Fecha de emisión: ${doc.fechaDocumento}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 14),

                  // Info del paciente y firmante
                  if (doc?.pacienteNombre != null) ...[
                    _buildInfoRow(Icons.person_outline, 'Paciente:', doc.pacienteNombre),
                    const SizedBox(height: 6),
                  ],
                  if (doc?.firmanteNombre != null) ...[
                    _buildInfoRow(Icons.medical_services_outlined, 'Emitido por:', doc.firmanteNombre),
                    const SizedBox(height: 6),
                  ],
                  _buildInfoRow(Icons.confirmation_number_outlined, 'ID Documento:', '#${widget.documentId}'),

                  const Divider(height: 24),

                  // Descripción o contenido
                  Text(
                    'Contenido / Diagnóstico:',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (doc?.descripcion != null && (doc.descripcion as String).isNotEmpty)
                          ? doc.descripcion
                          : 'Documento clínico adjunto emitido de acuerdo a la consulta médica realizada. Contiene las pautas, recetas o indicaciones diagnósticas oficiales.',
                      style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Sello de seguridad
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.secondary.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Documento con validez legal interna. Archivo binario asegurado en storage multitenant (${bytes.lengthInBytes} bytes).',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondary.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botón volver
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver al Listado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyOrLoading(BuildContext context) {
    final provider = context.watch<ClinicalDocumentsProvider>();
    final errorMessage = provider.errorMessage;

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Descargando documento de forma segura...',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}