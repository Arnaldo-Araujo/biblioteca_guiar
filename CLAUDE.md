# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Biblioteca Guiar — a Flutter app (Dart SDK ^3.8.1) for a church library: book catalog, reservation/loan workflow, admin dashboard, and user↔admin support chat. The backend is Firebase only (Auth, Firestore, Storage, Messaging); there is no server code in this repo. Android is the primary target (Play Store assets, launcher icons, ML Kit OCR, Android-only notification channel setup).

All UI strings, Firestore field names, status values, and most code comments are in Brazilian Portuguese. Keep new user-facing text and data fields in Portuguese to match.

## Commands

```bash
flutter pub get
flutter run                      # requires the gitignored Firebase files below
flutter analyze                  # lints: package:flutter_lints/flutter.yaml, no custom rules
flutter test                     # runs test/*_test.dart
flutter test test/widget_tests.dart                    # a single file
flutter test test/widget_tests.dart --plain-name "Login Screen renders correctly"   # a single test
flutter build appbundle          # Play Store release (signing keystore is gitignored)
dart run flutter_launcher_icons  # regenerate launcher icons from assets/icon/app_icon.png
```

### Files required to build that are not in git

`lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist` are gitignored. `main.dart` imports `firebase_options.dart`, so a fresh clone does not compile until it is generated with `flutterfire configure` (or copied in). Release keystores (`*.jks`, `*.keystore`) are also gitignored.

### State of the test suite

The tests have drifted from the code and should not be treated as a safety net until repaired:

