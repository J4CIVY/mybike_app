# ⚡ BSKMT Cockpit & Controller — App Móvil Oficial

Aplicación móvil oficial del ecosistema **BSKMT**, desarrollada en Flutter, diseñada para sincronizarse de manera bidireccional con el backend NestJS (**`Api`**) y el panel web de control y gestión (**`New-panel`**).

---

## 🏍️ Integración con el Ecosistema BSKMT

### 1. Conexión con `Api` (Backend NestJS)
- **Autenticación Better-Auth**: Inicio de sesión seguro con correo y contraseña vía `/api/auth/sign-in/email`, persistencia en almacenamiento seguro (AES-256) de tokens de sesión y datos del piloto.
- **Garaje Virtual BSKMT (`/garage`)**: Sincronización automática de motocicletas registradas por el usuario, placas, VIN y estado de vigencia de SOAT y RTM con semáforos visuales (Vigente, Próximo a vencer, Vencido).
- **Sincronización de Odómetro (`/garage/motorcycles/:id/odometer`)**: Envío de kilometraje real capturado por telemetría BLE VESC directamente a la nube del garaje.
- **Asistencia en Carretera ARPHA (`/arpha/request`)**: Modal de emergencia SOS con geolocalización GPS de alta precisión en tiempo real para despacho de grúa, auxilio mecánico, rescate médico o pinchazo.

### 2. Sincronización con `New-panel` (Dashboard Web)
- **Handoff Móvil & Deep Linking**:
  - Esquema URL nativo: `bskmt://cockpit` y `bskmt://garage`.
  - Package ID Android: `com.bskmt.app`.
  - Intent Android: `intent://cockpit#Intent;scheme=bskmt;package=com.bskmt.app;S.browser_fallback_url=https://bskmt.com/app;end`.
  - Enlaces universales: `https://bskmt.com/cockpit`.

---

## 📱 Características Principales

1. **Biker Profile & Garaje Virtual**:
   - Tarjeta digital del piloto con nivel BSKMT, placa activa y fecha de ingreso.
   - Listado de motos del garaje con alertas automáticas de SOAT y Tecnomecánica (RTM).
   - Acceso instantáneo a solicitud de grúa y auxilio vial ARPHA.
2. **Cockpit HUD & Telemetría en Vivo**:
   - Velocímetro digital con escala visual dinámica.
   - Potencia instantánea (kW), corriente de descarga/regeneración y voltaje del pack.
   - Monitor térmico en 3 puntos críticos (BMS, Inversor VESC y Motor).
   - Indicadores de luces, direccionales, pata de apoyo y estado de marcha.
3. **Diagnóstico Avanzado de Batería (BMS 24 Celdas)**:
   - Gráfico de barras interactivo con voltajes individuales celda por celda.
   - Cálculo automático de balance de celdas (Delta V en mV) y calificación de salud (Excelente, Bueno, Desbalance Moderado, Desbalance Crítico).
   - Radar de diagnóstico OBD de 8 fallas (sobrevoltaje, bajovoltaje, sobretemperatura, corto, etc.).
4. **Historial y Reproducción de Rutas**:
   - Mapa interactivo con codificación por gradiente de velocidad continua.
   - Línea de tiempo con velocidad de reproducción (1x, 2x, 4x) y opción para fijar cámara en la moto.
5. **Ajustes y Seguridad de la Moto**:
   - Sincronización horaria del reloj digital del tablero con un solo toque.
   - Límite de velocidad urbano (60 km/h) y modo de carga comercial.
   - Desbloqueo por proximidad BLE RSSI (Walk-Away Proximity Lock).
   - Inmovilizador antirrobo y gestión de tarjetas NFC.
6. **Diseño Visual BSKMT**:
   - Paleta de color oficial: Rojo Carmesí BSKMT (`#DC2626`), Pizarra Oscuro (`#0B0F17`/`#0F172A`), Oro/Ámbar (`#F59E0B`) y Esmeralda (`#10B981`).
   - Tipografía moderna (*Space Grotesk* y *Plus Jakarta Sans*).

---

## 🛠️ Requisitos de Entorno

- **Flutter SDK**: `>= 3.13.2`
- **Dart SDK**: `>= 3.13.2`
- **Android**:
  - `minSdk`: 26 (Android 8.0+)
  - `compileSdk`: 37
  - `applicationId` / `namespace`: `com.bskmt.app`
  - Java 17

---

## 🚀 Compilación y Ejecución

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Ejecutar en modo desarrollo
```bash
flutter run
```

### 3. Compilar APK Release optimizado
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```
*Archivo generado en: `build/app/outputs/flutter-apk/app-release.apk`*

### 4. Compilar App Bundle para Google Play
```bash
flutter build appbundle --release
```

---

## ⚠️ Advertencia y Responsabilidad

- Esta aplicación interactúa directamente con los controladores de potencia y sistemas de batería de la motocicleta mediante Bluetooth Low Energy (BLE).
- Por seguridad vial, **nunca manipules la pantalla ni configures parámetros mientras conduces**. Detén la motocicleta en un lugar seguro antes de realizar ajustes o consultar diagnósticos.
- Mantén siempre una llave de respaldo o tarjeta NFC física con tu vehículo.

---

## 📄 Licencia

Desarrollado para el ecosistema **BSKMT**. Todos los derechos reservados.
