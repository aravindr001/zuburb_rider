# Zuburb Rider — Driver App

<div align="center">

**Professional ride-hailing driver platform**

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

*Premium, futuristic driver experience with real-time location tracking and ride management*

</div>

---

## 📱 Overview

Zuburb Rider is the **driver-facing mobile app** for the Zuburb ride-hailing platform. Drivers (called "Guards" in the brand) use this app to accept ride requests, navigate to customers, verify pickups, and manage their availability — all powered by Firebase with no server-side Cloud Functions.

### ✨ Key Features

- 🔐 **Phone Authentication** — Secure OTP-based Firebase Auth flow
- 🟢 **Online/Offline Toggle** — Go online to start receiving ride requests
- 📍 **Background Location Tracking** — Foreground service updates location every 10s with geohash (precision 9)
- 🔔 **Real-time Ride Requests** — Firestore-driven incoming ride detection
- 🚗 **Complete Ride Lifecycle** — Accept → Navigate → Pickup OTP → Complete
- 🗺️ **Google Maps Integration** — Turn-by-turn navigation with polyline rendering
- ⏰ **Scheduled Rides** — Accept and manage future ride bookings
- 📅 **Availability Scheduler** — Set weekly availability windows for scheduled rides
- 🔄 **Ride Persistence** — Automatically resumes active rides on app restart
- 🌙 **Dark Mode First** — Premium futuristic design language

---

## 🎨 Design Language

Zuburb Rider follows a **futuristic, dark-first aesthetic** matching the customer app:

- **Background**: `#0A0A0F` (near-black)
- **Surface**: `#12121A` (dark grey cards)
- **Primary**: `#00E5C3` (Electric Teal) — online states, CTAs
- **Secondary**: `#6C63FF` (Soft Purple) — scheduled rides
- **Danger**: `#FF4757` (Coral Red) — cancel/reject actions
- **Glassmorphism**: 16-20px blur, 5-8% white opacity, subtle borders
- **Typography**: Bold headings (700, -0.5 tracking), body (400, 0.1 tracking)
- **Animations**: 150-300ms micro-interactions, 400ms screen transitions
- **State transitions**: Crossfade animations, never hard swaps

**Special interactions:**
- **Online toggle**: Satisfying 72px button with gradient, glow, and breathing animation
- **Incoming ride**: Urgent pulsing indicator (4 concentric rings) with shimmer title
- **Navigation**: Floating glassmorphism cards over full-screen map

See design system documentation for detailed standards.

---

## 🏗️ Architecture

### State Management
**BLoC/Cubit pattern exclusively** via `flutter_bloc` — business logic separated from UI:

```
lib/
├── bloc/                    # Business logic layer
│   ├── auth/                # Phone OTP authentication
│   ├── session/             # Auth session tracking
│   ├── rider_home/          # Home screen state machine
│   ├── rider_online/        # Online/offline toggle
│   ├── incoming_ride/       # Accept/reject incoming rides
│   ├── ride_navigation/     # Active ride lifecycle
│   ├── location_permission/ # Location permission handling
│   ├── background_location/ # Background service control
│   ├── availability/        # Weekly schedule management
│   └── scheduled_rides/     # Scheduled ride list
├── presentation/            # UI layer (widgets and screens)
│   ├── screens/
│   │   ├── auth_wrapper.dart
│   │   ├── login_screen.dart
│   │   ├── otp_screen.dart
│   │   ├── home_screen.dart             # Main dashboard
│   │   ├── incoming_rider_screen.dart   # Accept/reject UI
│   │   ├── ride_navigation_screen.dart  # Active ride + map
│   │   ├── rider_availability_screen.dart # Schedule management
│   │   ├── rider_profile_setup_screen.dart
│   │   └── scheduled_rides_screen.dart
│   └── widgets/
│       ├── online_toggle.dart           # 72px gradient toggle
│       ├── pulsing_indicator.dart       # 4-ring urgent animation
│       ├── glass_card.dart              # Glassmorphism container
│       ├── primary_button.dart          # Electric Teal CTA
│       ├── secondary_button.dart        # Glass button
│       └── animated_background.dart     # Auth screen orbs
├── repository/              # Data access layer
│   ├── auth_repository.dart
│   ├── rider_repository.dart
│   ├── ride_repository.dart
│   └── directions_repository.dart
├── services/
│   └── background_location_service.dart # Foreground service isolate
├── models/                  # Data models
│   ├── rider_profile.dart
│   ├── ride.dart
│   └── availability_schedule.dart
├── platform/                # Native channel bridges
│   ├── battery_channel.dart
│   └── maps_channel.dart
└── utils/                   # Helpers
    ├── distance_calculator.dart
    └── geohash_utils.dart
```

