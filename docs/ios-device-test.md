# iOS Device Test

This project is prepared for a local iOS device test through Godot and Xcode.

## Current Preset

- Preset: `iOS`
- App name: `Jade Bow Arrow`
- Bundle ID: `com.stoner609.jadebowarrow`
- Version: `0.1.0`
- Build: `1`
- Export path: `exports/ios/JadeBowArrow.xcodeproj`

## Requirements

- Full Xcode installed from the Mac App Store.
- Godot 4.5.1 export templates installed.
- An Apple Account signed in to Xcode.
- An iPhone connected by USB or trusted for wireless development.

## Xcode Setup

The current machine has Xcode installed, but the active developer directory may still point to Command Line Tools. If `xcodebuild -version` reports Command Line Tools, switch to full Xcode:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Then open Xcode once and accept any license or component install prompts.

## Team ID

Godot's iOS exporter requires `application/app_store_team_id`.

You can find it after signing in to Xcode or Apple Developer:

- Xcode: Settings > Accounts > select your Apple Account > Team details.
- Apple Developer account: Membership details > Team ID.

For free local device testing, you can use your personal development team in Xcode. TestFlight and App Store distribution require Apple Developer Program membership.

After finding the 10-character Team ID, set this in `export_presets.cfg`:

```cfg
application/app_store_team_id="YOURTEAMID"
```

## Export From Godot

Use the Godot editor:

```text
Project > Export > iOS > Export Project
```

Export to:

```text
exports/ios/JadeBowArrow.xcodeproj
```

The `exports/` folder is ignored by git.

## Run On iPhone

1. Open the exported `.xcodeproj` in Xcode.
2. Select the app target.
3. Go to `Signing & Capabilities`.
4. Select your Apple Account team.
5. Select your connected iPhone as the run destination.
6. Run with `Product > Run`.

If Xcode reports signing errors, let Xcode automatically manage signing and confirm the Bundle ID is still `com.stoner609.jadebowarrow`.
