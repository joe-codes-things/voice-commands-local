# Version History

## Current version: v0.0.56

The canonical build version is `MARKETING_VERSION` in `VoiceCommandsLocal/project.yml`. Build scripts read this setting for app and installer versioning.

### v0.0.56

- Simplified the voice-command editor by removing the Category field from the interface.
- Clarified the trigger label and adjusted the new-command window layout.

### v0.0.55

- Fixed a stale transcription timer that could execute an old partial transcription after recognition restarted.

### v0.0.54

- Improved command auto-loading, long-idle recognition recovery, and dictation paste timing.

### v0.0.53

- Added the unified installer DMG pipeline and fresh-install defaults.

Earlier release summaries are retained in this document. Build artifacts are local outputs and are intentionally ignored by Git.

## Release checklist

1. Update `MARKETING_VERSION` in `VoiceCommandsLocal/project.yml` to a new `MAJOR.MINOR.PATCH` value.
2. Regenerate the checked-in Xcode project with XcodeGen so direct Xcode builds use the same version.
3. Run `./scripts/build-dmg.sh` on macOS with Xcode and installer tools installed.
4. Test installation and basic app behavior on a clean macOS user account.
5. Review privacy disclosures and command safety notes before distributing.

No new version or build was created during the documentation update.