### Key Screens

| Screen | Purpose | State Management |
|--------|---------|-----------------|
| `login_screen.dart` | Phone number entry | AuthBloc |
| `otp_screen.dart` | OTP verification | AuthBloc |
| `home_screen.dart` | Main dashboard with online toggle | RiderHomeCubit, RiderOnlineCubit |
| `incoming_rider_screen.dart` | Accept/reject incoming ride | IncomingRideCubit |
| `ride_navigation_screen.dart` | Active ride with Google Maps | RideNavigationCubit |
| `rider_availability_screen.dart` | Weekly schedule management | RiderAvailabilityCubit |
| `scheduled_rides_screen.dart` | Upcoming rides list | ScheduledRidesCubit |
| `rider_profile_setup_screen.dart` | First-time rider onboarding | - |

### Background Location Service

**Critical component**: Runs in a separate isolate as a foreground service (Android) or background task (iOS).

- **Frequency**: Updates Firestore every 10 seconds
- **Geohash**: Precision 9 (~5m accuracy) for efficient spatial queries
- **Data**: `location` (GeoPoint), `geohash` (string), `updatedAt` (Timestamp)
- **Lifecycle**: Starts when rider goes online, stops when offline
- **Initialized**: In `main()` before `runApp()`
- **Isolate**: Runs in separate isolate with independent execution context
- **Testing**: Requires physical device (unreliable in emulator)

**Implementation details:**
- Android: Foreground service with persistent notification
- iOS: Background task with location updates
- Writes to `rider_locations/{riderId}` collection
- Handles errors gracefully without crashing main app
- Requests battery optimization exemption on Android

---

## 🔥 Firebase Integration

### Collections Used

#### **riders** — Driver profile and state
```
riders/{riderId}
  - phoneNumber: string
  - name: string
  - isOnline: boolean                    # Currently online and receiving requests
  - isAvailable: boolean                 # Available for immediate rides
  - currentRideId: string | null         # ID of active ride
  - totalRides: number                   # Lifetime ride count
  - acceptsScheduledRides: boolean       # Accepts future bookings
  - scheduleTimeZone: string             # e.g. "Asia/Kolkata"
  - schedule: Map<string, List<TimeSlot>> # Weekly availability
  - createdAt: Timestamp
```

#### **rider_locations** — Real-time location data
```
rider_locations/{riderId}
  - location: GeoPoint                   # Current GPS coordinates
  - geohash: string                      # Geohash (precision 9)
  - updatedAt: Timestamp                 # Last update time
```

#### **rides** — Ride lifecycle documents
```
rides/{rideId}
  - pickup: GeoPoint                     # Pickup coordinates
  - drop: GeoPoint                       # Drop coordinates
  - pickupAddress: string                # Human-readable pickup
  - dropAddress: string                  # Human-readable drop
  - distanceKm: number                   # Trip distance
  - status: string                       # See lifecycle below
  - customerId: string                   # Customer UID
  - riderId: string | null               # Assigned rider UID
  - pickupOtp: string                    # 4-digit verification code
  - pickupOtpVerified: boolean           # OTP verification status
  - isScheduled: boolean                 # Future booking flag
  - scheduledAt: Timestamp | null        # Scheduled pickup time
  - createdAt: Timestamp
  - completedAt: Timestamp | null
```

