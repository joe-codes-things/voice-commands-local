# Build Pipeline

## Prerequisites

Builds are intended to run on macOS with Xcode and its command-line tools installed. The production installer pipeline additionally uses `pkgbuild`, `hdiutil`, `osacompile`, and standard macOS utilities. No third-party package installation is required.

XcodeGen is optional and is only needed to regenerate `VoiceCommandsLocal/VoiceCommandsLocal.xcodeproj` from `VoiceCommandsLocal/project.yml`.

## Development build

From the repository root:

```sh
./scripts/run.sh
```

This builds the Debug app with `xcodebuild` into `.build/` and opens it. It terminates a currently running app instance before launching.

## Production DMG

From the repository root:

```sh
./scripts/build-dmg.sh
```

The release script reads `MARKETING_VERSION` from `VoiceCommandsLocal/project.yml` and:

1. Cleans and builds the Release app with that version.
2. Builds an installer package and an AppleScript uninstaller app.
3. Copies the app, installer, uninstaller, and root `README.md` (as “User Manual.md”) into a DMG.
4. Mounts the DMG to verify expected contents and that the app is embedded in the installer.
5. Removes temporary package and verification files.

The DMG is saved as `builds/VoiceCommandsLocal_vX.Y.Z_Installer.dmg`.

## Version source

`MARKETING_VERSION` in `VoiceCommandsLocal/project.yml` is the canonical version source used by `scripts/run.sh`, `scripts/build.sh`, `scripts/build-dmg.sh`, and installer scripts when no explicit version argument is passed. Set it to a numeric `MAJOR.MINOR.PATCH` value without a `v` prefix. For example:

```text
MARKETING_VERSION: "0.0.56"
```

The scripts validate the value and pass the same version through Xcode and package creation. Release scripts can accept an explicit `vMAJOR.MINOR.PATCH` argument for advanced use, but ordinary builds should omit it and use the project specification.

The checked-in Xcode project is generated from the XcodeGen specification and should be regenerated with XcodeGen after changing the specification. Repository build scripts override its marketing-version setting with the canonical value.

## Standalone app build

`./scripts/build.sh` builds a Release `.app` and places it in `builds/`. It uses the same canonical version source. This is primarily for local testing; the DMG pipeline is the distribution workflow.

## Artifacts and cleanup

Release artifacts in `builds/` are included in the repository. `.build/` and Xcode's Derived Data remain local and Git-ignored. Each release artifact should have a unique versioned filename; do not overwrite an existing published build.

Do not use a build output as a substitute for source or project configuration. The checked-in scripts and Xcode project are sufficient to build from a fresh clone on a compatible macOS/Xcode system.

## Troubleshooting

- If `xcodebuild` is unavailable, install or select Xcode and its command-line tools.
- If the version helper reports an invalid version, make sure `MARKETING_VERSION` in `VoiceCommandsLocal/project.yml` contains exactly three numeric components separated by periods, with no leading `v`.
- If a DMG already exists for the configured version, the script asks before replacing it. Increment `MARKETING_VERSION` for a new release rather than overwriting a published artifact.
- Confirm there is sufficient disk space for Xcode Derived Data and installer artifacts.