- `test/widget_test.dart` is the untouched Flutter counter template; it does not apply to this app.
- `test/widget_tests.dart` holds the real widget tests (hand-written mocks of `AuthService`/`FirestoreService`/providers, injected via the providers' optional constructor args). Its name does not end in `_test.dart`, so a bare `flutter test` skips it — pass the path explicitly. Its mocks are stale: they pass `isAdmin:` to `UserModel` (now `role:`), use old `activateLoan`/`renewLoan` signatures, and predate the two-step registration flow.
- `integration_test/loan_flow_test.dart` runs against the real Firebase project with a hardcoded test login, and the `integration_test` dev dependency is commented out in `pubspec.yaml`.

## Architecture

### Layers

`screens/` → `providers/` (ChangeNotifier, registered in `MultiProvider` in `main.dart`) → `services/` (`AuthService`, `FirestoreService`, `StorageService`, `NotificationService` singleton) → Firebase. `models/` are plain classes with `toMap`/`fromMap`.

The layering is a convention, not enforced, and is bypassed in several places — check before assuming a single access path:

- `ChatProvider` and `DashboardProvider` talk to `FirebaseFirestore.instance` directly; there is no chat/dashboard service.
- `UserProvider` mixes `FirestoreService` calls with direct `FirebaseAuth`/`FirebaseFirestore`/`FirebaseStorage` calls (registration, `getHelpers`, permanent delete).
- Some screens instantiate `FirestoreService()` themselves (e.g. `AdminUsersListScreen`).

Lists are exposed as Firestore snapshot `Stream`s consumed with `StreamBuilder` in the screens; providers mostly hold no cached list state. `DashboardProvider` is the exception (one-shot fetch, aggregates computed client-side over all loans and books).

### Auth and navigation

`AuthWrapper` (in `main.dart`) switches between `LoginScreen` and `HomeScreen` on `authStateChanges`, deliberately without a loading state. Separately, `UserProvider` listens to the same stream and loads the Firestore `users/{uid}` doc into `userModel`; there is a window after login where the auth user exists but `userModel` is still null, so UI must null-check it. Navigation otherwise uses the named routes table in `main.dart`, plus direct `MaterialPageRoute` pushes for screens that take arguments. `rootScaffoldMessengerKey` is a global key for showing snackbars outside a screen context.

Registration is two steps: `RegisterScreen` → `UserProvider.registerAuthOnly` (creates the Auth user only) → `CompleteProfileScreen` → `UserProvider.completeRegistration` (photo upload, CPF uniqueness check, write `users/{uid}`). If the CPF already exists, the just-created Auth user is deleted as a rollback. `AuthService.signUp` is the older one-step path and is no longer the flow in use.

### Roles and multi-church tenancy (in progress)

`UserModel.role` is one of `SUPER_ADMIN`, `ADMIN`, `HELPER`, `USER`. `isAdmin` is true for both `ADMIN` and `SUPER_ADMIN`. Legacy boolean fields `isAdmin`/`isHelper` are still written by `toMap()` and are still queried (`UserProvider.getHelpers`), and `fromMap`/`fromDocument` infer `role` from them when `role` is absent — keep both representations in sync when changing role logic. Role gating happens in the UI (`AppDrawer`, screens); helpers only get "Gerenciar Empréstimos".

Users carry `estado`/`cidade`/`churchId`. The super-admin State → City → Church → users drill-down (`screens/super_admin/super_admin_flow.dart`) runs on a hardcoded `mockLocationData` map and is not yet linked from the drawer or routes. `CompleteProfileScreen` loads cities from the public IBGE API and hardcodes the only real church (`metodista_palmas`, Palmas/TO). Books, loans, and chats are not yet scoped by church. `lib/seeds/admin_seed.dart` (`seedSuperAdmin`) is a manual helper for promoting a user and is not called anywhere.

There are two parallel user-admin screen pairs: `UsersListScreen` → `UserDetailScreen` (wired to the `/users` route) and the newer `AdminUsersListScreen(churchId)` → `UserDetailDossierScreen` (reached only from the super-admin flow).

### Loan lifecycle

`loans.status` moves `reservado` → `ativo` → `devolvido`, all in `FirestoreService`:

- `reserveBook`: user creates a `reservado` loan; stock is not touched. A `permission-denied` here is surfaced as "already has active reservations", meaning that limit is enforced by Firestore security rules, which live in the Firebase console and not in this repo.
- `activateLoan`: admin/helper sets `ativo`, the due date, and decrements `books.quantidadeDisponivel` in one batch.
- `returnBook`: transaction that sets `devolvido` and increments stock.
- `renewLoan`: pushes the due date from now and increments `renovationsCount`.

"Overdue" is never stored; it is derived as `ativo` and past `dataPrevistaDevolucao`. Deleting a book is a soft delete (`isActive: false`) if any loan ever referenced it, otherwise a hard delete (`BookProvider.deleteBook`). User self-deactivation is likewise a soft delete with feedback saved to `users/{uid}/feedback_history`; permanent deletion re-authenticates, writes to `deleted_users_feedback`, and removes the photo, the user doc, and the Auth account.

### Chat

One chat room per user: `chats/{userUid}` holds inbox metadata (`lastMessage`, `unreadCount`, `assignedTo*`), with messages in `chats/{userUid}/messages`. `unreadCount` counts only user→admin messages and is reset when an admin opens the chat.

### Push notifications

`NotificationService.initialize()` (called in `main()`) requests permission and shows foreground FCM messages through a local Android notification channel. `getToken()`, which would save `users/{uid}.fcmToken`, is never called, and nothing in this repo sends pushes.

### Firestore collections

`users` (+ `feedback_history` subcollection), `books`, `loans`, `chats` (+ `messages`), `deleted_users_feedback`. Queries that combine `where('userId')` with `orderBy('dataEmprestimo')` rely on composite indexes configured in the Firebase console.

### Root-level JS files

`cloud_functions_code.js` (SUPER_ADMIN-gated church CRUD over HTTP, `churches` collection) and `backend_logic_snippet.js` (ticket auto-assignment to the least-busy helper, `tickets` collection) are reference snippets meant to be pasted into a separate Cloud Functions project. There is no `functions/` directory or `firebase.json` here, nothing in the app calls them, and the `churches`/`tickets` collections they describe are not used by the Dart code yet.

### Other tooling

`.agents/` and `antigravity.config.json` (untracked) define role-based agents for Google Antigravity; they are not used by the Flutter build.