### Ride Status Lifecycle

```
requested → accepted → arrived_pickup → picked_up → completed
         ↘ rejected
         ↘ cancelled
```

**Driver actions:**
1. **requested** → Rider sees incoming request → accepts → **accepted**
2. **accepted** → Rider navigates → marks "Arrived at Pickup" → **arrived_pickup**
3. **arrived_pickup** → Customer shares OTP → Rider verifies → **picked_up**
4. **picked_up** → Rider navigates to drop → marks "Complete Dropoff" → **completed**

**Cancellation:**
- Driver can reject from `requested` → **rejected**
- Driver/customer can cancel from `accepted` → **cancelled**

### Security Rules
**Important**: This app assumes Firestore security rules are configured externally. Riders can only:
- Read/write their own `riders/{riderId}` document
- Read/write their own `rider_locations/{riderId}` document
- Read rides where `riderId == auth.uid` or `status == 'requested'`
- Update ride status via allowed transitions

**Example rules:**
```javascript
match /riders/{riderId} {
  allow read, write: if request.auth.uid == riderId;
}

match /rider_locations/{riderId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == riderId;
}

match /rides/{rideId} {
  allow read: if request.auth != null &&
    (resource.data.riderId == request.auth.uid ||
     resource.data.customerId == request.auth.uid ||
     resource.data.status == 'requested');
  
  allow update: if request.auth.uid == resource.data.riderId &&
    request.resource.data.keys().hasAny(['status', 'pickupOtpVerified']);
}
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** `>=3.11.0`
- **Dart SDK** (bundled with Flutter)
- **Android Studio** / **Xcode** for platform builds
- **Firebase project** with Auth (Phone) and Firestore enabled
- **Google Maps API key** with Maps SDK and Directions API enabled
- **Physical Android device** (required for background location testing)

### Installation

1. **Clone the monorepo**:
   ```bash
   cd zuburb/zuburb_rider
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/google-services.json` (not committed to repo)
   - Enable **Phone Authentication** in Firebase Console → Authentication → Sign-in method
   - For testing, add test phone numbers in Firebase Console

4. **Configure Google Maps**:
   
   **Android** — Add to `android/local.properties`:
   ```properties
   MAPS_API_KEY=AIzaSy...YOUR_KEY_HERE
   ```
   
   **iOS** — Add to `ios/Runner/Info.plist`:
   ```xml
   <key>MAPS_API_KEY</key>
   <string>AIzaSy...YOUR_KEY_HERE</string>
   ```

   Or pass at runtime:
   ```bash
   flutter run --dart-define=MAPS_API_KEY=YOUR_KEY
   ```

5. **Set up Firestore collections**:
   - Create `riders`, `rider_locations`, `rides` collections in Firebase Console
   - Configure security rules (see [Security](#-security-considerations))
   - Create composite indexes if needed (Firestore will prompt)

### Running the App

```bash
# Development build
flutter run

# With inline API key
flutter run --dart-define=MAPS_API_KEY=YOUR_KEY

# Production build (Android)
flutter build apk --release

# Production build (iOS)
flutter build ios --release
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/availability_schedule_test.dart

# Analyze code (REQUIRED after every change)
flutter analyze

