# Known Issues and Limitations

This list reflects the current source and previously reported behavior. The repository has no automated test suite, and runtime behavior has not been re-tested as part of the documentation update.

## Current limitations

### Audio-level indicator is simulated

`AppState.swift` assigns a random value to the audio-level indicator rather than measuring input buffer amplitude. It is visual feedback only and does not affect speech recognition.

### Command matching uses substring matching

Dynamic and built-in commands use case-insensitive substring matching against recognized text. Similar phrases and incidental speech can match. Optional activation phrases can reduce unintended matches but are not mandatory.

### Voice shortcut status feedback may be overwritten

The known-issues history reports that feedback for voice shortcuts could be overwritten by recognition status. The current implementation still updates status from asynchronous recognition callbacks; this behavior needs a runtime retest.

### Shortcut recording after editing the activation phrase

The known-issues history reports a keyboard focus issue after editing the activation phrase. The current settings view includes explicit focus handling, but this interaction has not been retested recently.

## Operational notes

- Shell-script and AppleScript commands execute as the current user.
- There are no automated tests or CI workflows in the repository at this time.

## Closed and owner-accepted items

The project owner reviewed and accepted the following behaviors as non-issues for this project. No code changes were made for these items:

- Speech recognition does not require on-device processing (`requiresOnDeviceRecognition` is `false`); depending on macOS and service availability, audio may be sent to Apple.
- Diagnostic logging writes recognized speech and command details to `/tmp/voicecmds.log`.
- While listening in Command mode, recognized text can match configured triggers and run their configured actions. An activation phrase is optional.

Earlier release notes document fixes for duplicate command execution, recognition restarts, command auto-loading, and dictation paste timing; see [VERSIONS.md](./VERSIONS.md).
