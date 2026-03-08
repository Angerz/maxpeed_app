import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/brand_option.dart';
import '../models/catalog_choice_option.dart';
import '../models/catalog_choices.dart';
import '../models/inventory_detail.dart';
import '../models/inventory_group_response.dart';
import '../models/rim_grouped_response.dart';
import '../models/rim_receipt_request.dart';
import '../models/restock_request.dart';
import '../models/restock_response.dart';
import '../models/sale_models.dart';
import '../models/service_option.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CatalogApiService {
  CatalogApiService({
    http.Client? client,
    this.host = '192.168.18.24',
    this.port = 8001,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String host;
  final int port;
  static const Duration _requestTimeout = Duration(seconds: 8);

  Future<CatalogChoices> fetchChoices() async {
    final uri = Uri.http('$host:$port', '/api/catalog/choices/');
    final response = await _getJson(uri);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al cargar opciones');
    }
    return CatalogChoices.fromJson(response);
  }

  Future<List<BrandOption>> searchBrands(String query) async {
    final trimmed = query.trim();
    final uri = Uri.http(
      '$host:$port',
      '/api/catalog/brands/',
      trimmed.isEmpty ? null : {'search': trimmed},
    );
    final response = await _getJson(uri);
    final rawList = response is List
        ? response
        : response is Map<String, dynamic> && response['results'] is List
        ? response['results'] as List
        : <dynamic>[];

    return rawList
        .whereType<Map>()
        .map((item) => BrandOption.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<List<BrandOption>> fetchRimBrands() async {
    final uri = Uri.http('$host:$port', '/api/catalog/rim-brands/');
    final response = await _getJson(uri);
    final rawList = response is List
        ? response
        : response is Map<String, dynamic> && response['results'] is List
        ? response['results'] as List
        : <dynamic>[];

    return rawList
        .whereType<Map>()
        .map((item) => BrandOption.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, dynamic>> postStockReceipt({
    required String tireType,
    required int brandId,
    required int ownerId,
    required String rimDiameter,
    required String origin,
    required String plyRating,
    required String treadType,
    required String letterColor,
    required int width,
    required int quantity,
    required String unitPurchasePrice,
    int? aspectRatio,
    String? recommendedSalePrice,
    String? model,
  }) async {
    final uri = Uri.http('$host:$port', '/api/inventory/stock-receipts/');
    final payload = <String, dynamic>{
      'tire_type': tireType,
      'brand_id': brandId,
      'owner_id': ownerId,
      'rim_diameter': rimDiameter,
      'origin': origin,
      'ply_rating': plyRating,
      'tread_type': treadType,
      'letter_color': letterColor,
      'width': width,
      'aspect_ratio': aspectRatio,
      'quantity': quantity,
      'unit_purchase_price': unitPurchasePrice,
      'recommended_sale_price': recommendedSalePrice,
      'model': model,
    };

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al registrar el ingreso. Verifica conexión y servidor.',
              );
            },
          );
    } on http.ClientException catch (error) {
      throw ApiException('Error de conexión: ${error.message}');
    } on TimeoutException {
      throw const ApiException(
        'Tiempo de espera agotado al registrar el ingreso. Verifica conexión y servidor.',
      );
    }

    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al registrar ingreso');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> createStockReceipt({
    required String tireType,
    required int brandId,
    required int ownerId,
    required String rimDiameter,
    required String origin,
    required String plyRating,
    required String treadType,
    required String letterColor,
    required int width,
    required int quantity,
    required String unitPurchasePrice,
    int? aspectRatio,
    String? recommendedSalePrice,
    String? model,
  }) {
    return postStockReceipt(
      tireType: tireType,
      brandId: brandId,
      ownerId: ownerId,
      rimDiameter: rimDiameter,
      origin: origin,
      plyRating: plyRating,
      treadType: treadType,
      letterColor: letterColor,
      width: width,
      quantity: quantity,
      unitPurchasePrice: unitPurchasePrice,
      aspectRatio: aspectRatio,
      recommendedSalePrice: recommendedSalePrice,
      model: model,
    );
  }

  Future<InventoryGroupResponse> fetchInventory({
    required bool includeZeroStock,
  }) async {
    final uri = Uri.http('$host:$port', '/api/inventory/items/', {
      'include_zero_stock': includeZeroStock.toString(),
    });
    final response = await _getJson(uri);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al cargar inventario');
    }
    return InventoryGroupResponse.fromJson(response);
  }

  Future<RimGroupedResponse> fetchRimsInventory() async {
    final uri = Uri.http('$host:$port', '/api/inventory/rims/');
    final response = await _getJson(uri);
    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        'Respuesta inválida al cargar inventario de aros',
      );
    }
    return RimGroupedResponse.fromJson(response);
  }

  Future<InventoryDetail> fetchInventoryDetail(int inventoryItemId) async {
    final uri = Uri.http(
      '$host:$port',
      '/api/inventory/items/$inventoryItemId/',
    );
    final response = await _getJson(uri);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al cargar detalle');
    }
    return InventoryDetail.fromJson(response);
  }

  Future<RestockResponse> restockInventoryItem(
    int inventoryItemId,
    RestockRequest requestPayload,
  ) async {
    final uri = Uri.http(
      '$host:$port',
      '/api/inventory/items/$inventoryItemId/restock/',
    );

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(requestPayload.toJson()),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al registrar restock. Verifica conexión y servidor.',
              );
            },
          );
    } on http.ClientException catch (error) {
      throw ApiException('Error de conexión: ${error.message}');
    } on TimeoutException {
      throw const ApiException(
        'Tiempo de espera agotado al registrar restock. Verifica conexión y servidor.',
      );
    }

    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al registrar restock');
    }

    return RestockResponse.fromJson(decoded);
  }

  Future<Map<String, dynamic>> postRimReceipt(RimReceiptRequest request) async {
    final uri = Uri.http('$host:$port', '/api/inventory/rim-receipts/');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al registrar ingreso de aro. Verifica conexión y servidor.',
              );
            },
          );
    } on http.ClientException catch (error) {
      throw ApiException('Error de conexión: ${error.message}');
    } on TimeoutException {
      throw const ApiException(
        'Tiempo de espera agotado al registrar ingreso de aro. Verifica conexión y servidor.',
      );
    }

    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'Respuesta inválida al registrar ingreso de aro',
      );
    }

    return decoded;
  }

  Future<void> deactivateRim(int inventoryItemId, {String? reason}) async {
    final uri = Uri.http(
      '$host:$port',
      '/api/inventory/rims/$inventoryItemId/deactivate/',
    );
    final payload = reason == null || reason.trim().isEmpty
        ? const <String, dynamic>{}
        : <String, dynamic>{'reason': reason.trim()};

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al desactivar aro. Verifica conexión y servidor.',
              );
            },
          );
    } on http.ClientException catch (error) {
      throw ApiException('Error de conexión: ${error.message}');
    } on TimeoutException {
      throw const ApiException(
        'Tiempo de espera agotado al desactivar aro. Verifica conexión y servidor.',
      );
    }

    _decodeResponse(response);
  }

  Future<List<ServiceOption>> fetchServices() async {
    final uri = Uri.http('$host:$port', '/api/catalog/services/');
    final response = await _getJson(uri);
    final rawList = response is List
        ? response
        : response is Map<String, dynamic> && response['results'] is List
        ? response['results'] as List
        : <dynamic>[];

    return rawList
        .map(ServiceOption.fromDynamic)
        .where((option) => option.name.isNotEmpty)
        .toList();
  }

  Future<SaleCreateResponse> createSale(SaleCreateRequest request) async {
    final uri = Uri.http('$host:$port', '/api/sales/');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al registrar venta. Verifica conexión y servidor.',
              );
            },
          );
    } on http.ClientException catch (error) {
      throw ApiException('Error de conexión: ${error.message}');
    } on TimeoutException {
      throw const ApiException(
        'Tiempo de espera agotado al registrar venta. Verifica conexión y servidor.',
      );
    }

    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al crear venta');
    }
    return SaleCreateResponse.fromJson(decoded);
  }

  Future<SalesListResponse> fetchSales({
    DateTime? start,
    DateTime? end,
    String? url,
  }) async {
    Uri uri;
    if (url == null || url.trim().isEmpty) {
      if (start == null || end == null) {
        throw const ApiException('Rango de fechas inválido para cargar ventas');
      }
      uri = Uri.http('$host:$port', '/api/sales/', {
        'start_date': _toYmd(start),
        'end_date': _toYmd(end),
      });
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      uri = Uri.parse(url);
    } else {
      final parsed = Uri.parse(url);
      uri = Uri.http('$host:$port', parsed.path, parsed.queryParameters);
    }
    final response = await _getJson(uri);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al cargar ventas');
    }
    return SalesListResponse.fromJson(response);
  }

  Future<SaleDetail> fetchSaleDetail(int id) async {
    final uri = Uri.http('$host:$port', '/api/sales/$id/');
    final response = await _getJson(uri);
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al cargar detalle de venta');
    }
    return SaleDetail.fromJson(response);
  }

  Future<dynamic> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al cargar datos. Verifica conexión y servidor.',
              );
            },
          );
      return _decodeResponse(response);
    } on http.ClientException catch (error) {
      throw ApiException('Error de conexión: ${error.message}');
    } on TimeoutException {
      throw const ApiException(
        'Tiempo de espera agotado al cargar datos. Verifica conexión y servidor.',
      );
    }
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractError(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(response.body);
  }

  String _extractError(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail =
            decoded['detail'] ?? decoded['message'] ?? decoded['error'];
        if (detail != null) {
          return detail.toString();
        }
        return decoded.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(' | ');
      }
      if (decoded is List && decoded.isNotEmpty) {
        return decoded.join(' | ');
      }
    } catch (_) {
      // Fall back to the raw body below.
    }

    if (body.trim().isNotEmpty) {
      return body.trim();
    }

    return 'Error de servidor ($statusCode)';
  }

  String _toYmd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String translateLabel(String fieldKey, CatalogChoiceOption option) {
    const fieldTranslations = {
      'tire_type': {
        'RADIAL': 'Radial',
        'CARGO': 'Carga',
        'MILLIMETRIC': 'Milimétrica',
        'CONVENTIONAL': 'Convencional',
      },
      'origin': {
        'CHINA': 'China',
        'THAILAND': 'Tailandesa',
        'JAPAN': 'Japonesa',
        'KOREA': 'Coreana',
        'AMERICAN': 'Americana',
        'INDIA': 'India',
        'MEXICAN': 'Mexicana',
        'EUROPE': 'Europea',
        'PERUVIAN': 'Peruana',
        'OTHER': 'Otra',
      },
      'tread_type': {
        'LINEAR': 'Lineal',
        'HIGHWAY': 'Pistera',
        'SPORT': 'Deportiva',
        'MIXED': 'Mixta',
      },
      'letter_color': {'BLACK': 'Negro', 'WHITE': 'Blanco'},
      'rim_material': {'ALUMINUM': 'Aluminio', 'IRON': 'Hierro'},
      'rim_is_set': {'true': 'Juego completo', 'false': 'Unidad'},
    };

    final translated = fieldTranslations[fieldKey]?[option.value];
    if (translated != null) {
      return translated;
    }

    final normalized = option.label.trim();
    if (normalized.isEmpty) {
      return option.value;
    }

    return normalized;
  }
}
