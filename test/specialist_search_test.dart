import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_telemedicina/features/appointments/specialist_search/data/models/specialist_search_models.dart';
import 'package:mobile_telemedicina/features/appointments/specialist_search/domain/entities/specialist_search_entities.dart';
import 'package:mobile_telemedicina/features/appointments/specialist_search/domain/repositories/specialist_search_repository.dart';
import 'package:mobile_telemedicina/features/appointments/specialist_search/presentation/providers/specialist_search_provider.dart';
import 'package:mobile_telemedicina/features/appointments/specialist_search/presentation/screens/specialist_search_screen.dart';

class MockSpecialistSearchRepository implements SpecialistSearchRepository {
  Future<SpecialistSearchResponseEntity> Function(SpecialistSearchFilterParams filters)? onSearch;
  Future<SpecialistEntity> Function(int idMedico, String fechaInicio, String fechaFin, {int? idServicio})? onAvailability;

  @override
  Future<SpecialistSearchResponseEntity> searchSpecialists(SpecialistSearchFilterParams filters) {
    if (onSearch != null) return onSearch!(filters);
    return Future.value(const SpecialistSearchResponseEntity(
      total: 0,
      page: 1,
      perPage: 20,
      items: [],
    ));
  }

  @override
  Future<SpecialistEntity> getSpecialistAvailability(int idMedico, String fechaInicio, String fechaFin, {int? idServicio}) {
    if (onAvailability != null) return onAvailability!(idMedico, fechaInicio, fechaFin, idServicio: idServicio);
    throw UnimplementedError();
  }
}