# Check formatting
dart format --set-exit-if-changed .
```

**Zero warnings is the bar** — run `flutter analyze` after every set of changes.

---

## 🧪 Key User Flows

### 1️⃣ **Going Online and Accepting a Ride**

```
Login → Go Online → Incoming Request → Accept → Navigate → Pickup → Complete
```

**Step-by-step:**

1. **Login** — Rider enters phone number → receives OTP → verifies
2. **Profile Check** — If first-time user, completes profile setup (name)
3. **Go Online** — Taps the large online toggle on home screen
   - Toggle animates with gradient and glow
   - Background location service starts automatically
   - Rider location updates to Firestore every 10 seconds
4. **Wait for Request** — Home screen shows "READY FOR RIDES" badge
5. **Incoming Request** — Customer books ride
   - Rider's `currentRideId` field is set in Firestore
   - App detects change and navigates to incoming ride screen
   - Urgent pulsing indicator with 4 rings appears
   - Shows pickup, drop, distance, scheduled flag
6. **Accept** — Rider taps "Accept" button
   - Ride status → `accepted`
   - Navigates to ride navigation screen
7. **Navigate to Pickup** — Full-screen map with floating controls
   - Tap "Navigate" → opens Google Maps for turn-by-turn
   - Rider drives to pickup location
8. **Arrive at Pickup** — Rider taps "Reached Pickup Location"
   - Ride status → `arrived_pickup`
   - Customer app generates 4-digit OTP
9. **Verify OTP** — Customer shares OTP verbally
   - Rider taps "Verify Pickup OTP" → enters code
   - On success: ride status → `picked_up`
10. **Navigate to Drop** — Rider drives customer to destination
    - Map automatically switches to drop location
    - Tap "Navigate" for turn-by-turn to drop
11. **Complete** — Rider taps "Complete Dropoff"
    - Ride status → `completed`
    - Returns to home screen
    - Customer rates the ride

### 2️⃣ **Managing Scheduled Rides**

```
Set Availability → Customer Books → Accept Scheduled Ride → Navigate
```

**Step-by-step:**

1. **Open Availability** — Tap drawer menu → "Availability & Schedule"
2. **Enable Scheduled Rides** — Toggle "Accept scheduled rides"
3. **Set Weekly Schedule**:
   - Select timezone (default: Asia/Kolkata)
   - For each day (Mon-Sun), add time slots
   - Example: Monday 9:00-17:00, Tuesday 9:00-17:00
   - Up to 6 slots per day supported
4. **Save** — Tap "Save" button
5. **Customer Books** — Customer schedules ride 2 days in advance
   - Ride appears in rider's "Scheduled Rides" list
   - Shows date, time, pickup, drop, distance
6. **Before Scheduled Time** — 15 minutes before `scheduledAt`
   - Ride becomes active (`currentRideId` assigned)
   - Rider sees incoming ride screen
   - "SCHEDULED RIDE" badge displayed
7. **Accept & Navigate** — Same flow as immediate ride

### 3️⃣ **Resuming an Active Ride**

```
App Restart → Auto-Resume Active Ride
```

**Scenarios:**
- App crashed during active ride
- Rider accidentally closed app
- Device restarted

**Resume flow:**

1. **Reopen App** — Rider launches app
2. **Auth Check** — User is still signed in (session persists)
3. **State Detection** — `RiderHomeCubit` reads rider profile
   - Finds `currentRideId` is not null
   - Fetches ride document from Firestore
4. **Auto-Navigate**:
   - If `status == 'accepted'` → Navigate to pickup
   - If `status == 'arrived_pickup'` → Show OTP entry
   - If `status == 'picked_up'` → Navigate to drop
5. **Resume Normal Flow** — Ride continues from current state

---

## 🔧 Native Channels

### Battery Optimization (Android)

**File:** `lib/platform/battery_channel.dart`

```dart
static const platform = MethodChannel('zuburb_rider/battery');

Future<void> requestIgnoreBatteryOptimization() async {
  await platform.invokeMethod('requestIgnoreBatteryOptimization');
}
```

**Android implementation:** `android/app/src/main/kotlin/MainActivity.kt`

**Purpose:** Opens Android system dialog to disable battery optimization for the app. This prevents the OS from killing the background location service.

**When to call:** After rider goes online for the first time.

### Google Maps Navigation

**File:** `lib/platform/maps_channel.dart`

```dart
static const platform = MethodChannel('zuburb_rider/maps');

