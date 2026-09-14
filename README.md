# Rider Tracking App

A Flutter application for riders to track trips from start to finish. It tracks distance, live speed, maximum speed, and coordinates while handling GPS noise, background tracking, offline syncing, and app restarts.

---

## Setup & Run

### Prerequisites
- Flutter SDK (3.24.0 or above)
- Android Studio or Xcode (with an emulator or real device)

### Steps
1. Get dependencies:
   ```bash
   flutter pub get
   ```
2. (Optional) Setup Firebase:
   - Add your `google-services.json` inside `android/app/` (for Android) and `GoogleService-Info.plist` inside `ios/Runner/` (for iOS).
   - If you run the app without Firebase files, it automatically works in local offline mode without crashing.
3. Run the app:
   ```bash
   flutter run
   ```
4. Run tests:
   ```bash
   flutter test
   ```

---

## Project Structure

```
lib/
├── main.dart
├── models/
│   ├── location_point.dart
│   └── trip_model.dart
├── providers/
│   └── trip_provider.dart
├── services/
│   ├── connectivity_service.dart
│   ├── firebase_service.dart
│   ├── gps_filter_service.dart
│   ├── location_service.dart
│   └── storage_service.dart
└── ui/
    └── trip_screen.dart
```

---

## Tracking Architecture & Technical Decisions

- **State Management:** Uses `Provider` (`ChangeNotifier`). `TripProvider` manages the trip state, starts and stops location streams, updates the timer, and handles local and cloud syncing.
- **GPS Noise & Jump Filter (`GpsFilterService`):**
  - **Accuracy Filter:** Discards fixes with accuracy worse than 30 meters.
  - **Timestamp Check:** Ensures incoming points have a positive time difference from the previous point.
  - **Haversine Distance & Jump Rejection:** Calculates distance using the Haversine formula. If the calculated speed between two consecutive points exceeds 130 km/h, the point is treated as a GPS jump and discarded.
  - **Stationary Jitter Suppression:** When standing still (speed < 1.5 km/h and distance < 2.5 meters), the app updates coordinates but does not add distance. This avoids artificial distance accumulation at traffic lights.
- **Offline Support & Backend:**
  - Every valid location point is saved locally in `SharedPreferences`.
  - If connected to the internet and Firebase is set up, points are uploaded to Firebase Realtime Database under `trips/{tripId}/locations/{timestamp}`.
  - When offline, points wait in the local queue. Once the network reconnects, `TripProvider` flushes queued points to Firebase.

---

## Foreground, Background & Terminated Tracking

### Foreground Tracking
- Tracks continuously via `Geolocator.getPositionStream` with high accuracy and a 5-meter distance filter.
- UI updates distance, current speed, max speed, and live coordinates in real time.

### Background Tracking
- **Android:**
  - Configured with a Foreground Service via `AndroidSettings` with `ForegroundNotificationConfig`.
  - Displays a persistent notification while tracking is active so Android keeps the location stream running when the app is minimized or the screen is locked.
  - Configured with `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, and `POST_NOTIFICATIONS` in `AndroidManifest.xml`.
- **iOS:**
  - Configured with `AppleSettings` (`pauseLocationUpdatesAutomatically: false`, `showBackgroundLocationIndicator: true`).
  - `UIBackgroundModes` with `location` and `fetch` set in `Info.plist`.

### Terminated-App Handling & Limitations
- **How it is handled:**
  - Active trip state is saved to `SharedPreferences` on every location update.
  - When the app is launched again after being killed or after a phone reboot, `TripProvider.init()` checks for an active trip.
  - If found, it automatically restores the trip, recalculates elapsed time from the original start time, and resumes the location stream.
- **Platform Limitations:**
  - **Android:** If the user goes to Android Settings and taps "Force Stop", Android kills all foreground services and background execution. Some OEM skins (MIUI, ColorOS) have aggressive battery managers that can kill background services unless battery optimization is disabled for the app.
  - **iOS:** When a user explicitly force-quits an app from the App Switcher, iOS halts background location delivery completely until the user opens the app again. Once reopened, our saved state restores the active trip.

---

## Testing Major Edge Cases

1. **GPS Jumps / Unrealistic Speed:**
   - On an emulator, use the Extended Controls > Location tab to jump coordinates by several kilometers in 1 second.
   - The app's filter calculates the derived speed (> 130 km/h) and discards the reading without adding false distance.
2. **Offline Mode & Reconnection:**
   - Turn on Airplane mode or turn off Wi-Fi/Mobile Data while a trip is active.
   - The status bar changes to "Offline". Points are stored in local storage.
   - Turn Wi-Fi/Data back on. The status changes to "Online" and queued points are uploaded to Firebase.
3. **App Killed / Device Reboot:**
   - Start a trip.
   - Swipe away the app from recent apps (or kill the process in Android Studio / Terminal).
   - Reopen the app. The trip is restored in progress with the original trip ID, distance, and elapsed time.
4. **Stationary GPS Drift:**
   - Keep the phone stationary on a table or test at 0 km/h in emulator.
   - Minor GPS coordinate jitter does not inflate the total distance travelled.
5. **Duplicate Button Clicks:**
   - Tapping "Start Trip" or "End Trip" repeatedly is blocked by an internal `isProcessing` flag to prevent duplicate trips or concurrent network requests.
