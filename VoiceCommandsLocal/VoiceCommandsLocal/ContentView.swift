//
//  ContentView.swift
//  VoiceCommandsLocal
//
//  Main application UI
//

import SwiftUI

// MARK: - Color Palette Extension

extension Color {
    // Dark nightclub aesthetic with neon purple accents
    static let neonPurple = Color(red: 138/255, green: 43/255, blue: 226/255)    // Bright electric purple
    static let neonIndigo = Color(red: 75/255, green: 0/255, blue: 130/255)      // Deep neon indigo
    static let glowPurple = Color(red: 186/255, green: 85/255, blue: 211/255)    // Medium orchid glow
    static let deepBlack = Color(red: 10/255, green: 10/255, blue: 15/255)       // Near black with hint of blue
    static let neonBlue = Color(red: 0/255, green: 191/255, blue: 255/255)       // Electric cyan blue
    static let neonGreen = Color(red: 57/255, green: 255/255, blue: 20/255)      // Bright neon green
    static let softGreen = Color(red: 46/255, green: 204/255, blue: 113/255)     // Softer emerald green
}

/**
 Main content view
 
 Displays:
 - Current mode indicator
 - Listening status
 - Audio level meter
 - Transcription results
 - Control buttons
 
 Dark nightclub aesthetic - black background with neon purple accents.
 */
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var commandManager = CommandManager()
    @State private var showingCommands = false
    @State private var showingSettings = false
    @State private var keyboardShortcuts = KeyboardShortcutSettings.load()
    
    var body: some View {
        ZStack {
            // Background - Deep black
            Color.deepBlack
                .ignoresSafeArea()
            
            // Main content or Commands view
            if showingCommands {
                CommandSettingsView(commandManager: commandManager, isPresented: $showingCommands)
                    .transition(.opacity)
            } else {
                VStack(spacing: 20) {
                    // Header
                    HeaderView(showingCommands: $showingCommands, showingSettings: $showingSettings)
                    
                    Spacer()
                    
                    // Status Display
                    StatusDisplayView()
                    
                    Spacer()
                    
                    // Controls
                    ControlsView()
                }
                .padding(30)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .onAppear {
            // Pass commandManager to appState for command execution
            appState.setCommandManager(commandManager)
            setupKeyboardShortcuts()
            
            // Listen for shortcut changes
            NotificationCenter.default.addObserver(
                forName: .keyboardShortcutsChanged,
                object: nil,
                queue: .main
            ) { _ in
                keyboardShortcuts = KeyboardShortcutSettings.load()
                // Update activation phrase and voice shortcuts in AppState
                appState.setActivationPhrase(keyboardShortcuts.activationPhrase)
                appState.setVoiceShortcuts(
                    commandMode: keyboardShortcuts.commandModeVoiceShortcut,
                    dictationMode: keyboardShortcuts.dictationModeVoiceShortcut,
                    stopListening: keyboardShortcuts.stopListeningVoiceShortcut
                )
            }
            
            // Listen for menu commands
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowVoiceCommands"),
                object: nil,
                queue: .main
            ) { _ in
                showingCommands = true
            }
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowSettings"),
                object: nil,
                queue: .main
            ) { _ in
                showingSettings = true
            }
            
            // Set initial activation phrase and voice shortcuts
            appState.setActivationPhrase(keyboardShortcuts.activationPhrase)
            appState.setVoiceShortcuts(
                commandMode: keyboardShortcuts.commandModeVoiceShortcut,
                dictationMode: keyboardShortcuts.dictationModeVoiceShortcut,
                stopListening: keyboardShortcuts.stopListeningVoiceShortcut
            )
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if handleKeyboardShortcut(event) {
                return nil // Event handled
            }
            return event
        }
    }
    
    private func handleKeyboardShortcut(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = event.charactersIgnoringModifiers?.uppercased() ?? ""
        
        var combo = ""
        // Build WITHOUT spaces for matching
        if modifiers.contains(.control) { combo += "⌃" }
        if modifiers.contains(.option) { combo += "⌥" }
        if modifiers.contains(.shift) { combo += "⇧" }
        if modifiers.contains(.command) { combo += "⌘" }
        combo += key
        
        // Check against configured shortcuts
        if combo == keyboardShortcuts.toggleListening {
            appState.toggleListening()
            return true
        }
        
        if combo == keyboardShortcuts.commandMode {
            appState.switchMode(to: .command)
            return true
        }
        
        if combo == keyboardShortcuts.dictation {
            appState.switchMode(to: .dictation)
            return true
        }
        
        return false
    }
}

// MARK: - Header View

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingCommands: Bool
    @Binding var showingSettings: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            // App Title - Centered
            Text("Voice Commands Local")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            // Commands Icon (Speech Bubble)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingCommands.toggle()
                }
            }) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Voice Commands")
            
            // Settings Icon (Gear)
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }
}

// MARK: - Mode Indicator

// Removed - no longer displayed in UI

// MARK: - Status Display

struct StatusDisplayView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 12) {
            // Listening indicator
            Circle()
                .fill(appState.isListening ? Color.neonPurple : Color.white.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: appState.isListening ? "mic.fill" : "mic.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )
                .shadow(color: appState.isListening ? Color.neonPurple.opacity(0.8) : Color.clear, radius: 30, x: 0, y: 0)
                .shadow(color: appState.isListening ? Color.neonPurple.opacity(0.6) : Color.clear, radius: 15, x: 0, y: 0)
                .scaleEffect(appState.isListening ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: appState.isListening)
            
            // Status text (selectable)
            Text(appState.statusMessage)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Audio Level Meter

struct AudioLevelMeterView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Audio Level")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    // Level indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(appState.audioLevel))
                        .animation(.linear(duration: 0.1), value: appState.audioLevel)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Transcription View

struct TranscriptionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Command")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
            
            ScrollView {
                Text(appState.lastTranscription.isEmpty ? "Waiting for command..." : appState.lastTranscription)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(appState.lastTranscription.isEmpty ? .gray.opacity(0.5) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .textSelection(.enabled)
            }
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Controls View

struct ControlsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            // Listen/Stop button
            Button(action: {
                appState.toggleListening()
            }) {
                HStack {
                    Image(systemName: appState.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18))
                    
                    Text(appState.isListening ? "Stop Listening" : "Start Listening")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appState.isListening ? Color.red.opacity(0.75) : Color.softGreen.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appState.isListening ? Color.red : Color.softGreen, lineWidth: 1.5)
                )
                .shadow(color: (appState.isListening ? Color.red : Color.softGreen).opacity(0.5), radius: 15)
            }
            .buttonStyle(.plain)
            
            // Mode switcher
            HStack(spacing: 12) {
                ForEach(AppState.OperatingMode.allCases, id: \.self) { mode in
                    Button(action: {
                        appState.switchMode(to: mode)
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 20))
                            
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(appState.currentMode == mode ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(appState.currentMode == mode ? Color.neonBlue.opacity(0.3) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(appState.currentMode == mode ? Color.neonBlue : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: appState.currentMode == mode ? Color.neonBlue.opacity(0.5) : Color.clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
            .frame(width: 400, height: 500)
    }
}
