import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybike_app/core/models/bskmt_models.dart';
import 'bskmt_api_service.dart';

export 'package:mybike_app/core/models/bskmt_models.dart';
export 'bskmt_api_service.dart';

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
    bool clearActiveMotorcycle = false,
    List<BskmtDocumentAlert>? documentAlerts,
    List<BskmtAlliedWorkshop>? alliedWorkshops,
    String? errorMessage,
    String? successMessage,
    DateTime? lastSyncedAt,
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

class BskmtNotifier extends Notifier<BskmtState> {
  final BskmtApiService _api = BskmtApiService.instance;

  @override
  BskmtState build() {
    Future.microtask(init);
    return const BskmtState();
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
          errorMessage: null,
        );
        await refreshGarage();
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Credenciales inválidas');
      return false;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = const BskmtState();
  }

  Future<void> refreshGarage() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _api.fetchGarageDashboard();
      final motos = (data['motorcycles'] as List<BskmtMotorcycle>?) ?? [];
      final alerts = (data['documentAlerts'] as List<BskmtDocumentAlert>?) ?? [];
      final workshops = (data['alliedWorkshops'] as List<BskmtAlliedWorkshop>?) ?? [];
      final active = data['activeMotorcycle'] as BskmtMotorcycle?;

      state = state.copyWith(
        isLoading: false,
        motorcycles: motos,
        activeMotorcycle: active ?? (motos.isNotEmpty ? motos.first : null),
        documentAlerts: alerts,
        alliedWorkshops: workshops,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  void selectMotorcycle(dynamic motoOrId) {
    if (motoOrId is BskmtMotorcycle) {
      state = state.copyWith(activeMotorcycle: motoOrId);
    } else if (motoOrId is String) {
      final found = state.motorcycles.where((m) => m.id == motoOrId).firstOrNull;
      if (found != null) {
        state = state.copyWith(activeMotorcycle: found);
      }
    }
  }

  Future<bool> syncOdometer(num odo) async {
    final motoId = state.activeMotorcycle?.id;
    if (motoId == null || motoId.isEmpty) return false;
    return _api.updateOdometer(motorcycleId: motoId, odometerKm: odo.toDouble());
  }

  Future<bool> requestArphaHelp({
    required double lat,
    required double lng,
    required String requestType,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
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

final bskmtProvider = NotifierProvider<BskmtNotifier, BskmtState>(BskmtNotifier.new);
