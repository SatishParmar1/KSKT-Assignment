# Rider Tracking App

A Flutter mobile application designed for riders to track trips from Start Trip to End Trip. It captures and displays real-time trip status, live coordinates, total distance, current speed, and maximum speed while filtering GPS noise, handling offline scenarios, syncing with Firebase Cloud Firestore, and recovering active trips across app terminations.

---

## Features

- **Trip Lifecycle:** Start and End trip actions with debounced safety and live elapsed duration counter.
- **Live Location:** Real-time latitude and longitude tracking.
- **Distance Calculation:** Accumulated distance calculated using the Haversine formula on validated coordinate fixes.
- **Speed Tracking:** Real-time current speed in km/h and maximum speed tracking.
- **Noise & Jump Filtering:** Rejection of unrealistic coordinate spikes, duplicate timestamps, poor accuracy fixes, and stationary GPS jitter.
- **Foreground & Background Tracking:** Android Foreground Service with persistent notification and iOS background location modes.
- **Terminated-App Recovery:** Active trip state is continuously stored in local storage and seamlessly restored upon relaunch if the app is killed by the OS or the user.
- **Offline First & Firebase Backend:** Trip metadata and location telemetry are queued locally when offline and automatically synced to Cloud Firestore when connectivity is restored.
- **Monochrome Minimalist UI:** Clean white, black, and gray high-contrast rider dashboard designed for outdoor visibility.
- **Built-in Simulation & Test Tools:** Interactive panel to test GPS jumps, accuracy drops, stationary stops, and offline sync directly on emulators without leaving your desk.

---

## Project Structure

```
lib/
├── main.dart                      # App entry point, Firebase init & Provider configuration
├── models/
│   ├── location_point.dart        # Telemetry data model matching required assignment schema
│   └── trip_model.dart            # Trip entity (status, distance, speed, points, sync state)
├── providers/
│   └── trip_provider.dart         # Core state management via ChangeNotifier (Provider)
├── services/
│   ├── connectivity_service.dart  # Network connectivity monitor
│   ├── firebase_service.dart      # Cloud Firestore integration & batch sync
│   ├── gps_filter_service.dart    # Haversine distance, speed validation & jump filter
│   ├── location_service.dart      # Geolocator stream & background notification config
│   └── storage_service.dart       # SharedPreferences persistence & offline sync queue
└── ui/
    ├── screens/
    │   ├── trip_history_screen.dart # History of completed trips
    │   └── trip_screen.dart         # Main rider dashboard
    └── widgets/
        ├── metric_card.dart         # Reusable monochrome metric display card
        ├── recovery_banner.dart     # Interrupted trip recovery notice
        ├── simulation_sheet.dart    # Test modal for simulating edge cases
        └── status_badge.dart        # Status pills (Online, Offline, Live, Queued)
```

---

## Setup and Run Instructions

### Prerequisites
- Flutter SDK (version 3.24.0 or higher)
- Dart SDK (version 3.5.0 or higher)
- Android Studio / Xcode for running on emulators or physical devices

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Firebase Configuration
The application is built to use **Firebase Cloud Firestore** for backend persistence:
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
2. Enable **Cloud Firestore** in test or production mode.
3. Configure your app using the FlutterFire CLI:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Or place `google-services.json` inside `android/app/` and `GoogleService-Info.plist` inside `ios/Runner/`.

> **Offline/Local Mode Fallback:** If Firebase configuration files are omitted during evaluation, the app automatically operates in local mode without crashing. All metrics, active trips, and history will persist locally in `SharedPreferences`, and points will queue for sync.

### 3. Run the App
```bash
# Run on connected device or emulator
flutter run

# Run unit tests
flutter test

# Verify code analysis
flutter analyze
```

---

## Tracking Architecture & Key Technical Decisions

### 1. State Management (Provider)
The application utilizes `ChangeNotifier` with `Provider`. `TripProvider` acts as the single source of truth for:
- Current trip lifecycle states (`idle`, `active`, `completed`).
- Live metrics (current speed, max speed, total distance, elapsed duration).
- Connectivity state changes and pending queue management.
- Active trip state recovery after process termination.

### 2. GPS Filtering & Noise Reduction (`GpsFilterService`)
Raw GPS data on mobile devices can produce spikes, inaccurate fixes, and stationary drift. The `GpsFilterService` enforces the following rules before accepting any location fix:
1. **Accuracy Threshold:** Discards any location fix with horizontal accuracy $> 30.0$ meters or $\le 0$ meters.
2. **Timestamp Validation:** Rejects fixes where $dt \le 0$ seconds to prevent backward or duplicate time events.
3. **Haversine Distance & Derived Speed:** Calculates distance between consecutive points via the spherical Haversine formula. Derived speed is calculated as:
   $$\text{speed} = \frac{\Delta d}{\Delta t} \times 3.6 \text{ (km/h)}$$