Future<void> openMapsNavigation({
  required double destLat,
  required double destLng,
  double? originLat,
  double? originLng,
}) async {
  await platform.invokeMethod('openMapsNavigation', {
    'destLat': destLat,
    'destLng': destLng,
    'originLat': originLat,
    'originLng': originLng,
  });
}
```

**Android implementation:** `android/app/src/main/kotlin/MainActivity.kt`

**Purpose:** Launches native Google Maps app with turn-by-turn navigation.

**When to call:** When rider taps "Navigate" button during active ride.

---

## 🔑 Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `MAPS_API_KEY` | Yes | Google Maps API key for Android/iOS | `AIzaSyB...` |

**Note:** Firebase config is handled via `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).

**Security:**
- Never commit API keys to repository
- Use `android/local.properties` (already in `.gitignore`)
- Restrict API key by package name in Google Cloud Console

---

## 📦 Dependencies

### Core
- `flutter_bloc` ^9.1.1 — State management (BLoC/Cubit pattern)
- `firebase_core` ^4.4.0 — Firebase initialization
- `firebase_auth` ^6.1.4 — Phone OTP authentication
- `cloud_firestore` ^6.1.2 — Real-time database
- `firebase_messaging` ^16.1.1 — Push notifications

### Maps & Location
- `google_maps_flutter` ^2.6.1 — Interactive maps
- `geolocator` ^13.0.2 — Device location
- `dart_geohash` ^2.1.0 — Geospatial queries
- `http` ^1.2.2 — Google Directions API

### Background Service
- `flutter_background_service` ^5.0.5 — Foreground service (Android/iOS)
- `flutter_local_notifications` ^18.0.0 — Local push notifications
- `permission_handler` ^11.3.1 — Permission requests

### UI & Animation
- `flutter_animate` ^4.5.0 — Declarative animations
- `shimmer` ^3.0.0 — Loading effects
- `intl` ^0.20.2 — Date/time formatting
- `timezone` ^0.10.0 — Timezone handling
- `url_launcher` ^6.3.2 — Open external links
- `shared_preferences` ^2.5.4 — Local storage

### Development
- `flutter_lints` ^6.0.0 — Recommended lints
- `flutter_test` — Unit testing

See [`pubspec.yaml`](./pubspec.yaml) for complete list.

---

## 🔒 Security Considerations

### Firestore Security Rules

**Riders can:**
- ✅ Read/write their own `riders/{riderId}` document
- ✅ Read/write their own `rider_locations/{riderId}` document
- ✅ Read rides where `riderId == auth.uid` or `status == 'requested'` (for discovery)
- ✅ Update ride status via allowed transitions (accept, arrive, pickup, complete)