void main() {
  group('CU06 Specialist Search Mobile Models', () {
    test('SpecialistItemModel deserializa snake_case y camelCase correctamente', () {
      final snakeJson = {
        'id_medico': 42,
        'nombre_completo': 'Dra. Elena Ríos',
        'foto_url': 'http://test.com/foto.jpg',
        'matricula_profesional': 'MAT-123',
        'especialidades': [
          {'id_especialidad': 1, 'nombre': 'Cardiología'}
        ],
        'servicios': [
          {
            'id_servicio': 7,
            'nombre': 'Teleconsulta',
            'modalidad': 'TELECONSULTA',
            'costo': 250.0,
            'moneda': 'BOB',
            'duracion_minutos': 30,
          }
        ],
        'disponibilidad': [
          {
            'fecha': '2026-04-10',
            'slots': [
              {'hora_inicio': '08:00:00', 'hora_fin': '08:30:00', 'disponible': true}
            ]
          }
        ]
      };

      final modelFromSnake = SpecialistItemModel.fromJson(snakeJson);
      expect(modelFromSnake.idMedico, 42);
      expect(modelFromSnake.nombreCompleto, 'Dra. Elena Ríos');
      expect(modelFromSnake.matriculaProfesional, 'MAT-123');
      expect(modelFromSnake.especialidades.first.nombre, 'Cardiología');
      expect(modelFromSnake.servicios.first.modalidad, 'TELECONSULTA');
      expect(modelFromSnake.servicios.first.costo, 250.0);
      expect(modelFromSnake.disponibilidad.first.slots.first.disponible, true);

      final camelJson = {
        'idMedico': 42,
        'nombreCompleto': 'Dra. Elena Ríos',
        'fotoUrl': 'http://test.com/foto.jpg',
        'matriculaProfesional': 'MAT-123',
        'especialidades': [
          {'idEspecialidad': 1, 'nombre': 'Cardiología'}
        ],
        'servicios': [
          {
            'idServicio': 7,
            'nombre': 'Teleconsulta',
            'modalidad': 'TELECONSULTA',
            'costo': '250.0',
            'moneda': 'BOB',
            'duracionMinutos': 30,
          }
        ],
        'disponibilidad': [
          {
            'fecha': '2026-04-10',
            'slots': [
              {'horaInicio': '08:00:00', 'horaFin': '08:30:00', 'disponible': true}
            ]
          }
        ]
      };

      final modelFromCamel = SpecialistItemModel.fromJson(camelJson);
      expect(modelFromCamel.idMedico, 42);
      expect(modelFromCamel.nombreCompleto, 'Dra. Elena Ríos');
      expect(modelFromCamel.servicios.first.costo, 250.0);
      expect(modelFromCamel.servicios.first.duracionMinutos, 30);
    });
  });

  group('CU06 SpecialistSearchProvider', () {
    late MockSpecialistSearchRepository mockRepo;
    late SpecialistSearchProvider provider;

    setUp(() {
      mockRepo = MockSpecialistSearchRepository();
      provider = SpecialistSearchProvider(repository: mockRepo);
    });

    test('estado inicial y búsqueda exitosa', () async {
      expect(provider.isInitial, true);

      mockRepo.onSearch = (filters) async {
        return const SpecialistSearchResponseEntity(
          total: 1,
          page: 1,
          perPage: 20,
          items: [
            SpecialistEntity(
              idMedico: 10,
              nombreCompleto: 'Dra. Elena Ríos',
              matriculaProfesional: 'MAT-10',
              especialidades: [],
              servicios: [],
              disponibilidad: [],
            )
          ],
        );
      };

      await provider.search(const SpecialistSearchFilterParams(
        fechaInicio: '2026-04-10',
        fechaFin: '2026-04-15',
      ));

      expect(provider.isSuccess, true);
      expect(provider.items.length, 1);
      expect(provider.items.first.nombreCompleto, 'Dra. Elena Ríos');
    });

    test('respuesta atrasada no sobreescribe respuesta más reciente', () async {
      final completer1 = Completer<SpecialistSearchResponseEntity>();
      final completer2 = Completer<SpecialistSearchResponseEntity>();

      int callCount = 0;
      mockRepo.onSearch = (filters) {
        callCount++;
        if (callCount == 1) return completer1.future;
        return completer2.future;
      };

      // Disparar búsqueda 1
      provider.search(const SpecialistSearchFilterParams(
        nombre: 'Viejo',
        fechaInicio: '2026-04-10',
        fechaFin: '2026-04-15',
      ));

      // Disparar búsqueda 2
      provider.search(const SpecialistSearchFilterParams(
        nombre: 'Nuevo',
        fechaInicio: '2026-04-10',
        fechaFin: '2026-04-15',
      ));

      // Resuelve búsqueda 2 primero
      completer2.complete(const SpecialistSearchResponseEntity(
        total: 1,
        page: 1,
        perPage: 20,
        items: [
          SpecialistEntity(
            idMedico: 2,
            nombreCompleto: 'Doctor Nuevo',
            matriculaProfesional: 'MAT-2',
            especialidades: [],
            servicios: [],
            disponibilidad: [],
          )
        ],
      ));

      await Future.delayed(Duration.zero);
      expect(provider.items.first.nombreCompleto, 'Doctor Nuevo');

      // Resuelve búsqueda 1 retrasada
      completer1.complete(const SpecialistSearchResponseEntity(
        total: 1,
        page: 1,
        perPage: 20,
        items: [
          SpecialistEntity(
            idMedico: 1,
            nombreCompleto: 'Doctor Viejo',
            matriculaProfesional: 'MAT-1',
            especialidades: [],
            servicios: [],
            disponibilidad: [],
          )
        ],
      ));

      await Future.delayed(Duration.zero);
      // No debe ser sobreescrito por el doctor viejo
      expect(provider.items.first.nombreCompleto, 'Doctor Nuevo');
    });

    test('clear() restablece estado y limpia items', () async {
      mockRepo.onSearch = (filters) async {
        return const SpecialistSearchResponseEntity(
          total: 1,
          page: 1,
          perPage: 20,
          items: [
            SpecialistEntity(
              idMedico: 10,
              nombreCompleto: 'Dra. Elena Ríos',
              matriculaProfesional: 'MAT-10',
              especialidades: [],
              servicios: [],
              disponibilidad: [],
            )
          ],
        );
      };

      await provider.search(const SpecialistSearchFilterParams(
        fechaInicio: '2026-04-10',
        fechaFin: '2026-04-15',
      ));
      expect(provider.items.isNotEmpty, true);

      provider.clear();
      expect(provider.isInitial, true);
      expect(provider.items.isEmpty, true);
    });
  });

  group('CU06 SpecialistSearchScreen Widget', () {
    testWidgets('renderiza pantalla de búsqueda y estado vacío', (tester) async {
      final mockRepo = MockSpecialistSearchRepository();
      mockRepo.onSearch = (filters) async {
        return const SpecialistSearchResponseEntity(
          total: 0,
          page: 1,
          perPage: 20,
          items: [],
        );
      };
      final provider = SpecialistSearchProvider(repository: mockRepo);

      await tester.pumpWidget(MaterialApp(
        home: SpecialistSearchScreen(provider: provider),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Directorio de Especialistas'), findsOneWidget);
      expect(find.text('No se encontraron resultados'), findsOneWidget);
      expect(find.text('Buscar'), findsOneWidget);
    });
  });
}

