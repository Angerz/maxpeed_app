import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/brand_option.dart';
import '../models/catalog_choice_option.dart';
import '../models/catalog_choices.dart';
import '../models/inventory_detail.dart';
import '../models/inventory_group_response.dart';
import '../models/login_response.dart';
import '../models/rim_grouped_response.dart';
import '../models/rim_receipt_request.dart';
import '../models/restock_request.dart';
import '../models/restock_response.dart';
import '../models/sale_models.dart';
import '../models/service_option.dart';
import '../models/capabilities.dart';

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
  static String? _authToken;
  static VoidCallback? _onUnauthorized;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static void setUnauthorizedHandler(VoidCallback? callback) {
    _onUnauthorized = callback;
  }

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
            headers: _buildHeaders(json: true, authenticated: true),
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
    return InventoryGroupResponse.fromJson(
      _normalizeImageUrlsInGroupedResponse(response),
    );
  }

  Future<RimGroupedResponse> fetchRimsInventory() async {
    final uri = Uri.http('$host:$port', '/api/inventory/rims/');
    final response = await _getJson(uri);
    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        'Respuesta inválida al cargar inventario de aros',
      );
    }
    return RimGroupedResponse.fromJson(
      _normalizeImageUrlsInGroupedResponse(response),
    );
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
    return InventoryDetail.fromJson(_normalizeImageUrlsInItem(response));
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
            headers: _buildHeaders(json: true, authenticated: true),
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
    if (request.rimPhotoBytes != null) {
      return _postRimReceiptMultipart(uri, request);
    }

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _buildHeaders(json: true, authenticated: true),
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

  Future<Map<String, dynamic>> _postRimReceiptMultipart(
    Uri uri,
    RimReceiptRequest request,
  ) async {
    final multipart = http.MultipartRequest('POST', uri);
    multipart.headers.addAll(_buildHeaders(json: false, authenticated: true));
    multipart.fields.addAll(request.toFields());

    final bytes = request.rimPhotoBytes!;
    final filename = _resolvePhotoFilename(
      request.rimPhotoFilename,
      request.internalCode,
    );
    final contentType = _resolveImageContentType(filename);
    multipart.files.add(
      http.MultipartFile.fromBytes(
        'rim_photo',
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );

    http.Response response;
    try {
      final streamed = await _client
          .send(multipart)
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al registrar ingreso de aro. Verifica conexión y servidor.',
              );
            },
          );
      response = await http.Response.fromStream(streamed);
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

  String buildAbsoluteUrl(String? relativeOrAbsoluteUrl) {
    final raw = (relativeOrAbsoluteUrl ?? '').trim();
    if (raw.isEmpty) {
      return '';
    }
    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      return raw;
    }
    final base = Uri.http('$host:$port');
    final resolved = base.resolve(raw);
    return resolved.toString();
  }

  String _resolvePhotoFilename(String? rawFilename, String fallbackBase) {
    final raw = (rawFilename ?? '').trim();
    if (raw.isEmpty) {
      return '$fallbackBase.jpg';
    }
    final lower = raw.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return raw;
    }
    if (lower.endsWith('.png')) {
      return raw;
    }
    return '$raw.jpg';
  }

  MediaType _resolveImageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    return MediaType('application', 'octet-stream');
  }

  Map<String, dynamic> _normalizeImageUrlsInGroupedResponse(
    Map<String, dynamic> raw,
  ) {
    final output = <String, dynamic>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is List) {
        output[entry.key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _normalizeImageUrlsInItem(item);
          }
          if (item is Map) {
            return _normalizeImageUrlsInItem(item.cast<String, dynamic>());
          }
          return item;
        }).toList();
      } else {
        output[entry.key] = value;
      }
    }
    return output;
  }

  Map<String, dynamic> _normalizeImageUrlsInItem(Map<String, dynamic> item) {
    final out = Map<String, dynamic>.from(item);
    out['image'] = _normalizeImageRef(out['image']);
    out['image_thumb'] = _normalizeImageRef(out['image_thumb']);
    return out;
  }

  Map<String, dynamic>? _normalizeImageRef(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final urlRaw = (raw['url'] ?? '').toString();
      return {...raw, 'url': buildAbsoluteUrl(urlRaw)};
    }
    if (raw is Map) {
      final casted = raw.cast<String, dynamic>();
      final urlRaw = (casted['url'] ?? '').toString();
      return {...casted, 'url': buildAbsoluteUrl(urlRaw)};
    }
    return null;
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
            headers: _buildHeaders(json: true, authenticated: true),
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
            headers: _buildHeaders(json: true, authenticated: true),
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

  Future<dynamic> _getJson(Uri uri, {bool authenticated = true}) async {
    final tokenSnapshot = _authToken;
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(authenticated: authenticated))
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al cargar datos. Verifica conexión y servidor.',
              );
            },
          );
      if (response.statusCode == 401 &&
          authenticated &&
          (tokenSnapshot ?? '').isNotEmpty &&
          tokenSnapshot == _authToken) {
        _onUnauthorized?.call();
      }
      return _decodeResponse(response);
    } on http.ClientException catch (error) {
      throw ApiException('Error de conexión: ${error.message}');
    } on TimeoutException {
      throw const ApiException(
        'Tiempo de espera agotado al cargar datos. Verifica conexión y servidor.',
      );
    }
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.http('$host:$port', '/api/auth/login/');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _buildHeaders(json: true, authenticated: false),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw const ApiException(
                'Tiempo de espera agotado al iniciar sesión.',
              );
            },
          );
    } on http.ClientException catch (error) {
      throw ApiException('Error de conexión: ${error.message}');
    } on TimeoutException {
      throw const ApiException('Tiempo de espera agotado al iniciar sesión.');
    }

    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respuesta inválida al iniciar sesión');
    }
    return LoginResponse.fromJson(decoded);
  }

  Future<void> logout() async {
    final uri = Uri.http('$host:$port', '/api/auth/logout/');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(json: true, authenticated: true),
            body: jsonEncode(const <String, dynamic>{}),
          )
          .timeout(_requestTimeout);
      _decodeResponse(response);
    } catch (_) {
      rethrow;
    }
  }

  Future<Capabilities> fetchCapabilities() async {
    final uri = Uri.http('$host:$port', '/api/capabilities/');
    final response = await _getJson(uri, authenticated: true);
    if (response is Map<String, dynamic>) {
      final source = response['capabilities'] ?? response;
      return Capabilities.fromDynamic(source);
    }
    return const Capabilities(<String, bool>{});
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

  Map<String, String> _buildHeaders({
    bool json = false,
    bool authenticated = true,
  }) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (authenticated && (_authToken ?? '').isNotEmpty) {
      headers['Authorization'] = 'Token ${_authToken!}';
    }
    return headers;
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