**Riders cannot:**
- ❌ Read other riders' profiles or locations
- ❌ Modify ride data outside of status transitions
- ❌ Delete rides
- ❌ Read customer personal data (except what's in ride document)

**Example production rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /riders/{riderId} {
      allow read, write: if request.auth.uid == riderId;
    }
    
    match /rider_locations/{riderId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == riderId;
    }
    
    match /rides/{rideId} {
      allow read: if request.auth != null &&
        (resource.data.riderId == request.auth.uid ||
         resource.data.customerId == request.auth.uid ||
         resource.data.status == 'requested');
      
      allow create: if false; // Only customers create rides
      
      allow update: if request.auth.uid == resource.data.riderId &&
        (
          // Accept ride
          (resource.data.status == 'requested' &&
           request.resource.data.status == 'accepted' &&
           request.resource.data.riderId == request.auth.uid) ||
          
          // Arrive at pickup
          (resource.data.status == 'accepted' &&
           request.resource.data.status == 'arrived_pickup') ||
          
          // Verify OTP
          (resource.data.status == 'arrived_pickup' &&
           request.resource.data.pickupOtpVerified == true) ||
          
          // Mark picked up
          (resource.data.status == 'arrived_pickup' &&
           resource.data.pickupOtpVerified == true &&
           request.resource.data.status == 'picked_up') ||
          
          // Complete ride
          (resource.data.status == 'picked_up' &&
           request.resource.data.status == 'completed') ||
          
          // Cancel ride
          (request.resource.data.status == 'cancelled')
        );
      
      allow delete: if false; // Never delete rides
    }
  }
}
```

### Additional Security
- ✅ Phone OTP via Firebase Auth (automatic spam protection)
- ✅ API keys are **not** committed to repository
- ✅ Background location only updates when rider is online
- ✅ OTP verification prevents unauthorized pickups
- ✅ Production builds use ProGuard (Android) and obfuscation (iOS)
- ⚠️ No rate limiting on ride acceptance (implement server-side if needed)
- ⚠️ Google Maps API key should be restricted by package name/bundle ID

---

## 🐛 Common Issues

### Background location not updating
**Symptoms:**
- Rider goes online but location not visible to customers
- `rider_locations` document not updating in Firestore

**Causes & Fixes:**
1. **Battery optimization enabled**
   - Call `requestIgnoreBatteryOptimization()` after first online toggle
   - Manual: Settings → Apps → Zuburb Rider → Battery → Unrestricted

2. **Location permissions not granted**
   - Android: Must grant "Allow all the time" for background location
   - iOS: Must grant "Always" location permission
   - Check: Settings → Apps → Zuburb Rider → Permissions → Location

3. **Background service not started**
   - Ensure `initializeService()` is called in `main()` before `runApp()`
   - Check logcat for service initialization errors

4. **Firestore write errors**
   - Check Firestore security rules allow writes to `rider_locations/{riderId}`
   - Background service isolate errors won't crash main app — check logs

**Debug steps:**
```bash
# View Android logs
flutter logs

# Filter for background service
adb logcat | grep "BackgroundLocationService"

# Check Firestore writes
# Firebase Console → Firestore → rider_locations → {your_uid}
```

### Maps not showing
**Symptoms:**
- Blank map on ride navigation screen
- "Google Maps not available" error

**Causes & Fixes:**
1. **API key not configured**
   - Add `MAPS_API_KEY` to `android/local.properties`
   - Or pass via `--dart-define=MAPS_API_KEY=YOUR_KEY`

2. **API key restrictions**
   - Google Cloud Console → APIs & Services → Credentials
   - Ensure API key has Maps SDK for Android/iOS enabled
   - Check package name restrictions match `com.example.zuburb_rider`

3. **Internet permission missing**
   - Check `AndroidManifest.xml` has `INTERNET` permission

### Ride requests not appearing
**Symptoms:**
- Rider is online but no incoming ride requests
- Customer sees "No riders available"

**Causes & Fixes:**
1. **Rider not online**
   - Ensure `isOnline == true` in `riders/{riderId}` document
   - Toggle off and back on

2. **Geohash radius too small**
   - Customer searches with geohash precision 6 (~5km radius)
   - Check rider's `geohash` in `rider_locations` matches area

3. **Firestore listener not working**
   - `RiderHomeCubit` watches `riders/{riderId}` for `currentRideId` changes
   - Check Firebase Console → Authentication → ensure phone auth enabled

4. **Current ride not cleared**
   - If previous ride ended abnormally, `currentRideId` might still be set
   - Manually clear in Firestore: `riders/{riderId}.currentRideId = null`

### App crashes on startup
**Symptoms:**
- App crashes immediately after splash screen
- Red error screen on launch

**Causes & Fixes:**
1. **Background service not initialized**
   - Ensure `main()` calls `initializeService()` before `runApp()`
   - Check `lib/main.dart` initialization order

2. **Firebase not initialized**
   - Ensure `google-services.json` exists in `android/app/`
   - Run `flutter clean` and rebuild

3. **Null safety errors**
   - Check Dart SDK version `>=3.11.0`
   - Run `flutter pub get` to refresh dependencies

### OTP verification fails
**Symptoms:**
- Rider enters correct OTP but verification fails
- "Invalid OTP" error shown

**Causes & Fixes:**
1. **OTP mismatch**
   - Ensure customer is reading correct OTP from their screen
   - OTP is 4 digits, case-sensitive

2. **Firestore write delay**
   - Customer app writes OTP to ride document
   - Wait 1-2 seconds after customer sees OTP before asking rider to enter

3. **Ride status incorrect**
   - OTP verification only works when `status == 'arrived_pickup'`
   - Check Firestore ride document status

4. **Network delay**
   - Poor connectivity can delay Firestore writes
   - Retry after a few seconds

---

## 📱 Permissions

### Android

Declared in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Background service permissions -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<!-- Notification permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Battery optimization -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

<!-- Internet (required for maps) -->
<uses-permission android:name="android.permission.INTERNET" />
```

