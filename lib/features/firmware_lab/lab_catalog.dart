// Firmware Lab — Catálogo de características BLE para pruebas de ingeniería.

import 'catalog/lab_catalog_info.dart';
import 'catalog/lab_catalog_settings.dart';
import 'catalog/lab_catalog_telemetry.dart';
import 'models/lab_models.dart';

export 'catalog/lab_catalog_info.dart';
export 'catalog/lab_catalog_settings.dart';
export 'catalog/lab_catalog_telemetry.dart';
export 'models/lab_models.dart';

final labCatalog = <LabCharTest>[
  ...labCatalogSettings,
  ...labCatalogInfo,
  ...labCatalogTelemetry,
];
