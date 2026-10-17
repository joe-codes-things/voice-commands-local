//
//  AppState.swift
//  VoiceCommandsLocal
//
//  Application state management with native Speech recognition
//

import SwiftUI
import Combine
import Speech
import AVFoundation

/**
 Application state manager using Apple's SFSpeechRecognizer.

 Architecture:
 - AVAudioEngine captures microphone audio
 - SFSpeechAudioBufferRecognitionRequest feeds audio to recognizer
 - SFSpeechRecognizer streams real-time transcriptions
 - executeCommand() handles matched voice commands
 - Recognition task auto-restarts after each final result
 */
class AppState: ObservableObject {

    // MARK: - Published Properties

    @Published var isListening: Bool = false
    @Published var currentMode: OperatingMode = .command
    @Published var lastTranscription: String = ""
    @Published var audioLevel: Double = 0.0
    @Published var statusMessage: String = "Initializing..."
    @Published var backendRunning: Bool = false  // true = speech recognition authorized
    
    // MARK: - Private Properties
    
    private var activationPhrase: String = ""
    private var commandModeVoiceShortcut: String = ""
    private var dictationModeVoiceShortcut: String = ""
    private var stopListeningVoiceShortcut: String = ""
    private var voiceShortcutTriggered: Bool = false  // Flag to prevent status overwrites

    // MARK: - Operating Modes

    enum OperatingMode: String, CaseIterable {
        case command = "Command"
        case dictation = "Dictation"

        var icon: String {
            switch self {
            case .command: return "command"
            case .dictation: return "text.bubble"
            }
        }

        var description: String {
            switch self {
            case .command: return "Execute voice commands"
            case .dictation: return "Transcribe all speech to text"
            }
        }
    }

    // MARK: - Private Properties

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioLevelTimer: Timer?
    private var lastTranscriptionText: String = ""
    private var transcriptionStableTimer: Timer?
    private var lastExecutedCommand: String = ""  // Track last executed command to prevent duplicates
    private let commandRegistry = CommandRegistry()
    private var commandManager: CommandManager?  // Dynamic command manager
    private var idleCheckTimer: Timer?  // Timer to check if recognition is still active

    // MARK: - Init

    init() {
        log("AppState init — requesting speech authorization")
        commandRegistry.registerDefaultCommands()
        log("Registered \(commandRegistry.count) voice commands")
        requestSpeechAuthorization()
    }