**Runtime permissions requested:**
- Location (when in use) — On first launch
- Location (always) — When rider goes online
- Notifications — For ride request alerts
- Battery optimization — For background service reliability

### iOS

Declared in `ios/Runner/Info.plist`:

```xml
<!-- Location when in use -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby customers and navigate to pickups</string>

<!-- Background location -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need background location to update your position while you're online</string>

<!-- Location always -->
<key>NSLocationAlwaysUsageDescription</key>
<string>We need background location to update your position while you're online</string>

<!-- Background modes -->
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>fetch</string>
</array>
```

**Permission flow:**
1. App launch → requests "When In Use" location
2. Go online → requests "Always" location (background)
3. iOS shows system dialog with location permission options

---

## 📝 Development Workflow

### After Every Change Set

```bash
# 1. Analyze code (zero warnings required)
flutter analyze

# 2. Format code
dart format lib/

# 3. Run tests
flutter test

# 4. Test on physical device
flutter run

# 5. Verify via screen mirroring
scrcpy  # or similar tool
```

### Before Committing

```bash
# Ensure no API keys in code
git diff | grep -i "AIza"  # Should return nothing

# Check gitignore
cat .gitignore | grep "local.properties"  # Should exist
cat .gitignore | grep "google-services.json"  # Should exist

# Run final analysis
flutter analyze  # Must show 0 errors
```

### Firestore Schema Changes

**Important**: Coordinate changes with the customer app (`zuburb_ride`).

1. **Plan schema change** — Document in project notes
2. **Update both apps**:
   - Models: `lib/models/`
   - Repositories: `lib/repository/`
   - BLoCs: Update state classes if needed
3. **Update security rules** in Firebase Console
4. **Test end-to-end**:
   - Customer books ride → Rider receives → Accepts → Completes
   - Test scheduled rides
   - Test cancellation flows
5. **Deploy Firestore indexes** if prompted
6. **Update documentation** with schema changes

### Release Checklist

Before releasing to production:

- [ ] Run `flutter analyze` — 0 errors
- [ ] Run `flutter test` — all tests pass
- [ ] Test on multiple physical devices
- [ ] Test background location service overnight
- [ ] Test with poor network conditions
- [ ] Verify battery optimization is disabled
- [ ] Test complete ride flow end-to-end
- [ ] Test scheduled ride flow
- [ ] Verify OTP verification works
- [ ] Check Firebase quotas and billing
- [ ] Review Firestore security rules
- [ ] Restrict Google Maps API key by package name
- [ ] Update version in `pubspec.yaml`
- [ ] Tag release in version control

---

## 📄 License

Private and proprietary. All rights reserved.

---

## 🔗 Related

- [Zuburb Ride App](../zuburb_ride/) — Customer-facing app
- [Monorepo Documentation](../CLAUDE.md) — Development standards and guidelines
- [Design System](../.claude/skills/) — UI/UX design specifications

---

<div align="center">

**Built with Flutter and Firebase**

*Zero Cloud Functions. Zero Backend. Pure Client-Side Power.*

</div>
