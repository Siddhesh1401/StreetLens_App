# StreetLens — Copilot Context File

This file gives a new chat session full context about the StreetLens project.

---

## What is StreetLens?

A full-stack civic issue reporting platform:
- **Flutter mobile app** — citizens report urban issues (potholes, garbage, water leaks, etc.) with photo + GPS
- **Next.js admin dashboard** — municipal authorities view and resolve issues (not built yet)

---

## GitHub Repository

https://github.com/Siddhesh1401/StreetLens

```
StreetLens/
├── streetlens_app/        ← Flutter app (BUILT ✅)
└── streetlens_admin/      ← Next.js admin dashboard (NOT BUILT YET)
```

---

## Tech Stack

| Part | Technology |
|------|-----------|
| Mobile App | Flutter 3.41.1 / Dart 3.11.0 |
| Auth | Firebase Authentication (email/password only, no Google Sign-In) |
| Database | Cloud Firestore |
| Image Upload | Cloudinary (free tier, no credit card) |
| Maps | OpenStreetMap via `flutter_map` (free, no API key needed) |
| Notifications | Firebase Cloud Messaging (configured, not wired to UI yet) |

---

## Firebase Project

- **Project ID:** `streetlens-8a15c`
- **Project Number:** `238699114278`
- **Android App ID:** `1:238699114278:android:7a7fafb61d3153cbd9dbe7`
- **API Key:** `AIzaSyAW2m7x8iVTnDKr-7z791ZTs9emQ9tOX00`
- **Auth Domain:** `streetlens-8a15c.firebaseapp.com`
- **Firestore Region:** `asia-south1` (test mode)
- **Enabled:** Email/Password Auth, Firestore
- **NOT enabled:** Firebase Storage (replaced by Cloudinary)
- **Console:** https://console.firebase.google.com/project/streetlens-8a15c

---

## Cloudinary (Image Uploads)

- **Cloud Name:** `dv02anfu1`
- **Upload Preset:** `streetlens_upload` (unsigned)
- Used in: `lib/services/firestore_service.dart` → `uploadImage()`

---

## Android Config

- **Package name:** `com.streetlens.streetlens_app`
- **google-services.json** at: `android/app/google-services.json`
- **Gradle:** Kotlin DSL (`.kts` files)
- **Google Services plugin:** `4.4.2` added to `settings.gradle.kts` and `app/build.gradle.kts`
- **Permissions in AndroidManifest.xml:** Location (fine + coarse), Camera, Storage, Internet

---

## Firestore Data Structure

```
users/{userId}
  name, email, phone, role (citizen/admin), createdAt

issues/{issueId}
  user_id, user_name, image_url, category, description,
  latitude, longitude, status, upvotes, assigned_worker,
  created_at, updated_at
```

**Issue Categories:** Pothole, Garbage, Water Leak, Streetlight, Road Damage, Other

**Issue Statuses:** `Pending` → `In Progress` → `Resolved`

---

## App Screens

| Screen | File | Notes |
|--------|------|-------|
| Splash | `splash_screen.dart` | 3s animation, checks auth state |
| Login | `login_screen.dart` | Email/password only |
| Register | `register_screen.dart` | Name, email, phone, password |
| Home | `home_screen.dart` | Stats + all issues feed + FAB to report |
| Report Issue | `report_issue_screen.dart` | Photo, category, description, GPS |
| My Complaints | `my_complaints_screen.dart` | Current user's issues only |
| Complaint Detail | `complaint_detail_screen.dart` | Full issue + upvote + status timeline |
| Map | `map_screen.dart` | OpenStreetMap markers (web shows placeholder) |
| Profile | `profile_screen.dart` | User info + logout |

---

## Key Dependencies (pubspec.yaml)

```yaml
firebase_core: ^3.0.0
firebase_auth: ^5.0.0
cloud_firestore: ^5.0.0
firebase_messaging: ^15.0.0
flutter_map: ^7.0.2        # OpenStreetMap (replaces google_maps_flutter)
latlong2: ^0.9.1
geolocator: ^13.0.0
image_picker: ^1.1.2
cached_network_image: ^3.3.1
intl: ^0.19.0
uuid: ^4.4.0
```

**Removed packages:** `google_maps_flutter`, `google_sign_in`, `firebase_storage`

---

## Important Implementation Notes

### No Google Sign-In
Completely removed. Only email/password auth.

### No Firebase Storage
Replaced with Cloudinary. Image upload in `firestore_service.dart` uses HTTP multipart POST to Cloudinary.

### No Google Maps
Replaced with `flutter_map` + OpenStreetMap (100% free, no account, no API key).
- Web: shows a placeholder ("map available on mobile app")
- Android/APK: shows real interactive map with coloured markers

### Firestore Query — My Issues
`getUserIssues()` uses only `.where()` (no `.orderBy()`) to avoid needing a composite index. Sorting is done client-side in Dart.

### FAB Position
`FloatingActionButtonLocation.endFloat` — NOT centerDocked (centerDocked only works with BottomAppBar, not BottomNavigationBar).

---

## Flutter Setup

- **Flutter SDK:** `C:\flutter` (PATH added permanently)
- **Run command:** `cd "C:\Users\SIDDHESH\Desktop\StreetLens\streetlens_app"; $env:PATH += ";C:\flutter\bin"; flutter run -d chrome`
- **After any package change:** run `flutter clean` then `flutter pub get` before running

---

## What's NOT Done Yet

- [ ] Admin web dashboard (`streetlens_admin/`) — Next.js, needs to be scaffolded
- [ ] FCM push notifications — configured but not wired to UI
- [ ] Android APK build — needs Android Studio (friend has it)
- [ ] Filter/Search issues on home screen
- [ ] Comments on issues
- [ ] Admin role in mobile app (status update)
- [ ] iOS support

---

## Admin Dashboard Plan (streetlens_admin)

To be built with Next.js + Tailwind + Firebase SDK (same Firestore project).

Key pages needed:
- `/login` — admin login
- `/dashboard` — stats + issues table with filters
- `/dashboard/issues/[id]` — issue detail + status update form

Deploy to Vercel (free). Full instructions in `StreetLens/streetlens_admin/README.md`.

---

## Bugs Fixed So Far

1. `google_maps_flutter_web` stale cache error → `flutter clean` + `flutter pub get`
2. Map crash on web → skip location init with `if (!kIsWeb)`
3. My Issues empty → removed `orderBy` from Firestore query, sort client-side
4. FAB overlapping nav bar → changed to `endFloat`
5. Location not working on Android → added permissions to `AndroidManifest.xml`
6. `firestore_service.dart` missing closing brace → fixed
7. Leftover `_loginWithGoogle` in login screen → removed