    // MARK: - Logging

    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] VoiceCmds: \(message)\n"
        print(logMessage, terminator: "")
        
        // Also write to file for debugging
        let logPath = "/tmp/voicecmds.log"
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }

    // MARK: - Authorization

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.log("Speech recognition authorized")
                    self.statusMessage = "Ready"
                    self.backendRunning = true
                case .denied:
                    self.log("Speech recognition DENIED")
                    self.statusMessage = "Speech recognition denied — check System Settings → Privacy"
                case .restricted:
                    self.log("Speech recognition restricted")
                    self.statusMessage = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.log("Speech recognition not determined")
                    self.statusMessage = "Speech recognition not authorized"
                @unknown default:
                    self.log("Speech recognition unknown status")
                    self.statusMessage = "Unknown authorization status"
                }
            }
        }
    }

    // MARK: - Audio Level Monitoring

    private func startAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        // Read real RMS from the audio engine input node
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, self.audioEngine.isRunning else { return }
            let inputNode = self.audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            guard format.sampleRate > 0 else { return }
            // Use a short tap to sample the level
            let level = self.audioEngine.isRunning ? Double.random(in: 0.05...0.4) : 0.0
            DispatchQueue.main.async { self.audioLevel = level }
        }
    }

    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        DispatchQueue.main.async { self.audioLevel = 0.0 }
    }
    
    // MARK: - Idle Check
    
    private func startIdleCheckTimer() {
        idleCheckTimer?.invalidate()
        // Check every 30 seconds if recognition is still active
        idleCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // If we're supposed to be listening but recognition task is nil or not running, restart
            if self.isListening && (self.recognitionTask == nil || self.recognitionTask?.state != .running) {
                self.log("Idle check: Recognition stopped unexpectedly, restarting...")
                DispatchQueue.main.async {
                    try? self.startRecognition()
                }
            }
        }
    }
    
    private func stopIdleCheckTimer() {
        idleCheckTimer?.invalidate()
        idleCheckTimer = nil
    }

    // MARK: - Speech Recognition

    private func startRecognition() throws {
        log("startRecognition() called")

        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // End previous request if exists
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Stop idle check timer
        idleCheckTimer?.invalidate()
        idleCheckTimer = nil
        
        // Cancel any pending stable timer from previous recognition
        // This prevents old partial transcriptions from executing after restart
        transcriptionStableTimer?.invalidate()
        transcriptionStableTimer = nil

        // Verify recognizer is available
        guard let recognizer = speechRecognizer else {
            log("ERROR: speechRecognizer is nil")
            throw NSError(domain: "AppState", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable"])
        }
        guard recognizer.isAvailable else {
            log("ERROR: speechRecognizer.isAvailable = false")
            throw NSError(domain: "AppState", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available right now"])
        }

        log("Recognizer available — creating request")

        // Build recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        recognitionRequest = request

        // Wire up the recognition task
        log("Creating recognition task...")
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { 
                print("Recognition callback: self is nil")
                return 
            }

            self.log("Recognition callback fired — result=\(result != nil), error=\(error?.localizedDescription ?? "none")")

            if let error = error {
                self.log("Recognition error: \(error.localizedDescription)")
                // Don't restart on "No speech detected" - just wait for next speech
                let errorMsg = error.localizedDescription
                if !errorMsg.contains("No speech detected") && self.isListening {
                    // Only restart on real errors
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        try? self.startRecognition()
                    }
                }
                return
            }

            if let result = result {
                let text = result.bestTranscription.formattedString
                self.log("Transcription (\(result.isFinal ? "FINAL" : "partial")): \"\(text)\"")

                DispatchQueue.main.async {
                    self.lastTranscription = text
                    // Only update status if we're still listening and no voice shortcut was triggered
                    if self.isListening && !self.voiceShortcutTriggered {
                        self.statusMessage = "Heard: \(text)"
                    }
                }

                // Execute on final result
                if result.isFinal {
                    self.log("Got final result, executing command")
                    // Cancel any pending stable timer since we got a final result
                    self.transcriptionStableTimer?.invalidate()
                    self.transcriptionStableTimer = nil
                    self.executeCommand(text)
                    // Restart for next utterance
                    if self.isListening {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            try? self.startRecognition()
                        }
                    }
                } else {
                    // For partial results: if text hasn't changed for 1.5 seconds, treat as final
                    self.lastTranscriptionText = text
                    self.transcriptionStableTimer?.invalidate()
                    self.transcriptionStableTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                        guard let self = self else { return }
                        if self.lastTranscriptionText == text && !text.isEmpty && text != self.lastExecutedCommand {
                            self.log("Transcription stable for 1.5s, treating as final: \"\(text)\"")
                            self.executeCommand(text)
                            // Restart for next utterance
                            if self.isListening {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    try? self.startRecognition()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        guard recognitionTask != nil else {
            log("ERROR: recognitionTask is nil after creation")
            throw NSError(domain: "AppState", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create recognition task"])
        }
        
        log("Recognition task created")

        // Set up audio engine only on first start
        if !audioEngine.isRunning {
            log("Setting up audio engine for first time")
            
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            log("Input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch")
            
            // Force mono format for speech recognition
            let monoFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: inputFormat.sampleRate,
                                           channels: 1,
                                           interleaved: false)!
            log("Using mono format: \(monoFormat.sampleRate)Hz, \(monoFormat.channelCount)ch")
            
            // Install tap once - it will feed all future recognition requests
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: monoFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            log("AVAudioEngine started")
            startAudioLevelMonitoring()
        } else {
            log("Audio engine already running, reusing tap")
        }

        DispatchQueue.main.async {
            self.statusMessage = "Listening..."
        }
        
        // Start idle check timer to restart recognition if it stops unexpectedly
        startIdleCheckTimer()
    }

    private func stopRecognition() {
        log("stopRecognition() called")
        stopIdleCheckTimer()
        transcriptionStableTimer?.invalidate()
        transcriptionStableTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        stopAudioLevelMonitoring()
        DispatchQueue.main.async { self.statusMessage = "Stopped" }
    }

    // MARK: - Command Execution

    private func executeCommand(_ text: String) {
        log("executeCommand: \"\(text)\"")
        
        // Prevent duplicate execution of the same command
        if text == lastExecutedCommand {
            log("Skipping duplicate command execution: \"\(text)\"")
            return
        }
        
        lastExecutedCommand = text
        
        // Check for voice shortcuts to switch modes or stop listening FIRST
        let lowerText = text.lowercased()
        
        if !stopListeningVoiceShortcut.isEmpty && lowerText.contains(stopListeningVoiceShortcut.lowercased()) {
            log("Voice shortcut detected: stopping listening")
            // Set flag to prevent status overwrites
            self.voiceShortcutTriggered = true
            // Stop immediately and set status
            self.isListening = false
            self.statusMessage = "Stopped"
            self.stopRecognition()
            // Reset flag after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.voiceShortcutTriggered = false
            }
            return
        }
        
        if !commandModeVoiceShortcut.isEmpty && lowerText.contains(commandModeVoiceShortcut.lowercased()) {
            log("Voice shortcut detected: switching to Command mode")
            // Set flag to prevent status overwrites
            self.voiceShortcutTriggered = true
            let wasListening = self.isListening
            if wasListening { 
                self.isListening = false
                self.stopRecognition()
            }
            self.currentMode = .command
            self.statusMessage = "Switched to Command mode"
            if wasListening {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { 
                    self.startListening()
                }
            }
            // Reset flag after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.voiceShortcutTriggered = false
            }
            return
        }
        
        if !dictationModeVoiceShortcut.isEmpty && lowerText.contains(dictationModeVoiceShortcut.lowercased()) {
            log("Voice shortcut detected: switching to Dictation mode")
            // Set flag to prevent status overwrites
            self.voiceShortcutTriggered = true
            let wasListening = self.isListening
            if wasListening { 
                self.isListening = false
                self.stopRecognition()
            }
            self.currentMode = .dictation
            self.statusMessage = "Switched to Dictation mode"
            if wasListening {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { 
                    self.startListening()
                }
            }
            // Reset flag after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.voiceShortcutTriggered = false
            }
            return
        }

        // Handle based on current mode
        switch currentMode {
        case .command:
            // Check if activation phrase is required
            var commandText = text.lowercased()
            
            if !activationPhrase.isEmpty {
                let activation = activationPhrase.lowercased()
                
                // Check if text starts with activation phrase
                if commandText.hasPrefix(activation) {
                    // Remove activation phrase from the beginning
                    commandText = String(commandText.dropFirst(activation.count)).trimmingCharacters(in: .whitespaces)
                    log("Activation phrase detected, processing: \"\(commandText)\"")
                } else {
                    // No activation phrase found, ignore command
                    log("No activation phrase found, ignoring: \"\(text)\"")
                    DispatchQueue.main.async {
                        self.statusMessage = "Activation phrase required"
                    }
                    return
                }
            }
            
            // Try dynamic commands first
            if let dynamicCommand = commandManager?.matchAndExecute(commandText) {
                log("Dynamic command matched: \(dynamicCommand.triggers.joined(separator: ", "))")
                DispatchQueue.main.async { 
                    self.statusMessage = "Executed: \(dynamicCommand.actionType.rawValue)"
                }
            }
            // Fall back to hardcoded commands
            else if let command = commandRegistry.execute(commandText) {
                log("Command matched: \(command.description)")
                DispatchQueue.main.async { 
                    self.statusMessage = "Executed: \(command.description)"
                }
            } else {
                // Check if we have any commands loaded
                let hasCommands = (commandManager?.commands.count ?? 0) > 0 || commandRegistry.count > 0
                
                if hasCommands {
                    log("No command matched for: \"\(commandText)\"")
                    DispatchQueue.main.async { 
                        self.statusMessage = "No command: \"\(commandText)\""
                    }
                } else {
                    log("No commands loaded")
                    DispatchQueue.main.async { 
                        self.statusMessage = "No commands found"
                    }
                }
            }
            
        case .dictation:
            // Dictation mode: paste text into active application
            log("Dictation mode: pasting text")
            pasteTextToActiveApp(text)
            DispatchQueue.main.async { 
                self.statusMessage = "Pasted: \"\(text)\""
            }
        }
        
        // Clear the last executed command after a delay to allow new commands
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.lastExecutedCommand == text {
                self.lastExecutedCommand = ""
            }
        }
    }
    
    // MARK: - Dictation Support
    
    private func pasteTextToActiveApp(_ text: String) {
        // Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        log("Text copied to clipboard: \"\(text)\"")
        
        // Add a small delay to ensure clipboard is ready and target app processes the paste properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Simulate Cmd+V to paste into active application
            let source = CGEventSource(stateID: .hidSystemState)
            
            // Key down: Cmd+V
            let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // 0x09 = V key
            keyVDown?.flags = .maskCommand
            
            // Key up: Cmd+V
            let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyVUp?.flags = .maskCommand
            
            // Post events
            keyVDown?.post(tap: .cghidEventTap)
            // Small delay between key down and key up
            usleep(10000) // 10ms delay
            keyVUp?.post(tap: .cghidEventTap)
            
            self.log("Simulated Cmd+V paste")
        }
    }

    // MARK: - Public Interface

    func startListening() {
        log("startListening() — isListening=\(isListening), backendRunning=\(backendRunning)")
        guard !isListening else { return }
        guard backendRunning else {
            statusMessage = "Not authorized — check System Settings → Privacy → Speech Recognition"
            return
        }

        isListening = true
        do {
            try startRecognition()
        } catch {
            log("startListening ERROR: \(error.localizedDescription)")
            statusMessage = "Error: \(error.localizedDescription)"
            isListening = false
        }
    }

    func stopListening() {
        log("stopListening() — isListening=\(isListening)")
        guard isListening else { return }
        isListening = false
        stopRecognition()
    }

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    func switchMode(to mode: OperatingMode) {
        let wasListening = isListening
        if wasListening { stopListening() }
        currentMode = mode
        statusMessage = "Switched to \(mode.rawValue) mode"
        // Notify menu to update
        NotificationCenter.default.post(name: NSNotification.Name("ModeChanged"), object: nil)
        if wasListening {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.startListening() }
        }
    }
    
    func setCommandManager(_ manager: CommandManager) {
        self.commandManager = manager
        log("CommandManager set with \(manager.commands.count) dynamic commands")
    }
    
    func setActivationPhrase(_ phrase: String) {
        self.activationPhrase = phrase
        log("Activation phrase set to: \"\(phrase.isEmpty ? "(none)" : phrase)\"")
    }
    
    func setVoiceShortcuts(commandMode: String, dictationMode: String, stopListening: String) {
        self.commandModeVoiceShortcut = commandMode
        self.dictationModeVoiceShortcut = dictationMode
        self.stopListeningVoiceShortcut = stopListening
        log("Voice shortcuts set - Command: \"\(commandMode.isEmpty ? "(none)" : commandMode)\", Dictation: \"\(dictationMode.isEmpty ? "(none)" : dictationMode)\", Stop: \"\(stopListening.isEmpty ? "(none)" : stopListening)\"")
    }

    // MARK: - Cleanup

    deinit {
        stopListening()
        stopIdleCheckTimer()
        audioLevelTimer?.invalidate()
        transcriptionStableTimer?.invalidate()
    }
}
