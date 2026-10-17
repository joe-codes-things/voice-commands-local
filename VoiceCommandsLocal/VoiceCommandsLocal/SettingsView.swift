//
//  SettingsView.swift
//  VoiceCommandsLocal
//
//  Settings panel for configuration
//

import SwiftUI
import Carbon

/**
 Settings view

 Provides configuration options:
 - Keyboard shortcuts
 - About / version info
 */
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var toggleListeningKey: String
    @State private var commandModeKey: String
    @State private var dictationModeKey: String
    @State private var activationPhrase: String
    @State private var commandModeVoiceShortcut: String
    @State private var dictationModeVoiceShortcut: String
    @State private var stopListeningVoiceShortcut: String
    
    @State private var recordingShortcut: ShortcutField? = nil
    @FocusState private var isActivationFieldFocused: Bool
    
    enum ShortcutField {
        case toggleListening
        case commandMode
        case dictationMode
    }
    
    init() {
        // Load from settings storage
        let settings = KeyboardShortcutSettings.load()
        _toggleListeningKey = State(initialValue: settings.toggleListening)
        _commandModeKey = State(initialValue: settings.commandMode)
        _dictationModeKey = State(initialValue: settings.dictation)
        _activationPhrase = State(initialValue: settings.activationPhrase)
        _commandModeVoiceShortcut = State(initialValue: settings.commandModeVoiceShortcut)
        _dictationModeVoiceShortcut = State(initialValue: settings.dictationModeVoiceShortcut)
        _stopListeningVoiceShortcut = State(initialValue: settings.stopListeningVoiceShortcut)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(20)
            
            Divider()
            
            // Content
            Form {
                Section(header: Text("Keyboard Shortcuts")) {
                    ShortcutRow(
                        label: "Start/Stop Listening",
                        shortcut: toggleListeningKey,
                        isRecording: recordingShortcut == .toggleListening,
                        onRecord: { 
                            isActivationFieldFocused = false
                            if recordingShortcut == .toggleListening {
                                // Cancel recording
                                recordingShortcut = nil
                            } else {
                                recordingShortcut = .toggleListening
                            }
                        }
                    )
                    
                    ShortcutRow(
                        label: "Command Mode",
                        shortcut: commandModeKey,
                        isRecording: recordingShortcut == .commandMode,
                        onRecord: { 
                            isActivationFieldFocused = false
                            if recordingShortcut == .commandMode {
                                // Cancel recording
                                recordingShortcut = nil
                            } else {
                                recordingShortcut = .commandMode
                            }
                        }
                    )
                    
                    ShortcutRow(
                        label: "Dictation Mode",
                        shortcut: dictationModeKey,
                        isRecording: recordingShortcut == .dictationMode,
                        onRecord: { 
                            isActivationFieldFocused = false
                            if recordingShortcut == .dictationMode {
                                // Cancel recording
                                recordingShortcut = nil
                            } else {
                                recordingShortcut = .dictationMode
                            }
                        }
                    )
                    
                    Text("Click current key command to set new one")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Voice Shortcuts")) {
                    HStack {
                        Text("Command Mode")
                        Spacer()
                        TextField("", text: $commandModeVoiceShortcut)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .frame(width: 150)
                    }
                    
                    HStack {
                        Text("Dictation Mode")
                        Spacer()
                        TextField("", text: $dictationModeVoiceShortcut)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .frame(width: 150)
                    }
                    
                    HStack {
                        Text("Stop Listening")
                        Spacer()
                        TextField("", text: $stopListeningVoiceShortcut)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                            .frame(width: 150)
                    }
                }
                
                Section(header: Text("Activation")) {
                    HStack {
                        Text("Activation Phrase")
                        Spacer()
                        TextField("", text: $activationPhrase)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(isActivationFieldFocused ? 0.15 : 0.1))
                            .cornerRadius(6)
                            .frame(width: 150)
                            .focused($isActivationFieldFocused)
                            .onTapGesture {
                                isActivationFieldFocused = true
                            }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Clicking outside the TextField unfocuses it
                        isActivationFieldFocused = false
                    }
                    
                    Text("Require specific name or phrase be said before trigger phrase(s) of commands")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .background(
                KeyEventHandler(
                    isRecording: recordingShortcut != nil,
                    isTextFieldFocused: isActivationFieldFocused,
                    onKeyPress: { keyCombo in
                        handleKeyPress(keyCombo)
                    },
                    onEscape: {
                        if isActivationFieldFocused {
                            // Unfocus activation field
                            isActivationFieldFocused = false
                        } else if recordingShortcut != nil {
                            // Cancel recording
                            recordingShortcut = nil
                        } else {
                            // Close settings
                            dismiss()
                        }
                    },
                    onReturn: {
                        if isActivationFieldFocused {
                            // Unfocus activation field
                            isActivationFieldFocused = false
                        } else if recordingShortcut == nil {
                            // Save and close
                            saveSettings()
                            dismiss()
                        }
                    }
                )
            )
            
            Divider()
            
            // Footer
            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: {
                    saveSettings()
                    dismiss()
                }) {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(width: 550, height: 600)
    }
    
    private func handleKeyPress(_ keyCombo: String) {
        guard let field = recordingShortcut else { return }
        
        switch field {
        case .toggleListening:
            toggleListeningKey = keyCombo
        case .commandMode:
            commandModeKey = keyCombo
        case .dictationMode:
            dictationModeKey = keyCombo
        }
        
        recordingShortcut = nil
    }
    
    private func saveSettings() {
        let settings = KeyboardShortcutSettings(
            toggleListening: toggleListeningKey,
            commandMode: commandModeKey,
            dictation: dictationModeKey,
            activationPhrase: activationPhrase,
            commandModeVoiceShortcut: commandModeVoiceShortcut,
            dictationModeVoiceShortcut: dictationModeVoiceShortcut,
            stopListeningVoiceShortcut: stopListeningVoiceShortcut
        )
        settings.save()
        
        // Notify app to reload shortcuts
        NotificationCenter.default.post(name: .keyboardShortcutsChanged, object: nil)
    }
}

