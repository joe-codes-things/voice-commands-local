# Voice Commands Local

A macOS menu bar app for voice-triggered commands and dictation. It uses Apple's Speech framework and stores user settings and command registries in the user's Documents folder.

## Features

- Command mode for opening files and URLs or running user-configured shell scripts and AppleScripts.
- Dictation mode for transcribing speech and pasting it into the active app.
- Configurable keyboard shortcuts, activation phrase, and voice shortcuts.
- JSON import and export for user-created commands.

## Requirements

- macOS 13 or later.
- Xcode with the macOS SDK and command-line build tools.
- A microphone; Accessibility permission is needed for simulated paste in Dictation mode.

There are no third-party Swift package dependencies. XcodeGen is optional and is only needed to regenerate the checked-in Xcode project from `VoiceCommandsLocal/project.yml`.

## Build and run

Clone the repository, open Terminal in the checkout, then run:

```sh
./scripts/run.sh
```

To create a distributable DMG:

```sh
./scripts/build-dmg.sh
```

Both scripts require Xcode command-line tools. Release artifacts are written to `builds/`, which is intentionally Git-ignored; people cloning the source build their own copy. See [docs/BUILD-PIPELINE.md](./docs/BUILD-PIPELINE.md) for details.

## First launch

macOS requests microphone and Speech Recognition permissions. Grant them in **System Settings → Privacy & Security**. Grant Accessibility permission if Dictation mode must paste automatically; without it, the recognized text remains on the clipboard for manual paste.

The app appears in the menu bar. Start listening from the app controls or configured shortcut, select Command or Dictation mode, and speak.

## Using the app

Command mode matches recognized phrases against enabled commands. Dictation mode copies recognized text to the clipboard and simulates Command-V in the active app.

Open the Voice Commands view using the speech-bubble control. Each command has a title, one or more comma-separated trigger phrases, an action type, and action data. Supported actions are:

| Action | Behavior |
| --- | --- |
| Open File | Opens the selected file or application. |
| Open URL | Opens the URL in the default browser; HTTPS is added when omitted. |
| Run Shell Script | Runs the provided text using `/bin/zsh -c` as the current user. |
| Run AppleScript | Executes the provided AppleScript. |

Commands can be edited, enabled or disabled, deleted, imported from JSON, and exported to JSON. Only import registries from trusted sources, and review scripts before enabling them. While listening, recognized audio that contains a configured trigger can activate a command. The activation phrase is optional.

Open Settings using the gear control. Default global shortcuts are:

| Shortcut | Action |
| --- | --- |
| Command-L | Start or stop listening |
| Command-1 | Switch to Command mode |
| Command-2 | Switch to Dictation mode |

Shortcuts and optional voice shortcuts can be changed in Settings. When an activation phrase is configured, it must precede command phrases.

## User data

Settings and the default command registry are stored in:

```text
~/Documents/Voice Commands Local/
```

The default files are `settings.json` and `voice-commands.json`. The app may migrate JSON files from its former `~/Documents/VoiceCommandsLocal/` directory.

Use the Voice Commands view's Open and Save controls to import and export command registries. Keep backups of registries you want to preserve.

## Privacy and command safety

Speech recognition is configured with `requiresOnDeviceRecognition = false`. Depending on macOS and service availability, speech audio may be sent to Apple for recognition.

Diagnostic logs are written to `/tmp/voicecmds.log` and can contain recognized text and command details.

## Troubleshooting

- If speech recognition does not start, check Microphone and Speech Recognition permissions under **System Settings → Privacy & Security**, confirm an input device is selected, and restart the app after changing permissions.
- If Dictation does not paste automatically, check Accessibility permission, click the intended text field before speaking, or paste manually with Command-V.
- If a command does not run, confirm Command mode is listening, the command is enabled, and the recognized phrase contains its trigger. If an activation phrase is configured, say it first.
- If settings or commands appear missing, check `~/Documents/Voice Commands Local/` and verify the JSON files are readable and valid.

## Documentation

- [User guide](./docs/USER-GUIDE.md)
- [Build pipeline](./docs/BUILD-PIPELINE.md)
- [Known limitations](./docs/BUGS.md)
- [Version history](./docs/VERSIONS.md)

## License

This project is licensed under the MIT License; see [LICENSE](./LICENSE).
