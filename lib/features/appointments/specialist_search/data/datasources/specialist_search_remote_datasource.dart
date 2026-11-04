import '../../../../../core/network/api_client.dart';
import '../models/specialist_search_models.dart';

class SpecialistSearchRemoteDataSource {
  final ApiClient _apiClient;

  SpecialistSearchRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<SpecialistSearchResponseModel> searchSpecialists(
    SpecialistSearchFilterParams filters,
  ) async {
    final queryParams = filters.toQueryParams();
    final queryString = Uri(queryParameters: queryParams).query;
    final url = '/especialistas/buscar?$queryString';

    final response = await _apiClient.get(url);
    if (response is Map<String, dynamic>) {
      return SpecialistSearchResponseModel.fromJson(response);
    }
    return const SpecialistSearchResponseModel(
      total: 0,
      page: 1,
      perPage: 20,
      items: [],
    );
  }

  Future<SpecialistItemModel> getSpecialistAvailability(
    int idMedico,
    String fechaInicio,
    String fechaFin, {
    int? idServicio,
  }) async {
    final queryParams = <String, String>{
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
    };
    if (idServicio != null) {
      queryParams['id_servicio'] = idServicio.toString();
    }
    final queryString = Uri(queryParameters: queryParams).query;
    final url = '/especialistas/$idMedico/disponibilidad?$queryString';

    final response = await _apiClient.get(url);
    return SpecialistItemModel.fromJson(response as Map<String, dynamic>);
  }
}

