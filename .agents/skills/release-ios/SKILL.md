---
name: release-ios
description: Build a release (not debug) iOS binary of this app and install it straight onto a physical iPhone, so the app keeps working after the Mac is unplugged or flutter run is closed — no dependency on localhost/the dev machine at runtime. Use this whenever the user asks to "build release", "làm bản release", "cài bản release lên iPhone", wants the app to run standalone on their phone, or asks why the app breaks when they close their laptop / stop `flutter run`. Also use before handing the phone to someone else to test, since a debug build requires the Mac to stay connected.
---

# Release iOS build → physical device

Goal: produce a release `.app` built with the real cloud config, then install it directly onto the user's iPhone so nothing at runtime depends on this Mac.

Why this matters: `flutter run` (debug/profile mode) keeps a live connection to the dev machine for hot reload — closing the laptop or losing wifi/USB kills the app. A release build compiles `SUPABASE_URL` / `SUPABASE_ANON_KEY` into the binary via `--dart-define-from-file` and calls the cloud project directly, so it's fully standalone.

## Steps

### 1. Verify `env.json` points at the cloud, not localhost

`env.json` (repo root, gitignored) must contain:
```json
{
  "SUPABASE_URL": "https://iogokoqxmtnbhsuwaveg.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_..."
}
```
If `SUPABASE_URL` is `http://127.0.0.1:54321` or the file is missing, **stop** — that's the local Supabase emulator config (see `env.example.json` for the local template). Building with that baked in would make the release binary depend on the Mac running `supabase start`, which defeats the whole point. Tell the user to fix `env.json` first.

### 2. Check for undeployed edge function changes

```bash
git diff --stat -- supabase/functions/
```
Any edge function under `supabase/functions/*/index.ts` with pending local changes means the cloud project is still running older server-side logic. The release binary will call whatever is live on `iogokoqxmtnbhsuwaveg.supabase.co` regardless of what's in the local working tree, so a stale deploy silently ships a client that expects behavior the server doesn't have yet.

If there are pending changes, ask the user (don't deploy silently — deploying is a real change to shared production infra):

> "`<function-slug>` has local changes not yet deployed. Deploy it now with `supabase functions deploy <slug>` before building, or build with the current live version?"

`supabase functions list` shows deployed versions/status if you want to cross-check, but the git diff is the primary signal — a function can be ACTIVE on the cloud while still being out of date relative to the working tree.

### 3. Confirm the device and toolchain

```bash
flutter devices
flutter doctor
```
Look for the physical iPhone (not the iOS simulator — simulators can't be "unplugged" from the Mac in the way that matters here). In this project it has shown up as `Việt`, udid `00008110-001945540178801E`, but confirm from the current `flutter devices` output rather than assuming the udid never changes (re-pairing, cable, or a different phone would change it). `flutter doctor` should report Xcode + iOS toolchain with no issues.

Signing is already configured for this project — no manual setup needed: `DEVELOPMENT_TEAM = 7F5FC9KAFS`, `CODE_SIGN_STYLE = Automatic`, bundle id `com.tencuaban.nihongo` (see `ios/Runner.xcodeproj/project.pbxproj`). Current app version is in `pubspec.yaml` (`version: 0.1.0+1` at time of writing) — bump it there first if this release should carry a new version/build number.

### 4. Build the release binary

```bash
flutter build ios --release --dart-define-from-file=env.json
```
This is the step that bakes the Supabase URL/key into the compiled binary via Dart's `String.fromEnvironment` (see `lib/core/config/env.dart`). Skipping `--dart-define-from-file` produces a binary with empty config that fails `Env.assertConfigured()`.

### 5. Install to the device

```bash
flutter install --release -d <device-udid>
```
Run this plainly — don't pipe it through `tail` or otherwise truncate the output. A truncated pipe has previously hidden whether the install actually finished; you want to see the real exit code and the full "Installing... / Uninstalling old version... " sequence to confirm success.

### 6. Tell the user about the two gotchas

- **First install on this phone / after a signing change**: iOS will block the app until the user goes to *Settings → General → VPN & Device Management* and trusts the developer certificate once.
- **Free Apple Developer account**: automatic signing certs from a free account expire after ~7 days. If the app suddenly won't open, that's why — rerun this whole flow to reinstall, no code changes needed.

## Out of scope

This skill only covers shipping a release build to a directly-connected physical iPhone for the user's own testing. It does not cover App Store / TestFlight submission (needs archive + distribution certificate + App Store Connect) or Android release builds — those are separate workflows.