4. **Jump Rejection:** If the derived speed exceeds $130\text{ km/h}$ (or if raw GPS speed exceeds realistic limits), the fix is rejected as a coordinate spike. The rejected count is recorded in telemetry.
5. **Stationary Drift Suppression:** When waiting at traffic signals, GPS chips often report random 1-2 meter jumps. If distance is $< 2.5$ meters and speed is $< 1.5\text{ km/h}$, the location is accepted to update live coordinates, but **distance is not added** to the trip total.

### 3. Offline Support & Synchronization
- When an accepted location is captured, it is packaged as a `LocationPoint` and appended to a persistent pending list in `SharedPreferences`.
- If the device is online and Firebase is accessible, the point is uploaded directly to Firestore:
  `trips/{tripId}/locations/{timestamp}`
- If offline, points accumulate in the local queue.
- `ConnectivityService` listens to network changes. Upon reconnection, `syncPendingData()` uploads queued points in batches using Firestore's `writeBatch()`.

---

## Foreground, Background & Terminated Tracking

### Foreground Tracking
- Uses `Geolocator.getPositionStream` with high accuracy and a 5-meter distance filter.
- UI displays real-time speed, distance, coordinates, and live duration.

### Background Tracking
- **Android:**
  - Configured with `AndroidSettings` and `ForegroundNotificationConfig`.
  - Runs a foreground service with a persistent notification (`Rider Trip Active`), preventing the OS from killing the location listener when the app is minimized or the screen is locked.
  - Required permissions added to `AndroidManifest.xml`:
    `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `WAKE_LOCK`.
- **iOS:**
  - Configured with `AppleSettings` (`pauseLocationUpdatesAutomatically: false`, `showBackgroundLocationIndicator: true`).
  - Added `UIBackgroundModes` with `location` and `fetch` to `Info.plist`.
  - Added location usage strings: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`.

### Terminated-App Handling & Platform Limitations

#### Implementation Approach:
Whenever a valid location update occurs, the full active trip state (`TripModel` with total distance, speeds, start time, and point count) is serialized to `SharedPreferences`.
When the application re-launches:
1. `TripProvider.init()` inspects `StorageService.getActiveTrip()`.
2. If an active trip exists, it automatically restores the trip state, calculates the elapsed time from the original `startTime`, restarts the foreground location stream, and presents a dismissible recovery banner to the rider.

#### Platform Limitations:
- **Android:**
  - Standard app switching or screen locking keeps tracking active via the Foreground Service.
  - However, if the user explicitly **Force Stops** the app from Android Settings, all foreground services are killed by the OS.
  - Aggressive battery optimizations by specific OEMs (e.g., Xiaomi MIUI/HyperOS, Samsung OneUI, Huawei) may kill long-running foreground services unless the user manually grants "Unrestricted Battery" permissions.
- **iOS:**
  - When an app is swiped away / killed from the App Switcher by the user, iOS treats this as an explicit intent to stop and terminates background tasks. Location events will not be delivered until the user opens the app again.
  - In our architecture, as soon as the rider reopens the app, the session is recovered with all previously accumulated metrics intact.

---

## Edge Cases & Testing Instructions

You can test all critical edge cases directly using the built-in **Simulation & Test Tools** button in the app, or with emulator settings:

### 1. GPS Jump / Unrealistic Spike
- **Action:** Tap "Simulation & Test Tools" > "Simulate GPS Jump Spike (+5km instant)".
- **Expected Result:** The spike is rejected. The "Jumps Rejected" counter increases by 1, distance does not jump, and the telemetry box shows the rejection reason.

### 2. Poor GPS Accuracy
- **Action:** Tap "Simulation & Test Tools" > "Simulate Poor Accuracy Reading (75m)".
- **Expected Result:** The fix is rejected because accuracy exceeds 30m. The rejection counter increments.

### 3. Stationary GPS Drift
- **Action:** Tap "Simulation & Test Tools" > "Simulate Stationary Drift (Signal Stop)".
- **Expected Result:** Live coordinates update, but total distance does not increase.

### 4. Offline Mode & Auto-Sync
- **Action:** Toggle Wi-Fi / Mobile Data off or use airplane mode. The app bar will display `OFFLINE`.
- Accumulate points by riding or tapping "Simulate Valid Movement". A badge will show `N QUEUED`.
- Turn Wi-Fi / Mobile Data back on. The app bar will switch to `ONLINE` and flush the queued points to Firebase Firestore automatically.

### 5. App Process Termination / Crash Recovery
- **Action:** Start a trip, let it track for a few seconds.
- Force kill the app (swipe away from recent apps or kill process via terminal/debugger).
- Reopen the app.
- **Expected Result:** The active trip is restored with its original Trip ID, accumulated distance, max speed, and elapsed time. A recovery banner appears: *"Active trip recovered from previous session. Tracking resumed."*

### 6. Duplicate Submission Protection
- **Action:** Rapidly tap the "START TRIP" or "END TRIP" buttons.
- **Expected Result:** Button debouncing (`isProcessing` flag) prevents duplicate trip creations or concurrent Firestore write collisions.
