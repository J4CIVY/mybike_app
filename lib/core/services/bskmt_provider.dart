import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bskmt_api_service.dart';

class BskmtState {
  final bool isLoading;
  final bool isAuthenticated;
  final BskmtUser? user;
  final List<BskmtMotorcycle> motorcycles;
  final BskmtMotorcycle? activeMotorcycle;
  final List<BskmtDocumentAlert> documentAlerts;
  final List<BskmtAlliedWorkshop> alliedWorkshops;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastSyncedAt;

  const BskmtState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.motorcycles = const [],
    this.activeMotorcycle,
    this.documentAlerts = const [],
    this.alliedWorkshops = const [],
    this.errorMessage,
    this.successMessage,
    this.lastSyncedAt,
  });

  BskmtState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    BskmtUser? user,
    List<BskmtMotorcycle>? motorcycles,
    BskmtMotorcycle? activeMotorcycle,
    List<BskmtDocumentAlert>? documentAlerts,
    List<BskmtAlliedWorkshop>? alliedWorkshops,
    String? errorMessage,
    String? successMessage,
    DateTime? lastSyncedAt,
    bool clearActiveMotorcycle = false,
  }) {
    return BskmtState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      motorcycles: motorcycles ?? this.motorcycles,
      activeMotorcycle: clearActiveMotorcycle ? null : (activeMotorcycle ?? this.activeMotorcycle),
      documentAlerts: documentAlerts ?? this.documentAlerts,
      alliedWorkshops: alliedWorkshops ?? this.alliedWorkshops,
      errorMessage: errorMessage,
      successMessage: successMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class BskmtNotifier extends StateNotifier<BskmtState> {
  final BskmtApiService _api = BskmtApiService.instance;

  BskmtNotifier() : super(const BskmtState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    final hasSession = await _api.initSession();
    if (hasSession && _api.currentUser != null) {
      state = state.copyWith(
        isAuthenticated: true,
        user: _api.currentUser,
      );
      await refreshGarage();
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final user = await _api.login(email: email, password: password);
      if (user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          successMessage: '¡Bienvenido, ${user.displayName}!',
        );
        await refreshGarage();
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Error al iniciar sesión');
      return false;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _api.logout();
    state = const BskmtState();
  }

  Future<void> refreshGarage() async {
    if (!state.isAuthenticated) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _api.fetchGarageDashboard();
      final motorcycles = (data['motorcycles'] as List<BskmtMotorcycle>?) ?? [];
      final activeMoto = data['activeMotorcycle'] as BskmtMotorcycle? ??
          (motorcycles.isNotEmpty ? motorcycles.first : null);
      final alerts = (data['documentAlerts'] as List<BskmtDocumentAlert>?) ?? [];
      final workshops = (data['alliedWorkshops'] as List<BskmtAlliedWorkshop>?) ?? [];

      state = state.copyWith(
        isLoading: false,
        motorcycles: motorcycles,
        activeMotorcycle: activeMoto,
        documentAlerts: alerts,
        alliedWorkshops: workshops,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al sincronizar garaje BSKMT');
    }
  }

  void selectMotorcycle(String id) {
    final found = state.motorcycles.firstWhere(
      (m) => m.id == id,
      orElse: () => state.motorcycles.first,
    );
    state = state.copyWith(activeMotorcycle: found);
  }

  /// Sincroniza el odómetro del viaje/moto actual con el Garaje BSKMT
  Future<bool> syncCurrentOdometer(double km) async {
    final moto = state.activeMotorcycle;
    if (moto == null || moto.id.isEmpty) return false;

    // Solo actualizar si el km es mayor o relevante
    if (km <= moto.currentOdometerKm && km > 0) return true;

    final ok = await _api.updateOdometer(
      motorcycleId: moto.id,
      odometerKm: km,
      source: 'APP_COCKPIT_BLE',
    );

    if (ok) {
      await refreshGarage();
      return true;
    }
    return false;
  }

  /// Solicita ayuda ARPHA en carretera
  Future<bool> requestArphaHelp({
    required double lat,
    required double lng,
    required String requestType,
    required String description,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _api.requestArphaSos(
        latitude: lat,
        longitude: lng,
        requestType: requestType,
        description: description,
        plate: state.activeMotorcycle?.plate,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: '¡Asistencia ARPHA solicitada con éxito! Un operador te contactará en breve.',
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final bskmtProvider = StateNotifierProvider<BskmtNotifier, BskmtState>((ref) {
  return BskmtNotifier();
});
