# GUÍA PASO A PASO: COMPILAR Y PUBLICAR EN GOOGLE PLAY STORE (SIN MAC)

* **Proyecto:** Damas del Mundo: Némesis IA (`com.juegodedamas.nemesis`)
* **Plataforma Objetivo:** Android (`minSdkVersion 23` — Android 6.0+ hasta `targetSdkVersion 35` — Android 15)
* **Arquitectura de Privacidad:** **100% Offline-First** (cero permisos de Internet o rastreo en `AndroidManifest.xml`, lo que simplifica al máximo la revisión de Políticas de Datos en Google Play Console).

---

## 1. REQUISITOS EN TU PC (WINDOWS O LINUX)

No necesitas Mac para desarrollar, probar ni publicar en Android. Solo necesitas:
1. **Flutter SDK (3.19 o superior):** Descárgalo desde `https://docs.flutter.dev/get-started/install`.
2. **Android Studio (o Android Command-Line Tools) + JDK 17:** Para contar con el compilador de Android (`sdkmanager` y `keytool`).
3. Verifica que todo esté listo abriendo una terminal en la carpeta del proyecto (`juego_de_damas`) y ejecutando:
   ```bash
   flutter doctor
   ```

---

## 2. EJECUTAR LAS PRUEBAS AUTOMATIZADAS EN TU PC

Antes de compilar para tu celular, verifica las 4 fases del proyecto:

```bash
# 1. Ejecutar los verificadores de invariantes y arquitectura GEM V4.0
python3 scripts/verify_f01.py && python3 scripts/verify_f02.py && python3 scripts/verify_f03.py && python3 scripts/verify_f04.py

# 2. Ejecutar la suite completa de Flutter Test (26 tests unitarios y de widget)
flutter test
```

---

## 3. COMPILAR EL `.APK` PARA INSTALAR DIRECTO EN TU CELULAR

Si quieres probar el juego hoy mismo en tu teléfono Android (enviándote el archivo por cable USB, WhatsApp, Telegram o Google Drive):

```bash
flutter build apk --release
```

* **¿Dónde queda el archivo `.apk`?**
  En `build/app/outputs/flutter-apk/app-release.apk`.
* **¿Cómo lo instalas?**
  Pásalo a tu celular, tócalo para abrirlo y acepta *"Instalar de esta fuente"*.

---

## 4. FIRMAR Y COMPILAR EL `.AAB` PARA GOOGLE PLAY STORE

Google Play Store exige que las aplicaciones se suban en formato **Android App Bundle (`.aab`)** firmadas con tu propia llave criptográfica (`keystore`).

### Paso 4.1: Generar tu llave privada de subida (`upload-keystore.jks`)
Ejecuta este comando **una sola vez** desde la carpeta `android/app/`:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*(Guarda ese archivo `upload-keystore.jks` y su contraseña en un lugar seguro como Google Drive, porque Google Play te pedirá siempre la misma llave para futuras actualizaciones).*

### Paso 4.2: Configurar `android/key.properties`
Copia la plantilla `android/key.properties.example` como `android/key.properties` y coloca tu contraseña:

```properties
storePassword=TU_PASSWORD_AQUI
keyPassword=TU_PASSWORD_AQUI
keyAlias=upload
storeFile=upload-keystore.jks
```

### Paso 4.3: Generar el paquete oficial `.aab`
Desde la raíz del proyecto ejecuta:

```bash
flutter build appbundle --release
```

* **¿Dónde queda el paquete listo para Google Play?**
  En `build/app/outputs/bundle/release/app-release.aab`.

---

## 5. SUBIR A GOOGLE PLAY CONSOLE (PASO A PASO)

1. Crea tu cuenta de desarrollador en **Google Play Console** (`https://play.google.com/console`, pago único de registro de \$25 USD).
2. Haz clic en **"Crear aplicación"**:
   * **Nombre:** *Damas del Mundo: Némesis IA*
   * **Idioma predeterminado:** Español (Latinoamérica / España)
   * **Aplicación o juego:** Juego
   * **Gratis o de pago:** Gratis (o de pago según prefieras)
3. En la sección **"Contenido de la aplicación" (Políticas)**:
   * **Seguridad de los datos (Data Safety):** Marca **"No, mi aplicación no recopila ni comparte ningún tipo de datos del usuario"**. Como nuestro `AndroidManifest.xml` no solicita permiso `INTERNET` y toda la IA (`TD-Learning`, `ADN` y `Academia`) vive localmente en `LocalStorageService`, pasará la auditoría de privacidad de Google sin fricciones.
   * **Clasificación por edades (IARC):** Marca que es un juego de mesa abstracto de estrategia sin violencia ni compras integradas (obtendrás clasificación **E / PEGI 3 / Apto para todo público**).
4. Ve a **Prueba cerrada / Producción -> Crear nueva versión**, sube el archivo `build/app/outputs/bundle/release/app-release.aab` y envía a revisión.
