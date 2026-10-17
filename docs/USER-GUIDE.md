# User Guide

## Overview

Voice Commands Local is a macOS menu bar app with two modes:

- **Command mode** matches recognized phrases against enabled commands.
- **Dictation mode** copies recognized text to the clipboard and simulates Command-V in the active app.

The app needs microphone and Speech Recognition permissions. Dictation's automatic paste additionally needs Accessibility permission.

## Getting started

1. Launch Voice Commands Local and grant microphone and Speech Recognition access when macOS asks.
2. Grant Accessibility access in **System Settings → Privacy & Security → Accessibility** if you want Dictation mode to paste automatically.
3. Open the app from its menu bar icon.
4. Choose Command or Dictation mode and start listening.

Without Accessibility permission, text is still copied to the clipboard; paste it manually with Command-V.

## Commands

Open the Voice Commands view using the speech-bubble control. Create a command by entering a title, one or more comma-separated trigger phrases, an action type, and its action data.

Supported action types:

| Action | Behavior |
| --- | --- |
| Open File | Opens the selected file or application. |
| Open URL | Opens the URL in the default browser; an HTTPS scheme is added when omitted. |
| Run Shell Script | Runs the provided text using `/bin/zsh -c` as the current user. |
| Run AppleScript | Executes the provided AppleScript. |

Commands can be edited, enabled or disabled, deleted, imported from JSON, and exported to JSON. The default registry is loaded from `voice-commands.json` at app startup.

### Command safety

Shell scripts and AppleScripts can perform actions available to your macOS user account. Only import command registries from sources you trust, and review script contents before enabling them. While the app is listening, recognized audio that contains a configured trigger can activate that command. An activation phrase can reduce accidental matches, but it is optional.

## Settings and shortcuts

Open Settings using the gear control. The default global keyboard shortcuts are:

| Shortcut | Action |
| --- | --- |
| Command-L | Start or stop listening |
| Command-1 | Switch to Command mode |
| Command-2 | Switch to Dictation mode |

You can record different shortcuts in Settings. An optional activation phrase must precede command phrases when configured. Optional voice shortcuts switch modes or stop listening.

## Stored data and migration

The app stores user data in:

```text
~/Documents/Voice Commands Local/
```

This directory contains `settings.json` and `voice-commands.json`. On launch, the app can migrate JSON files from the former `~/Documents/VoiceCommandsLocal/` directory when the corresponding destination file does not already exist.

Use the Voice Commands view's Open and Save controls to import and export command registries. Keep backups of registries you want to preserve.

## Privacy

Speech requests set `requiresOnDeviceRecognition` to `false`, so on-device-only recognition is not required. Depending on macOS and service availability, speech audio may be sent to Apple for recognition.

The app writes diagnostic logs to `/tmp/voicecmds.log`. Logs can include recognized speech and command text.

## Troubleshooting

### Speech recognition does not start

- Confirm microphone and Speech Recognition permissions in **System Settings → Privacy & Security**.
- Confirm a working microphone is selected in **System Settings → Sound → Input**.
- Restart the app after changing permissions.

### Dictation does not paste

- Confirm Accessibility permission is enabled for the app.
- Click the intended text field before speaking.
- Use Command-V to paste manually if automatic paste is unavailable.

### A command does not run

- Confirm Command mode is active and listening is on.
- Confirm the command is enabled and its trigger phrase matches the recognized text.
- If an activation phrase is set, say it before the command.

### Settings or commands appear missing

- Check `~/Documents/Voice Commands Local/`.
- Confirm the JSON files are valid and readable.
- Use a backup or import a known-good command registry if needed.

## Diagnostic log

The current log path is `/tmp/voicecmds.log`; it may be useful when diagnosing app behavior.