// MARK: - Shortcut Row

struct ShortcutRow: View {
    let label: String
    let shortcut: String
    let isRecording: Bool
    let onRecord: () -> Void
    
    // Format shortcut for display by adding spaces after modifiers
    private var displayShortcut: String {
        var display = shortcut
        display = display.replacingOccurrences(of: "⌃", with: "⌃ ")
        display = display.replacingOccurrences(of: "⌥", with: "⌥ ")
        display = display.replacingOccurrences(of: "⇧", with: "⇧ ")
        display = display.replacingOccurrences(of: "⌘", with: "⌘ ")
        return display
    }
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Button(action: onRecord) {
                Text(isRecording ? "Press keys..." : displayShortcut)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(isRecording ? .blue : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.blue : Color.clear, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Key Event Handler

struct KeyEventHandler: NSViewRepresentable {
    let isRecording: Bool
    let isTextFieldFocused: Bool
    let onKeyPress: (String) -> Void
    let onEscape: () -> Void
    let onReturn: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onKeyPress = onKeyPress
        view.onEscape = onEscape
        view.onReturn = onReturn
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? KeyCaptureView {
            view.isRecording = isRecording
            view.isTextFieldFocused = isTextFieldFocused
        }
    }
}

class KeyCaptureView: NSView {
    var isRecording = false
    var isTextFieldFocused = false
    var onKeyPress: ((String) -> Void)?
    var onEscape: (() -> Void)?
    var onReturn: (() -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        // Always handle Escape and Return, even when text field is focused
        if event.keyCode == 53 { // Escape key
            onEscape?()
            return
        }
        
        if event.keyCode == 36 { // Return key
            onReturn?()
            return
        }
        
        // If text field is focused, let it handle the key event
        if isTextFieldFocused {
            super.keyDown(with: event)
            return
        }
        
        // Only capture keys for shortcuts when recording
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var combo = ""
        
        // Store WITHOUT spaces for matching
        if modifiers.contains(.control) { combo += "⌃" }
        if modifiers.contains(.option) { combo += "⌥" }
        if modifiers.contains(.shift) { combo += "⇧" }
        if modifiers.contains(.command) { combo += "⌘" }
        
        if let char = event.charactersIgnoringModifiers?.uppercased() {
            combo += char
        }
        
        if !combo.isEmpty {
            onKeyPress?(combo)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
}

// MARK: - Keyboard Shortcut Settings

struct KeyboardShortcutSettings: Codable {
    var toggleListening: String
    var commandMode: String
    var dictation: String
    var activationPhrase: String
    var commandModeVoiceShortcut: String
    var dictationModeVoiceShortcut: String
    var stopListeningVoiceShortcut: String
    
    static let defaultSettings = KeyboardShortcutSettings(
        toggleListening: "⌘L",
        commandMode: "⌘1",
        dictation: "⌘2",
        activationPhrase: "",
        commandModeVoiceShortcut: "",
        dictationModeVoiceShortcut: "",
        stopListeningVoiceShortcut: ""
    )
    
    // Custom encoding to ensure consistent order
    enum CodingKeys: String, CodingKey {
        case toggleListening
        case commandMode
        case dictation
        case activationPhrase
        case commandModeVoiceShortcut
        case dictationModeVoiceShortcut
        case stopListeningVoiceShortcut
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toggleListening, forKey: .toggleListening)
        try container.encode(commandMode, forKey: .commandMode)
        try container.encode(dictation, forKey: .dictation)
        try container.encode(activationPhrase, forKey: .activationPhrase)
        try container.encode(commandModeVoiceShortcut, forKey: .commandModeVoiceShortcut)
        try container.encode(dictationModeVoiceShortcut, forKey: .dictationModeVoiceShortcut)
        try container.encode(stopListeningVoiceShortcut, forKey: .stopListeningVoiceShortcut)
    }
    
    private static func getSettingsPath() -> String {
        // Use Documents/Voice Commands Local folder for JSON storage
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appFolder = documents.appendingPathComponent("Voice Commands Local")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        // Migrate from old location if needed
        migrateSettingsFromOldLocation(to: appFolder.path)
        
        return appFolder.path
    }
    
    private static func migrateSettingsFromOldLocation(to newPath: String) {
        let oldPaths = [
            "\(NSHomeDirectory())/Documents/VoiceCommandsLocal"  // Old folder without spaces
        ]
        
        for oldPath in oldPaths {
            let oldSettingsFile = "\(oldPath)/settings.json"
            let newSettingsFile = "\(newPath)/settings.json"
            
            // Only migrate if old file exists and new file doesn't
            if FileManager.default.fileExists(atPath: oldSettingsFile) &&
               !FileManager.default.fileExists(atPath: newSettingsFile) {
                do {
                    try FileManager.default.copyItem(atPath: oldSettingsFile, toPath: newSettingsFile)
                    print("Migrated settings.json from \(oldPath)")
                } catch {
                    print("Settings migration error from \(oldPath): \(error)")
                }
            }
        }
    }
    
    static func load() -> KeyboardShortcutSettings {
        let settingsDir = getSettingsPath()
        let settingsPath = "\(settingsDir)/settings.json"
        
        print("Loading settings from: \(settingsPath)")
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
              let settings = try? JSONDecoder().decode(KeyboardShortcutSettings.self, from: data) else {
            print("Using default settings")
            return defaultSettings
        }
        
        print("Loaded settings successfully")
        return settings
    }
    
    func save() {
        let settingsDir = KeyboardShortcutSettings.getSettingsPath()
        let settingsPath = "\(settingsDir)/settings.json"
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(atPath: settingsDir, withIntermediateDirectories: true)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(self) {
            do {
                try data.write(to: URL(fileURLWithPath: settingsPath))
                print("Saved settings to: \(settingsPath)")
            } catch {
                print("Error saving settings: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let keyboardShortcutsChanged = Notification.Name("keyboardShortcutsChanged")
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
    }
}
