# GUÍA PASO A PASO: COMPILAR Y PUBLICAR EN GOOGLE PLAY STORE (CAPACITOR 6 + GITHUB ACTIONS)

* **Proyecto:** Damas del Mundo (`com.juegodedamas.nemesis`)
* **Stack Nativo:** **Capacitor 6** (empaquetando `index.html` + Tailwind CSS compilado estáticamente en `www/`)
* **Plataforma Objetivo:** Android (`minSdkVersion 23` — Android 6.0+ hasta `targetSdkVersion 35` — Android 15 con Edge-to-Edge)
* **Arquitectura de Privacidad:** **100% Offline-First** (cero permiso `INTERNET` en `AndroidManifest.xml`, cero compras con dinero real, cero apuestas/rake, cero cuentas remotas).

---

## 1. VERIFICACIÓN LOCAL ANTES DE PUBLICAR

Ejecuta los verificadores integrales desde la raíz del repositorio:

```bash
# 1. Reconstruir Tailwind, ensamblar www/ y sincronizar con Android
npm run cap:sync

# 2. Auditar cumplimiento estricto de Google Play Store y Offline-First
python3 scripts/verify_playstore_ready.py

# 3. Ejecutar verificadores GEM V4.0 de todas las fases
python3 scripts/verify_f01.py && python3 scripts/verify_f02.py && python3 scripts/verify_f03.py && python3 scripts/verify_f04.py
```

---

## 2. GENERAR TU LLAVE DE FIRMA DIGITAL (`upload-keystore.jks`)

Google Play Store exige que cada `.aab` vaya firmado con una llave privada única. Ejecuta este comando **una sola vez** en tu PC o en GitHub Codespaces / terminal local con JDK 17:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

> **IMPORTANTE:** Guarda `upload-keystore.jks` y sus contraseñas en un gestor seguro fuera de Git. Nunca subas archivos `.jks` ni `android/key.properties` al repositorio (están bloqueados en `.gitignore`).

### Opción A: Compilar `.aab` en la nube con GitHub Actions (Recomendado)

El workflow [`.github/workflows/android-playstore.yml`](.github/workflows/android-playstore.yml) compila y firma automáticamente el `.aab` en Ubuntu con Node 20, JDK 17 y Android SDK API 35.

1. Convierte tu keystore a Base64:
   ```bash
   base64 -w 0 android/app/upload-keystore.jks
   ```
   *(En macOS usa `base64 -i android/app/upload-keystore.jks | tr -d '\n'`).*
2. En tu repositorio de GitHub ve a **Settings -> Secrets and variables -> Actions -> New repository secret** y crea estos **4 secrets**:
   * `ANDROID_KEYSTORE_BASE64`: salida Base64 del paso anterior.
   * `ANDROID_KEYSTORE_PASSWORD`: contraseña del almacén (`storePassword`).
   * `ANDROID_KEY_ALIAS`: `upload`
   * `ANDROID_KEY_PASSWORD`: contraseña de la llave (`keyPassword`).
3. Ve a la pestaña **Actions -> Android Play Store Build (Capacitor 6) -> Run workflow** (o publica un tag `git tag v1.0.0 && git push origin v1.0.0`).
4. Al terminar el job `build-release-aab`, descarga el artefacto **`damas-del-mundo-playstore-aab`** (`app-release.aab`).

### Opción B: Compilar `.aab` o `.apk` localmente (si tienes Android Studio / SDK)

1. Copia `android/key.properties.example` como `android/key.properties` y completa tus credenciales (`storeFile=upload-keystore.jks`).
2. Ejecuta:
   ```bash
   npm run cap:sync
   cd android
   ./gradlew assembleDebug    # APK de prueba rápida
   ./gradlew bundleRelease    # AAB firmado listo para Google Play Store
   ```
   *Salida `.aab`:* `android/app/build/outputs/bundle/release/app-release.aab`.

---

## 3. ACTIVAR POLÍTICA DE PRIVACIDAD EN GITHUB PAGES

Google Play Console exige una URL pública HTTPS para la Política de Privacidad:

1. En GitHub ve a **Settings -> Pages**.
2. En **Build and deployment -> Source**, selecciona **Deploy from a branch**, rama **`main`** y carpeta **`/ (root)`**.
3. Guarda y espera 1–2 minutos. La URL quedará activa en:
   * `https://emmanuelcamachod.github.io/damas-del-mundo/privacy-policy.html`

---

## 4. FICHA Y REQUISITOS EN GOOGLE PLAY CONSOLE

1. **Cuenta Play Console:** Registro único (\$25 USD) en `https://play.google.com/console`.
2. **Activos gráficos listos en `play_store_assets/`:**
   * **Ícono de la aplicación (512x512 px):** `play_store_assets/icon_512x512.png`
   * **Gráfico de funciones (1024x500 px):** `play_store_assets/feature_graphic_1024x500.png`
   * **Capturas de pantalla:** Toma 2–4 capturas reales desde tu celular instalando el `damas-del-mundo-debug-apk`.
3. **Políticas y Declaraciones:**
   * **Data Safety (Seguridad de los datos):** Marca **"No, mi aplicación no recopila ni comparte ningún tipo de datos del usuario"** (`AndroidManifest.xml` no declara `INTERNET`, todo el progreso vive en `localStorage` local).
   * **Anuncios:** Marca **"No, mi aplicación no contiene anuncios"**.
   * **Clasificación IARC:** Juego de mesa/estrategia abstracta sin dinero real ni compras -> clasificación **E / PEGI 3 / Apto para todo público**.
4. **Requisito obligatorio de Cuentas Personales (12 testers / 14 días):**
   * Si tu cuenta de Play Console es **Personal** creada después de noviembre de 2023, antes de habilitar **Producción** debes abrir una pista de **Prueba cerrada**, invitar al menos **12 testers confirmados** que mantengan la app instalada durante **14 días continuos** y luego solicitar el acceso a Producción.
