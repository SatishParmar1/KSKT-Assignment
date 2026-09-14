# Rider Tracking App — Flutter Mobile Application

A production-ready Flutter mobile application designed for riders to track trips from **Start Trip** to **End Trip**. The application captures and displays accurate live trip status, real-time location, total distance, current speed, and maximum speed while filtering GPS noise, tracking in the foreground and background, recovering seamlessly across app terminations, and syncing telemetry to **Firebase Cloud Firestore**.

The UI is built with a minimalist, high-contrast **white, black, and gray monochrome** dashboard designed specifically for outdoor rider legibility. The codebase follows clean, practical Flutter practices using **MultiProvider** for state management, with **zero comments in the code**.

---

## Table of Contents

1. [Overview & Objective](#overview--objective)
2. [Visuals & Firebase Database Screenshots](#visuals--firebase-database-screenshots)
3. [Firebase Cloud Firestore Architecture](#firebase-cloud-firestore-architecture)
4. [Project Structure](#project-structure)
5. [Tracking Architecture & Technical Decisions](#tracking-architecture--technical-decisions)
6. [Foreground, Background & Terminated App Tracking](#foreground-background--terminated-app-tracking)
7. [Offline Support & Synchronization](#offline-support--synchronization)
8. [Edge Cases & Testing Guide](#edge-cases--testing-guide)
9. [Setup & Run Instructions](#setup--run-instructions)

---

## Overview & Objective

The objective of this assignment is to build an accurate, robust rider tracking application that handles real-world mobile conditions (unstable GPS, network dropouts, app kills by the OS, and background execution restrictions).

### Key Highlights
- **Trip Lifecycle:** Safe Start and End actions with action debouncing and live elapsed time counter.
- **Live Location:** Continuous capture of latitude, longitude, speed, and horizontal accuracy.
- **Distance Calculation:** Accumulated distance calculated using the Haversine formula on validated coordinate fixes.
- **Speed Monitoring:** Captures current speed in km/h and records the highest valid speed achieved during the trip.
- **GPS Noise & Jump Filter:** Discards inaccurate GPS fixes, duplicate timestamps, unrealistic speed jumps, and stationary drift.
- **Background Tracking:** Continues tracking when the application is minimized or the screen is locked via Android Foreground Services and iOS Location Background Modes.
- **App Termination Recovery:** Recovers active trips seamlessly if the app is killed by the OS or the user restarts the device.
- **Offline-First Cloud Sync:** Buffers all telemetry in local storage (`SharedPreferences`) and automatically syncs to Firebase Cloud Firestore when connected.

---

## Visuals & Firebase Database Screenshots

### 1. Live Firebase Cloud Firestore Database
Below is the live Firestore console screenshot from our project showing multiple trips created and synced (`TRIP-1789200271593`, `TRIP-1789204899854`, `TRIP-1789360488938`, `TRIP-1789361209649`, `TRIP-1789361248583`, `TRIP-1789361348589`, `TRIP-1789362371731`, `TRIP-1789362717564`, `TRIP-1789362822276`), showing the trip document attributes and the nested `locations` subcollection:

![Firebase Cloud Firestore Live Database Data](assets/screenshots/firebase_db_data_image.png)

### 2. Firestore Document Fields & Telemetry Structure
As shown in the console screenshot above, each trip document contains:
- `currentSpeed`: Current rider speed (`0` km/h at stop).
- `endTime`: ISO-8601 formatted trip completion time (`"2026-09-14T10:43:58.816622"`).
- `isSynced`: Cloud synchronization status (`true`).
- `lastAccuracy`: Real-time GPS accuracy in meters (`16.25m`).
- `lastLatitude` & `lastLongitude`: Final GPS coordinate fix (`26.8830976, 75.7996287`).
- `maxSpeed`: Maximum recorded valid speed for the trip.
- `startTime`: ISO-8601 formatted trip start time (`"2026-09-14T10:43:42.276058"`).
- `status`: Lifecycle state (`"completed"` or `"active"`).
- `totalDistance`: Accumulated validated distance in meters.
- `locations`: Subcollection containing every individual accepted GPS fix with timestamp, speed, and accuracy matching the assignment payload.

---

## Firebase Cloud Firestore Architecture

The application communicates with Firebase Cloud Firestore using the official `cloud_firestore` SDK. Data is structured hierarchically into a root `trips` collection with nested `locations` subcollections.

### 1. Root Collection: `trips`
Each trip is stored as a document with the document ID matching the `tripId` (e.g. `trips/TRIP-1789204899854`).

| Field | Type | Description | Example |
|---|---|---|---|
| `tripId` | `String` | Unique trip identifier | `"TRIP-1789204899854"` |
| `startTime` | `String` (ISO 8601) | Timestamp when trip started | `"2026-09-08T10:15:23.000Z"` |
| `endTime` | `String?` (ISO 8601) | Timestamp when trip ended (null if active) | `"2026-09-08T10:35:10.000Z"` |
| `status` | `String` | Current trip state (`active`, `completed`) | `"completed"` |
| `totalDistance` | `Number` (meters) | Total validated distance travelled | `4250.8` |
| `currentSpeed` | `Number` (km/h) | Rider's current speed | `38.5` |
| `maxSpeed` | `Number` (km/h) | Highest valid speed recorded during trip | `54.2` |
| `lastLatitude` | `Number` | Last recorded latitude | `28.6139` |
| `lastLongitude` | `Number` | Last recorded longitude | `77.2090` |
| `lastAccuracy` | `Number` | Last recorded horizontal accuracy in meters | `6.5` |
| `isSynced` | `Boolean` | Sync status flag | `true` |

### 2. Nested Subcollection: `trips/{tripId}/locations`
Every validated location update during an active trip is stored under this subcollection. The document ID is the point's millisecond timestamp (e.g. `locations/1789204899950`).

```json
{
  "tripId": "TRIP-1001",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "speed": 42.5,
  "accuracy": 8.2,
  "timestamp": "2026-09-08T10:15:23.000Z"
}
```

### 3. Firestore Security Rules
To allow the mobile app to write trip data without requiring a user login screen, the following Firestore rules are applied:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## Project Structure

```
lib/
├── firebase_options.dart          # Firebase configuration generated by FlutterFire
├── main.dart                      # App entry point, Firebase init & MultiProvider setup
├── models/
│   ├── location_point.dart        # Telemetry data model matching required assignment schema
│   └── trip_model.dart            # Trip entity (status, distance, speed, points, sync state)
├── providers/
│   └── trip_provider.dart         # Core state management via ChangeNotifier (Provider)
├── services/
│   ├── connectivity_service.dart  # Network connectivity monitor via connectivity_plus
│   ├── firebase_service.dart      # Cloud Firestore integration & batch writes
│   ├── gps_filter_service.dart    # Haversine distance, speed validation & jump filter
│   ├── location_service.dart      # Geolocator stream & background notification config
│   └── storage_service.dart       # SharedPreferences persistence & offline sync queue
└── ui/
    └── trip_screen.dart           # Main rider dashboard with speedometer & controls
assets/
└── screenshots/                   # Database screenshots and visual documentation
test/
└── widget_test.dart               # Unit test suite for GPS filtering & validation
```

---

## Tracking Architecture & Technical Decisions

### 1. State Management (`MultiProvider`)
The application utilizes `MultiProvider` with `ChangeNotifierProvider<TripProvider>`. `TripProvider` is the single source of truth for:
- Current trip lifecycle states (`idle`, `active`, `completed`).
- Live metrics (current speed, max speed, total distance, elapsed duration).
- Connectivity state changes and pending queue management.
- Active trip state recovery after process termination.

### 2. GPS Filtering & Noise Reduction (`GpsFilterService`)
Raw mobile GPS chips produce noise, multipath reflections, and occasional teleportation jumps. The `GpsFilterService` enforces strict mathematical validation rules before accepting any location fix:

1. **Accuracy Threshold:**
   Discards any fix where horizontal accuracy is worse than `30.0` meters or $\le 0$ meters.
2. **Timestamp Validation:**
   Calculates $\Delta t = t_2 - t_1$. If $\Delta t \le 0$ seconds, the reading is rejected (prevents duplicate or out-of-order platform events).
3. **Haversine Distance & Derived Speed:**
   Calculates the spherical surface distance between consecutive points:
   $$a = \sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)$$
   $$d = 2R \cdot \text{atan2}\left(\sqrt{a}, \sqrt{1-a}\right)$$
   $$\text{derived speed} = \frac{\Delta d}{\Delta t} \times 3.6 \text{ (km/h)}$$
4. **Jump / Teleportation Rejection:**
   If the derived speed between consecutive fixes exceeds `130 km/h` (realistic motorcycle limit), the fix is identified as a GPS jump and discarded. Total distance is preserved and not inflated.
5. **Stationary Jitter Suppression:**
   When a rider stops at a traffic signal, GPS chips continuously drift 1–3 meters every second. If distance is $< 2.5$ meters and speed is $< 1.5\text{ km/h}$, coordinates are updated on screen for the rider, but **no distance is added** to the total distance.

---

## Foreground, Background & Terminated App Tracking

### Foreground Tracking
- Uses `Geolocator.getPositionStream` with `LocationAccuracy.high` and a 5-meter distance filter.
- UI displays real-time current speed (large digital speedometer), max speed, total distance, coordinates, and live duration.

### Background Tracking (Screen Locked / App Minimized)
- **Android:**
  - Configured with `AndroidSettings` and `ForegroundNotificationConfig`.
  - Runs an Android Foreground Service with a persistent notification (`Rider Trip Active`), preventing the operating system from suspending or killing the app when minimized or when the screen is locked.
  - Required permissions configured in `android/app/src/main/AndroidManifest.xml`:
    - `android.permission.ACCESS_FINE_LOCATION`
    - `android.permission.ACCESS_COARSE_LOCATION`
    - `android.permission.ACCESS_BACKGROUND_LOCATION`
    - `android.permission.FOREGROUND_SERVICE`
    - `android.permission.FOREGROUND_SERVICE_LOCATION`
    - `android.permission.POST_NOTIFICATIONS`
    - `android.permission.WAKE_LOCK`
- **iOS:**
  - Configured with `AppleSettings` (`pauseLocationUpdatesAutomatically: false`, `showBackgroundLocationIndicator: true`).
  - Added `UIBackgroundModes` with `location` and `fetch` to `ios/Runner/Info.plist`.
  - Configured location usage descriptions: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`.

### Terminated-App Handling & Platform Limitations

#### Implementation Strategy:
On every accepted location fix, the active trip state (`TripModel` with distance, speeds, start time, and coordinates) is immediately serialized to `SharedPreferences`.
When the application is relaunched after being killed:
1. `TripProvider.init()` checks `StorageService.getActiveTrip()`.
2. If an active trip exists, it automatically restores the trip, calculates the elapsed time from the original `startTime`, restarts the foreground location stream, and resumes tracking seamlessly.

#### Platform Limitations:
- **Android:**
  - Standard app switching or screen locking keeps tracking alive via the Foreground Service.
  - However, if the user explicitly **Force Stops** the app from Android Settings, Android forcibly terminates all foreground services.
  - Aggressive battery optimizations by specific OEMs (e.g. Xiaomi MIUI/HyperOS, Samsung OneUI, Huawei) may kill long-running background services unless the user manually grants "Unrestricted Battery" permissions.
- **iOS:**
  - When an app is swiped away / killed from the App Switcher by the user, iOS treats this as an explicit user intent to terminate execution and halts background location delivery until the user manually relaunches the app.
  - Upon app reopening, our saved state restores the active trip with all previously accumulated metrics intact.

---

## Offline Support & Synchronization

- **Local Storage Queue:** Every location point and trip state update is written to `SharedPreferences` locally before network operations.
- **Offline Mode:** If there is no internet connection, points accumulate safely in the local queue without data loss.
- **Auto-Sync:** `ConnectivityService` listens to network connectivity changes via `connectivity_plus`. When connectivity is restored, `syncPendingData()` executes:
  1. Iterates over any un-synced completed trips and saves them to Firestore using `.set(trip.toMap(), SetOptions(merge: true))`.
  2. Flushes all pending location points in batch using Firestore's atomic `writeBatch()`.
  3. Removes successfully synced points from the local queue.

---

## Edge Cases & Testing Guide

| Edge Case | Test Procedure | Expected Outcome |
|---|---|---|
| **GPS Jump / Teleportation** | On emulator, jump coordinates by 5 km in 1 second using Extended Controls > Location. | The fix is discarded as an unrealistic jump ($> 130\text{ km/h}$). Total distance is not inflated. |
| **Poor GPS Accuracy** | Inject a location point with accuracy $> 30\text{ m}$ (e.g. 60m). | The fix is rejected by `GpsFilterService`. |
| **Stationary Drift (Traffic Light)** | Keep the phone stationary on a desk for 5 minutes. | Live coordinates update, but total distance does not increase. |
| **No Internet Connection** | Turn on Airplane mode or turn off Wi-Fi/Data during a trip. | App bar indicates `Offline`. Telemetry continues recording and queues in `SharedPreferences`. |
| **Network Reconnection** | Turn Wi-Fi/Data back on after riding offline. | App bar switches to `Online`. Queued points automatically flush to Firestore via batch write. |
| **App Killed by User / OS** | Start a trip, swipe the app away from recent apps, then reopen. | Active trip is restored with its original Trip ID, distance, max speed, and elapsed time. |
| **Duplicate Button Clicks** | Rapidly tap "Start Trip" or "End Trip". | Internal `_isProcessing` flag debounces the action, preventing duplicate Firestore writes or stream collisions. |

---

## Setup & Run Instructions

### Prerequisites
- Flutter SDK (3.24.0 or above)
- Android Studio / Xcode with an emulator or physical device

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Firebase Setup
The project is configured with `firebase_core` and `cloud_firestore`:
1. Ensure your `google-services.json` is located at `android/app/google-services.json`.
2. In the **Firebase Console**, ensure **Firestore Database** is created in **Test Mode** (or update security rules to `allow read, write: if true;`).

### 3. Run the App
```bash
# Run on connected device or emulator
flutter run
```

### 4. Run Automated Tests
```bash
# Run unit tests (GPS filter, jump rejection, stationary drift tests)
flutter test

# Verify static analysis
flutter analyze
```
