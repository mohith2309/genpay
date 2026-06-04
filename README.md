# GenPay ⚡

Your AI financial wingman — a UPI expense tracker that roasts you into saving money.

GenPay is **offline-first**: everything lives in an encrypted local Hive store and the
app is fully usable with no internet and no API keys. Add a free Gemini key to unlock
smarter, snarkier AI insights. Turn on **Privacy Mode** to disable every cloud call and
run AI on-device only.

---

## Features

- **Expense tracking** — add manually or auto-import from UPI SMS (Android).
- **SMS auto-parsing** — reads UPI messages locally, extracts merchant / amount / date,
  and queues them for one-tap batch review. Raw SMS never leaves the device.
- **AI categorization** — Google Gemini 2.0 Flash online; keyword fallback offline.
- **Insights ("Spending DNA")** — 30-day trend, weekday heatmap, AI patterns,
  duplicate-spend detection, and mood-vs-money correlation.
- **Future-self projection** — "at this rate you'll spend ₹X" + a *You vs You (if you chill)*
  comparison.
- **Budgets + autopilot** — set per-category budgets or let GenPay derive them from your
  last 3 months.
- **Micro-savings vault** — every expense rounds up to the nearest ₹10 into a virtual vault.
- **Pause / cooling-off mode** — blocks new spending for a chosen window, with a
  friction-filled override.
- **Mood tracking, silent expenses, swipe gestures, biometric lock.**
- **Privacy Mode** — flip one switch to keep all AI on-device.

## Tech stack

| Layer | Choice |
|------|--------|
| UI | Flutter 3.41.6 (Material 3, dark, brutalist-minimal) |
| State | Riverpod 2.x |
| Local storage | Hive |
| Online AI | Gemini 2.0 Flash (free tier, rate-limited + cached) |
| Charts | fl_chart |
| SMS | flutter_sms_inbox + permission_handler (Android) |
| Auth | local_auth (biometric) |

## Getting started

```bash
# 1. Install dependencies
flutter pub get

# 2. (optional) Add your Gemini key — skip to run fully offline
cp .env.example .env
#   then edit .env and set GEMINI_API_KEY=...

# 3. Run
flutter run
```

Requires Flutter **3.41.6+**. Verify your setup with `flutter doctor`.

### Gemini API key (optional)

Grab a free key at <https://ai.google.dev> and put it in `.env`. Without a key — or with
Privacy Mode on — GenPay falls back to on-device keyword categorization and locally
computed insights. The free tier is rate-limited to ~1,500 calls/day in-app, and results
are cached per-merchant to conserve quota.

## Platform notes

**Android** — SMS parsing needs the `READ_SMS` / `RECEIVE_SMS` permissions, already
declared in `android/app/src/main/AndroidManifest.xml` and requested at runtime during
onboarding. Biometric lock uses `FlutterFragmentActivity` (already wired in
`MainActivity.kt`).

**iOS** — SMS inbox access is not available on iOS, so transactions are added manually.
Face ID usage and background fetch are declared in `ios/Runner/Info.plist`.

## Architecture

```
lib/
├── main.dart            # init (Hive, dotenv) + onboarding/lock gate + bottom nav
├── core/                # theme, constants, formatting utils
├── models/              # Hive models (Transaction, Budget, Category) + plain models
├── services/            # SMS parser, Gemini, vault, pause-mode, Hive
├── providers/           # Riverpod state (transactions, budgets, insights, vault, auth)
├── screens/             # onboarding, home, insights, categories, transactions, vault, settings
└── widgets/             # transaction card, budget ring, trend graph, pause overlay, …
```

State flows one way: services own Hive I/O → providers expose reactive state → screens
watch providers. The transaction box drives everything via `box.watch()`.

## Privacy

- SMS is parsed entirely on-device; only a merchant name is ever sent to Gemini, and only
  when Privacy Mode is **off** and a key is present.
- No analytics, no data selling. "Delete all data" in Settings wipes the local store.

## Optional: cloud sync (not included)

GenPay ships local-only so it runs with zero backend setup. To add Firebase sync, add
`firebase_core` + `cloud_firestore`, run `flutterfire configure`, and mirror the
transaction box to Firestore in a new `FirebaseService`.

## Notes

- `Go Premium` is a placeholder CTA (no billing wired up).
- `flutter analyze` is clean (0 errors, 0 warnings).
