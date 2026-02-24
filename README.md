# Zuburb Rider

A Flutter-based rider app for the Zuburb ride-hailing platform. Riders use this app to go online, receive ride requests, navigate to pickup/drop locations, and manage their active rides — all powered by Firebase.

## Features

- **Phone Auth** — Firebase Authentication with OTP-based phone login
- **Online/Offline Toggle** — Riders go online to start receiving ride requests; location tracking activates automatically
- **Background Location Tracking** — Foreground service updates the rider's location to Firestore every 10 seconds with geohash (precision 9) while online
- **Real-time Ride Requests** — Firestore-driven incoming ride detection via `currentRideId` on the rider profile
- **Ride Lifecycle** — Accept → Arrive at Pickup → Verify OTP → Pick Up → Complete Drop-off, with cancellation/rejection support
- **Ride Persistence** — Automatically resumes an active ride on app restart
- **Local Notifications** — Ride request notifications via `flutter_local_notifications` (no Cloud Functions required)
- **Google Maps Navigation** — Turn-by-turn directions from pickup to drop using Google Maps with polyline rendering

## Architecture

```
lib/
├── main.dart                    # App entry point, Firebase init, providers
├── bloc/                        # BLoC / Cubit state management
│   ├── auth/                    # Phone auth (send OTP, verify)
│   ├── session/                 # Auth session tracking (signed in/out)
│   ├── rider_home/              # Home screen state (waiting, incoming, active)
│   ├── rider_online/            # Online/offline toggle
│   ├── incoming_ride/           # Incoming ride accept/reject
│   ├── ride_navigation/         # Active ride lifecycle
│   ├── pickup_otp/              # OTP verification at pickup
│   ├── location_permission/     # Location permission handling
│   └── background_location/     # Background service control
├── models/
│   ├── rider_profile.dart       # Rider Firestore document model
│   └── ride.dart                # Ride Firestore document model
├── repository/
│   ├── auth_repository.dart     # Firebase Auth operations
│   ├── rider_repository.dart    # Rider profile & location Firestore ops
│   ├── ride_repository.dart     # Ride lifecycle Firestore ops
│   └── directions_repository.dart # Google Directions API
├── services/
│   └── background_location_service.dart # Foreground service (Android/iOS)
├── presentation/
│   ├── screens/
│   │   ├── auth_wrapper.dart          # Auth routing
│   │   ├── login_screen.dart          # Phone number input
│   │   ├── otp_screen.dart            # OTP verification
│   │   ├── home_screen.dart           # Rider dashboard
│   │   ├── incoming_rider_screen.dart # Accept/reject incoming ride
│   │   └── ride_navigation_screen.dart # Active ride with map
│   └── widgets/
├── utils/
│   ├── maps_launcher.dart       # Native map app launcher
│   └── polyline_codec.dart      # Google polyline decoder
└── config/
```

**State Management:** BLoC/Cubit pattern via `flutter_bloc`

**Backend:** Firebase (Auth, Firestore) — no Cloud Functions, all logic runs client-side or in the background service isolate

## Firestore Collections

| Collection | Document ID | Key Fields |
|---|---|---|
| `riders` | rider UID | `isOnline`, `isAvailable`, `currentRideId`, `totalRides` |
| `rider_locations` | rider UID | `location` (GeoPoint), `geohash`, `updatedAt` |
| `rides` | auto-generated | `pickup`, `drop`, `distanceKm`, `status`, `riderId`, `pickupOtp`, `pickupOtpVerified` |

### Ride Status Flow

```
requested → accepted → arrived_pickup → picked_up → completed
                ↘ rejected
                ↘ cancelled
```

## Tech Stack

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.4.0 | Firebase initialization |
| `firebase_auth` | ^6.1.4 | Phone authentication |
| `cloud_firestore` | ^6.1.2 | Real-time database |
| `flutter_bloc` | ^9.1.1 | State management |
| `google_maps_flutter` | ^2.6.1 | Map rendering |
| `geolocator` | ^13.0.2 | GPS location |
| `dart_geohash` | ^2.1.0 | Geohash encoding |
| `flutter_background_service` | ^5.0.5 | Android foreground service |
| `flutter_local_notifications` | ^18.0.0 | Local push notifications |
| `url_launcher` | ^6.3.2 | External map app launch |

## Getting Started

### Prerequisites

- Flutter SDK ^3.11.0
- Firebase project with Auth (Phone) and Firestore enabled
- Google Maps API key (Android & iOS)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/aravindr001/zuburb_rider.git
   cd zuburb_rider
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase configuration**
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`
   - Enable **Phone Authentication** in Firebase Console
   - Create the Firestore collections (`riders`, `rider_locations`, `rides`)

4. **Google Maps API key**
   - Add your API key to `android/app/src/main/AndroidManifest.xml`
   - Add your API key to `ios/Runner/AppDelegate.swift`

5. **Run**
   ```bash
   flutter run
   ```

## Permissions

### Android
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — GPS tracking
- `ACCESS_BACKGROUND_LOCATION` — Background location updates
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION` — Foreground service
- `POST_NOTIFICATIONS` — Local notifications
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — Keep background service alive

### iOS
- Location When In Use / Always
- Background Modes: Location Updates, Background Fetch

## Native Channels

| Channel | Method | Purpose |
|---|---|---|
| `zuburb_rider/battery` | `requestIgnoreBatteryOptimization` | Disable battery optimization dialog |
| `zuburb_rider/maps` | `openMapsNavigation` | Launch native Google Maps navigation |

## License

Private project — not licensed for public use.
