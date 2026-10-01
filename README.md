# Escáner Local Offline (Document Scanner Mobile App)

Aplicación móvil profesional de escaneo, procesamiento y exportación de documentos en PDF que funciona **100% offline y de forma local en el dispositivo**.

---

## 🏛️ 1. Arquitectura y Estructura del Proyecto

El proyecto sigue una arquitectura **Clean Architecture / Feature-first Modular (MVVM)**, desacoplando completamente la lógica de negocio, el procesamiento de imagen en CPU, el almacenamiento local y la presentación visual en Flutter:

```text
doc_scanner_app/
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml       # Permisos estrictos (sin INTERNET) + FileProvider
│   │   │   └── res/xml/filepaths.xml     # Rutas seguras para FileProvider
│   │   └── build.gradle                  # Configuración Android SDK (minSdk 21, targetSdk 34)
│   ├── build.gradle                      # Repositorios Maven y Google
│   └── settings.gradle                   # Integración Gradle con Flutter
├── lib/
│   ├── main.dart                         # Inicialización offline e inyección de dependencias
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart           # Paleta visual accesible (Teal / Slate)
│   │   │   └── app_strings.dart          # Textos y constantes de UI 100% en español
│   │   └── theme/
│   │       └── app_theme.dart            # Material Design 3 (soporte claro y oscuro)
│   ├── data/
│   │   ├── models/
│   │   │   ├── filter_type.dart          # Enum de filtros (Original, B&N Texto, Grises, Magic Color)
│   │   │   ├── scanned_page_model.dart   # Modelo inmutable de página individual
│   │   │   └── document_model.dart       # Modelo de documento multi-página
│   │   ├── services/
│   │   │   ├── image_processor_service.dart # Binarización, rotación, recorte y filtros en Isolates
│   │   │   ├── pdf_generator_service.dart   # Compilador local a PDF estándar en tamaño A4
│   │   │   ├── storage_service.dart         # Persistencia en Hive y Scoped Storage privado
│   │   │   ├── scanner_service.dart         # Integración offline con Google ML Kit Document Scanner
│   │   │   └── share_export_service.dart    # Hoja nativa (Share Sheet) y exportador a Descargas
│   │   └── repositories/
│   │       └── document_repository.dart     # Única fuente de la verdad para documentos
│   └── ui/
│       ├── core_widgets/
│       │   ├── custom_app_bar.dart       # Barra superior con badge de modo 100% offline
│       │   ├── empty_state_view.dart     # Pantalla vacía con llamadas de acción
│       │   └── loading_indicator.dart    # Indicador de estado para procesamiento pesado
│       └── features/
│           ├── home/                     # Listado de documentos, búsqueda y accesos rápidos
│           │   ├── view_models/home_view_model.dart
│           │   └── views/home_view.dart
│           ├── scanner/                  # Cámara guiada en vivo con flash y visor de encuadre
│           │   ├── view_models/scanner_view_model.dart
│           │   └── views/camera_scanner_view.dart
│           ├── crop/                     # Recorte manual interactivo de esquinas (perspectiva de 4 puntos)
│           │   └── views/crop_perspective_view.dart
│           ├── editor/                   # Reordenar páginas, rotar 90°, aplicar filtros, añadir páginas
│           │   ├── view_models/document_editor_view_model.dart
│           │   ├── views/document_editor_view.dart
│           │   └── views/page_filter_view.dart
│           └── viewer/                   # Vista previa PDF interactiva, guardar en Descargas y compartir
│               └── views/pdf_viewer_view.dart
└── pubspec.yaml                          # Dependencias de producción y configuración
```

---

## 🔒 2. Garantías de Privacidad y Seguridad (100% Offline)

1. **Sin permiso de red:** `android.permission.INTERNET` ha sido omitido deliberadamente de `AndroidManifest.xml`. El sistema operativo Android impide a nivel de sandbox que la aplicación realice cualquier comunicación externa.
2. **Cero telemetría:** No existen trackers ni dependencias analíticas de terceros.
3. **Scoped Storage estricto:** Los documentos e imágenes escaneadas se almacenan en el directorio privado de la aplicación (`getApplicationDocumentsDirectory()`), inaccesible para otras aplicaciones salvo que el usuario lo exporte explícitamente.
4. **FileProvider:** El intercambio de archivos con otras aplicaciones se gestiona exclusivamente a través de URIs seguras y temporales mediante `androidx.core.content.FileProvider`.

---

## ⚙️ 3. Requisitos Previos para Compilar

Para compilar el archivo APK en tu PC, asegúrate de tener instalado:
1. **Flutter SDK** (versión 3.19.0 o superior): [flutter.dev](https://docs.flutter.dev/get-started/install)
2. **Android SDK** (API 34) y **Java JDK 17** (incluido habitualmente en Android Studio).

Verifica tu entorno ejecutando:
```bash
flutter doctor
```

---

## 🚀 4. Comandos Paso a Paso para Compilar y Generar el APK

Abre tu terminal en la carpeta del proyecto:
`C:\Users\Usuario\.gemini\antigravity\scratch\doc_scanner_app`

### Paso 1: Descargar las dependencias
```bash
flutter pub get
```

### Paso 2: Limpiar construcciones anteriores (opcional pero recomendado)
```bash
flutter clean
flutter pub get
```

### Paso 3: Compilar el APK en modo Release
Ejecuta el siguiente comando para generar el instalable APK optimizado:

```bash
flutter build apk --release
```

Si deseas generar APKs separados y optimizados por arquitectura de procesador (ARM64, ARMv7, x86_64) para reducir aún más el tamaño del archivo:
```bash
flutter build apk --release --split-per-abi
```

### Paso 4: Localizar el archivo APK generado
Una vez concluida la compilación, encontrarás tu archivo ejecutable listo para instalar en:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Paso 5: Instalar directamente en tu dispositivo Android vía USB (Opcional)
Con tu teléfono conectado con **Depuración USB** activada:
```bash
flutter install
# o directamente vía ADB:
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
