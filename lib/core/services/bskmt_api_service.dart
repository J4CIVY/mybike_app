import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/bskmt_models.dart';

export '../models/bskmt_models.dart';

/// Servicio singleton para comunicarse con la API de BSKMT
class BskmtApiService {
  static final BskmtApiService instance = BskmtApiService._internal();
  BskmtApiService._internal();

  static const String defaultBaseUrl = 'https://api.bskmt.com';
  String _baseUrl = defaultBaseUrl;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _sessionToken;
  BskmtUser? _currentUser;

  String get baseUrl => _baseUrl;
  BskmtUser? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _sessionToken != null && _sessionToken!.isNotEmpty;

  void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_sessionToken';
      headers['Cookie'] = 'better-auth.session_token=$_sessionToken';
    }
    return headers;
  }

  /// Inicializa la sesión guardada desde el almacenamiento seguro
  Future<bool> initSession() async {
    try {
      _sessionToken = await _storage.read(key: 'bskmt_session_token');
      final savedUserJson = await _storage.read(key: 'bskmt_user_profile');
      if (savedUserJson != null) {
        final decoded = jsonDecode(savedUserJson) as Map<String, dynamic>;
        _currentUser = BskmtUser.fromJson(decoded);
      }
      if (_sessionToken != null) {
        final profile = await fetchProfile();
        return profile != null;
      }
    } catch (_) {}
    return false;
  }

  /// Inicia sesión con correo y contraseña en BSKMT API
  Future<BskmtUser?> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/sign-in/email');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token =
            data['token']?.toString() ??
            data['session']?['token']?.toString() ??
            res.headers['set-cookie'];

        if (token != null) {
          _sessionToken = token;
          await _storage.write(key: 'bskmt_session_token', value: token);
        }

        final user = await fetchProfile(fallbackEmail: email);
        return user;
      } else {
        final err = jsonDecode(res.body);
        final msg = err['message'] ?? 'Credenciales inválidas en BSKMT';
        throw Exception(msg);
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Cierra sesión local y remueve credenciales
  Future<void> logout() async {
    try {
      if (_sessionToken != null) {
        final uri = Uri.parse('$_baseUrl/api/auth/sign-out');
        await http
            .post(uri, headers: _buildHeaders())
            .catchError((_) => http.Response('', 200));
      }
    } finally {
      _sessionToken = null;
      _currentUser = null;
      await _storage.delete(key: 'bskmt_session_token');
      await _storage.delete(key: 'bskmt_user_profile');
    }
  }

  /// Consulta el perfil del piloto en BSKMT (/profile)
  Future<BskmtUser?> fetchProfile({String? fallbackEmail}) async {
    if (!isAuthenticated) return null;
    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final res = await http.get(uri, headers: _buildHeaders());

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final user = BskmtUser.fromJson(data, defaultEmail: fallbackEmail);
        _currentUser = user;
        await _storage.write(
          key: 'bskmt_user_profile',
          value: jsonEncode(data),
        );
        return user;
      }
    } catch (_) {}
    return _currentUser;
  }

  /// Consulta los datos completos del Garage Virtual del usuario en BSKMT (/garage)
  Future<Map<String, dynamic>> fetchGarageDashboard({
    String? motorcycleId,
  }) async {
    const emptyGarage = {
      'hasVehicles': false,
      'motorcycles': <BskmtMotorcycle>[],
      'activeMotorcycle': null,
      'documentAlerts': <BskmtDocumentAlert>[],
      'alliedWorkshops': <BskmtAlliedWorkshop>[],
    };
    if (!isAuthenticated) return emptyGarage;

    try {
      var uri = Uri.parse('$_baseUrl/garage');
      if (motorcycleId != null) {
        uri = uri.replace(queryParameters: {'motorcycleId': motorcycleId});
      }

      final res = await http.get(uri, headers: _buildHeaders());

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final motosRaw = (data['motorcycles'] as List<dynamic>?) ?? [];
        final motorcycles = motosRaw
            .map((m) => BskmtMotorcycle.fromJson(m as Map<String, dynamic>))
            .toList();

        final activeRaw = data['activeMotorcycle'] as Map<String, dynamic>?;
        final activeMotorcycle = activeRaw != null
            ? BskmtMotorcycle.fromJson(activeRaw)
            : (motorcycles.isNotEmpty ? motorcycles.first : null);

        final alertsRaw = (data['documentAlerts'] as List<dynamic>?) ?? [];
        final documentAlerts = alertsRaw
            .map((a) => BskmtDocumentAlert.fromJson(a as Map<String, dynamic>))
            .toList();

        final workshopsRaw = (data['alliedWorkshops'] as List<dynamic>?) ?? [];
        final alliedWorkshops = workshopsRaw
            .map((w) => BskmtAlliedWorkshop.fromJson(w as Map<String, dynamic>))
            .toList();

        return {
          'hasVehicles': data['hasVehicles'] == true,
          'motorcycles': motorcycles,
          'activeMotorcycle': activeMotorcycle,
          'documentAlerts': documentAlerts,
          'alliedWorkshops': alliedWorkshops,
        };
      }
    } catch (_) {}

    return emptyGarage;
  }

  /// Sincroniza el Odómetro de la motocicleta activa directamente en el Garaje BSKMT
  Future<bool> updateOdometer({
    required String motorcycleId,
    required double odometerKm,
    String source = 'MOBILE_COCKPIT_BLE',
  }) async {
    if (!isAuthenticated || motorcycleId.isEmpty) return false;

    try {
      final uri = Uri.parse(
        '$_baseUrl/garage/motorcycles/$motorcycleId/odometer',
      );
      final res = await http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({'odometerKm': odometerKm.round(), 'source': source}),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Solicita Asistencia Mecánica o de Emergencia en Carretera ARPHA (/arpha/request)
  Future<Map<String, dynamic>> requestArphaSos({
    required double latitude,
    required double longitude,
    required String requestType,
    required String description,
    String? plate,
  }) async {
    if (!isAuthenticated) {
      throw Exception(
        'Debes iniciar sesión con tu cuenta BSKMT para solicitar ARPHA SOS',
      );
    }

    try {
      final uri = Uri.parse('$_baseUrl/arpha/request');
      final res = await http.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({
          'requestType': requestType,
          'description': description,
          'plate': plate,
          'location': {
            'type': 'Point',
            'coordinates': [longitude, latitude],
          },
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final err = jsonDecode(res.body);
        throw Exception(
          err['message'] ?? 'No se pudo generar la solicitud ARPHA',
        );
      }
    } catch (_) {
      rethrow;
    }
  }
}
