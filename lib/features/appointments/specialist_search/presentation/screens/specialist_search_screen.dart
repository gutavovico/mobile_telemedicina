import 'package:flutter/material.dart';
import '../../data/models/specialist_search_models.dart';
import '../../domain/entities/specialist_search_entities.dart';
import '../providers/specialist_search_provider.dart';

class SpecialistSearchScreen extends StatefulWidget {
  final SpecialistSearchProvider provider;

  const SpecialistSearchScreen({
    super.key,
    required this.provider,
  });

  @override
  State<SpecialistSearchScreen> createState() => _SpecialistSearchScreenState();
}

class _SpecialistSearchScreenState extends State<SpecialistSearchScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _modalidad = 'AMBAS';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _triggerSearch();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _triggerSearch() {
    final filters = SpecialistSearchFilterParams(
      nombre: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      modalidad: _modalidad,
      costoMin: double.tryParse(_minPriceController.text.trim()),
      costoMax: double.tryParse(_maxPriceController.text.trim()),
      fechaInicio: _formatDate(_startDate),
      fechaFin: _formatDate(_endDate),
    );
    widget.provider.search(filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de Especialistas'),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: widget.provider,
        builder: (context, _) {
          return Column(
            children: [
              _buildFiltersSection(),
              Expanded(child: _buildResultsSection()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o apellido...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onSubmitted: (_) => _triggerSearch(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _modalidad,
                  decoration: InputDecoration(
                    labelText: 'Modalidad',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'AMBAS', child: Text('Todas')),
                    DropdownMenuItem(value: 'TELECONSULTA', child: Text('Teleconsulta')),
                    DropdownMenuItem(value: 'PRESENCIAL', child: Text('Presencial')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _modalidad = val);
                      _triggerSearch();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _triggerSearch,
                icon: const Icon(Icons.filter_list),
                label: const Text('Buscar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (widget.provider.isLoading && widget.provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.provider.isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                widget.provider.errorMessage ?? 'Error al buscar especialistas',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _triggerSearch,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.provider.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.provider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No se encontraron resultados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Intenta modificar tus filtros de búsqueda.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.provider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.provider.items.length,
        itemBuilder: (context, index) {
          final item = widget.provider.items[index];
          return _buildSpecialistCard(item);
        },
      ),
    );
  }

  Widget _buildSpecialistCard(SpecialistEntity item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: item.fotoUrl != null ? NetworkImage(item.fotoUrl!) : null,
                  child: item.fotoUrl == null
                      ? Text(
                          item.nombreCompleto.isNotEmpty ? item.nombreCompleto[0] : 'D',
                          style: TextStyle(fontSize: 20, color: Colors.blue.shade800),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombreCompleto,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Matrícula: ${item.matriculaProfesional}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Wrap(
                        spacing: 4,
                        children: item.especialidades
                            .map(
                              (e) => Chip(
                                label: Text(e.nombre, style: const TextStyle(fontSize: 10)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            if (item.servicios.isNotEmpty) ...[
              const Text(
                'Servicios disponibles:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...item.servicios.map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${s.nombre} (${s.modalidad})', style: const TextStyle(fontSize: 12)),
                      Text(
                        '${s.costo.toStringAsFixed(2)} ${s.moneda}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openAvailability(item),
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Ver Disponibilidad'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAvailability(SpecialistEntity item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Disponibilidad: ${item.nombreCompleto}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: item.disponibilidad.isEmpty
                        ? const Center(child: Text('No hay horarios disponibles en este rango.'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: item.disponibilidad.length,
                            itemBuilder: (context, index) {
                              final dia = item.disponibilidad[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      dia.fecha,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  if (dia.slots.isEmpty)
                                    const Text('Sin slots para este día', style: TextStyle(color: Colors.grey))
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: dia.slots.map((s) {
                                        return Chip(
                                          backgroundColor: s.disponible
                                              ? Colors.green.shade50
                                              : Colors.grey.shade200,
                                          label: Text(
                                            '${s.horaInicio.substring(0, 5)} - ${s.horaFin.substring(0, 5)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: s.disponible
                                                  ? Colors.green.shade800
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          avatar: Icon(
                                            s.disponible ? Icons.check_circle : Icons.block,
                                            size: 14,
                                            color: s.disponible ? Colors.green : Colors.grey,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

