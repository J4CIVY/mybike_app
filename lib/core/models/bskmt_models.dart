/// Modelos de datos para el ecosistema y backend BSKMT
class BskmtUser {
  final String id;
  final String email;
  final String displayName;
  final String membershipLevel;
  final String role;
  final String? phone;
  final bool emailVerified;
  final bool phoneVerified;
  final bool identityVerified;
  final String? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? eps;
  final String? profilePhoto;

  const BskmtUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.membershipLevel = 'STANDARD',
    this.role = 'user',
    this.phone,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.identityVerified = false,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.eps,
    this.profilePhoto,
  });

  factory BskmtUser.fromJson(Map<String, dynamic> json, {String? defaultEmail}) {
    final profile = (json['profile'] as Map<String, dynamic>?) ?? {};
    final personal = (profile['informacionPersonal'] as Map<String, dynamic>?) ?? {};
    final emergency = (profile['contactoEmergencia'] as Map<String, dynamic>?) ?? {};
    final medical = (profile['informacionMedica'] as Map<String, dynamic>?) ?? {};

    final firstName = personal['nombres']?.toString() ?? '';
    final lastName = personal['apellidos']?.toString() ?? '';
    final fullName = ('$firstName $lastName').trim();
    final name = fullName.isNotEmpty
        ? fullName
        : (json['displayName']?.toString() ?? json['email']?.toString() ?? 'Piloto BSKMT');

    return BskmtUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? defaultEmail ?? '',
      displayName: name,
      membershipLevel: (json['membershipLevel']?.toString() ?? 'STANDARD').toUpperCase(),
      role: json['role']?.toString() ?? 'user',
      phone: json['phone']?.toString() ?? personal['telefono']?.toString(),
      emailVerified: json['emailVerified'] == true,
      phoneVerified: json['phoneVerified'] == true,
      identityVerified: json['identityVerified'] == true,
      bloodType: medical['grupoSanguineo']?.toString() ?? 'O+',
      emergencyContactName: emergency['nombreContacto']?.toString(),
      emergencyContactPhone: emergency['telefonoContacto']?.toString(),
      eps: medical['eps']?.toString(),
      profilePhoto: personal['fotoPerfil']?.toString(),
    );
  }
}

class BskmtMotorcycle {
  final String id;
  final String brand;
  final String modelLine;
  final String plate;
  final int year;
  final int displacementCc;
  final String color;
  final String motorcycleType;
  final double currentOdometerKm;
  final DateTime? odometerLastUpdatedAt;
  final DateTime? soatExpiryDate;
  final DateTime? rtmExpiryDate;
  final DateTime? licenseExpiryDate;
  final bool isPrimary;
  final bool isRuntVerified;
  final String? runtSoatStatus;
  final String? runtRtmStatus;
  final String? insuranceCompany;
  final String? policyNumber;

  String get line => modelLine;
  String get model => modelLine;
  String? get vin => null;

  dynamic operator [](String key) {
    switch (key) {
      case 'id': return id;
      case 'brand': return brand;
      case 'line':
      case 'model':
      case 'modelLine': return modelLine;
      case 'plate': return plate;
      case 'year': return year;
      case 'color': return color;
      case 'displacementCc': return displacementCc;
      default: return null;
    }
  }

  const BskmtMotorcycle({
    required this.id,
    required this.brand,
    required this.modelLine,
    required this.plate,
    required this.year,
    required this.displacementCc,
    this.color = 'Negro',
    this.motorcycleType = 'Naked',
    this.currentOdometerKm = 0,
    this.odometerLastUpdatedAt,
    this.soatExpiryDate,
    this.rtmExpiryDate,
    this.licenseExpiryDate,
    this.isPrimary = false,
    this.isRuntVerified = false,
    this.runtSoatStatus,
    this.runtRtmStatus,
    this.insuranceCompany,
    this.policyNumber,
  });

  factory BskmtMotorcycle.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    return BskmtMotorcycle(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? 'Motocicleta',
      modelLine: json['modelLine']?.toString() ?? 'Modelo Base',
      plate: (json['plate']?.toString() ?? '').toUpperCase(),
      year: (json['year'] as num?)?.toInt() ?? 2024,
      displacementCc: (json['displacementCc'] as num?)?.toInt() ?? 250,
      color: json['color']?.toString() ?? 'Negro',
      motorcycleType: json['motorcycleType']?.toString() ?? 'Naked',
      currentOdometerKm: (json['currentOdometerKm'] as num?)?.toDouble() ?? 0.0,
      odometerLastUpdatedAt: parseDate(json['odometerLastUpdatedAt']),
      soatExpiryDate: parseDate(json['soatExpiryDate']),
      rtmExpiryDate: parseDate(json['rtmExpiryDate']),
      licenseExpiryDate: parseDate(json['licenseExpiryDate']),
      isPrimary: json['isPrimary'] == true,
      isRuntVerified: json['isRuntVerified'] == true,
      runtSoatStatus: json['runtSoatStatus']?.toString(),
      runtRtmStatus: json['runtRtmStatus']?.toString(),
      insuranceCompany: json['insuranceCompany']?.toString(),
      policyNumber: json['policyNumber']?.toString(),
    );
  }

  int? get daysUntilSoat {
    if (soatExpiryDate == null) return null;
    return soatExpiryDate!.difference(DateTime.now()).inDays;
  }

  int? get daysUntilRtm {
    if (rtmExpiryDate == null) return null;
    return rtmExpiryDate!.difference(DateTime.now()).inDays;
  }
}

class BskmtDocumentAlert {
  final String id;
  final String title;
  final DateTime? expiryDate;
  final int? daysRemaining;
  final String status;
  final bool canRenewOneClick;

  const BskmtDocumentAlert({
    required this.id,
    required this.title,
    this.expiryDate,
    this.daysRemaining,
    required this.status,
    this.canRenewOneClick = false,
  });

  factory BskmtDocumentAlert.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    return BskmtDocumentAlert(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Documento',
      expiryDate: parseDate(json['expiryDate']),
      daysRemaining: json['daysRemaining'] as int?,
      status: json['status']?.toString() ?? 'active',
      canRenewOneClick: json['canRenewOneClick'] == true,
    );
  }
}

class BskmtAlliedWorkshop {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String city;
  final double discountPercent;
  final String services;

  const BskmtAlliedWorkshop({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.city,
    required this.discountPercent,
    required this.services,
  });

  factory BskmtAlliedWorkshop.fromJson(Map<String, dynamic> json) {
    return BskmtAlliedWorkshop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Taller Aliado BSKMT',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Bogotá',
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 10.0,
      services: json['services']?.toString() ?? 'Mantenimiento Preventivo y Correctivo',
    );
  }
}

