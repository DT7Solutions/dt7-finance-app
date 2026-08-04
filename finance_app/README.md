# 🚀 DT7 Agency Finance Flutter Application — Complete Step-by-Step Guide

This guide provides a comprehensive step-by-step manual for **Installing**, **Running**, **Checking Code Quality**, **Same Wi-Fi Network Setup**, and **Building Production Release Bundles** for the DT7 Agency Finance Flutter Project.

---

## 📋 Table of Contents
- [1. INSTALLATION & SETUP](#1-installation--setup)
- [2. CHECKING PROJECT HEALTH & TESTING](#2-checking-project-health--testing)
- [3. RUNNING THE FLUTTER APPLICATION](#3-running-the-flutter-application)
  - [3.1 Run in Chrome (Local Debug)](#31-run-in-chrome-local-debug)
  - [3.2 Run on Same Wi-Fi Network (Laptop + Mobile Phone)](#32-run-on-same-wi-fi-network-laptop--mobile-phone)
  - [3.3 Run as Windows Desktop App](#33-run-as-windows-desktop-app)
- [4. BUILDING THE PROJECT (PRODUCTION RELEASE)](#4-building-the-project-production-release)
  - [4.1 Build Web Release Bundle](#41-build-web-release-bundle)
  - [4.2 Build Android APK](#42-build-android-apk)
- [5. TROUBLESHOOTING & PROCESS TIPS](#5-troubleshooting--process-tips)

---

## 1. INSTALLATION & SETUP

### Step 1.1: Verify Environment & Flutter Doctor
Open Terminal / PowerShell and check system prerequisites:
```bash
flutter doctor
```
*Ensure Flutter SDK (`>=3.0.0`) and Google Chrome or Edge are available.*

### Step 1.2: Fetch Project Dependencies
Navigate to the `finance_app` project directory:
```bash
cd d:\mobile_app\dt7-finance-app\finance_app
```
Download all required Flutter packages (`pubspec.yaml`):
```bash
flutter pub get
```

### Step 1.3: Setup Backend API Connection
The app connects to a Django REST API. Configure the API base URL in `lib/services/auth_service.dart`:

```dart
// Open lib/services/auth_service.dart

// For Same Wi-Fi Network Testing:
static String baseUrl = 'http://192.168.0.7:8000/api/v1';

// For Local Chrome Testing:
// static String baseUrl = 'http://127.0.0.1:8000/api/v1';
```

---

## 2. CHECKING PROJECT HEALTH & TESTING

Before running or building, perform code quality checks and automated tests:

### Step 2.1: Code Static Analysis (`flutter analyze`)
Analyzes the codebase for syntax errors, unused imports, or lint issues:
```bash
flutter analyze
```
*Expected result: `No issues found!`*

### Step 2.2: Run Unit & Widget Tests (`flutter test`)
Executes the automated Flutter test suite:
```bash
flutter test
```
*Expected result: `All tests passed!`*

### Step 2.3: Check Connected Devices (`flutter devices`)
Lists all available target devices (Chrome, Edge, Windows, Android):
```bash
flutter devices
```

---

## 3. RUNNING THE FLUTTER APPLICATION

### 3.1 Run in Chrome (Local Debug)
Launches the app in Google Chrome with full hot-reload and Dart DevTools debugging support:
```bash
flutter run -d chrome
```
*Hot restart: Press `r` in the terminal | Quit: Press `q`*

---

### 3.2 Run on Same Wi-Fi Network (Laptop + Mobile Phone)
Allows your mobile phone and laptop to run and test the app live over your local Wi-Fi router.

#### Step 1: Find Laptop Local IPv4 Address
In PowerShell / Command Prompt, run:
```bash
ipconfig
```
Look for `Wireless LAN adapter Wi-Fi -> IPv4 Address` (e.g., `192.168.0.7`).

#### Step 2: Start Django API Server (Local Network)
In a separate terminal, navigate to the `backend` folder and run:
```bash
python manage.py runserver 0.0.0.0:8000
```

#### Step 3: Launch Flutter Web Server on Local Network
In the `finance_app` folder, run:
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

#### Step 4: Open App on Phone & Laptop
- **Laptop Browser**: Open `http://localhost:8080`
- **Phone Browser**: Open mobile Chrome/Safari and visit **`http://192.168.0.7:8080`**

---

### 3.3 Run as Windows Desktop App
Launches the app as a native Windows desktop executable:
```bash
flutter run -d windows
```

---

## 4. BUILDING THE PROJECT (PRODUCTION RELEASE)

### 4.1 Build Web Release Bundle
Compiles and minifies the Flutter app for production web deployment:
```bash
flutter build web --release
```
- **Output Bundle Location**: `finance_app/build/web/`
- **Deployment**: Upload the contents of `build/web/` to Vercel, Netlify, Firebase Hosting, or Nginx.

### 4.2 Build Android APK
Compiles an installable release APK file for Android mobile smartphones:
```bash
flutter build apk --release
```
- **Output APK Location**: `finance_app/build/app/outputs/flutter-apk/app-release.apk`
- **Installation**: Copy `app-release.apk` to any Android smartphone via USB or file transfer and tap to install!

---

## 5. TROUBLESHOOTING & PROCESS TIPS

| Issue / Symptom | Possible Cause | Resolution Process |
| :--- | :--- | :--- |
| `SocketException: errno = 10048` | Port `8080` or `8000` is already in use by a background process | Run web server on a different port: `--web-port 8081` |
| `Phone cannot load web page` | Laptop and phone are connected to different networks | Connect both phone and laptop to the **same Wi-Fi router** |
| `API Connection Refused` | `baseUrl` in `auth_service.dart` is set to `127.0.0.1` | Change `baseUrl` to laptop Wi-Fi IP (e.g. `http://192.168.0.7:8000/api/v1`) |
| `Asset not found error` | Image asset path not listed in `pubspec.yaml` | Ensure asset directory `assets/images/` is registered under `flutter -> assets:` in `pubspec.yaml` |

---
© 2026 DT7 Agency. All rights reserved.


flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080

