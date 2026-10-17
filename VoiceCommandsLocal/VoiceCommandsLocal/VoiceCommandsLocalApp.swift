//
//  VoiceCommandsLocalApp.swift
//  VoiceCommandsLocal
//
//  Voice Commands Local - Main App Entry Point
//  A voice-controlled system for macOS using Apple's on-device speech recognition
//

import SwiftUI

/**
 Main application entry point

 Root of the SwiftUI app. Initializes app state and presents the main content view.

 Architecture:
 - SwiftUI lifecycle management
 - Menu bar app (no dock icon, lives in status bar)
 - Native Speech framework for voice recognition (no external dependencies)
 */
@main
struct VoiceCommandsLocalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate for Menu Bar

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var window: NSWindow?
    var appState: AppState?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Create a custom icon that's more unique than the generic mic
            // Use a waveform.circle to make it distinct from the system mic indicator
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Voice Commands")?.withSymbolConfiguration(config)
            button.action = #selector(toggleWindow)
            button.target = self
            
            // Enable right-click menu
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create AppState instance for the menu bar app
        let appState = AppState()
        self.appState = appState
        
        let contentView = ContentView()
            .environmentObject(appState)
            .frame(width: 700, height: 600)
        
        // Create window with standard controls
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Voice Commands Local"
        window.contentViewController = NSHostingController(rootView: contentView)
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        self.window = window
        
        // Observe mode changes to update menu
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenu),
            name: NSNotification.Name("ModeChanged"),
            object: nil
        )
    }
    
    @objc func toggleWindow(_ sender: NSStatusBarButton?) {
        guard let event = NSApp.currentEvent else { return }
        
        // Right-click shows menu
        if event.type == .rightMouseUp {
            showMenu()
            return
        }
        
        // Left-click toggles window
        if let window = window {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                // Position window near menu bar icon
                if let button = statusItem?.button {
                    let buttonRect = button.window?.convertToScreen(button.frame) ?? .zero
                    let windowX = buttonRect.midX - (window.frame.width / 2)
                    let windowY = buttonRect.minY - window.frame.height - 8
                    window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
                }
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc func showMenu() {
        let menu = NSMenu()
        
        // Voice Commands
        let commandsItem = NSMenuItem(title: "Voice Commands", action: #selector(showVoiceCommands), keyEquivalent: "")
        commandsItem.target = self
        menu.addItem(commandsItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Mode indicator (disabled, grey text)
        let modeText = appState?.currentMode == .command ? "Command Mode" : "Dictation Mode"
        let modeItem = NSMenuItem(title: modeText, action: nil, keyEquivalent: "")
        modeItem.isEnabled = false
        menu.addItem(modeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Voice Commands Local", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        
        // Clear menu after it's shown so left-click still works
        DispatchQueue.main.async {
            self.statusItem?.menu = nil
        }
    }
    
    @objc func updateMenu() {
        // This will be called when mode changes to update the menu if it's open
    }
    
    @objc func showVoiceCommands() {
        // Open window and navigate to voice commands
        if let window = window {
            if !window.isVisible {
                // Position window near menu bar icon
                if let button = statusItem?.button {
                    let buttonRect = button.window?.convertToScreen(button.frame) ?? .zero
                    let windowX = buttonRect.midX - (window.frame.width / 2)
                    let windowY = buttonRect.minY - window.frame.height - 8
                    window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
                }
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            // Post notification to show commands view
            NotificationCenter.default.post(name: NSNotification.Name("ShowVoiceCommands"), object: nil)
        }
    }
    
    @objc func showSettings() {
        // Open window and navigate to settings
        if let window = window {
            if !window.isVisible {
                // Position window near menu bar icon
                if let button = statusItem?.button {
                    let buttonRect = button.window?.convertToScreen(button.frame) ?? .zero
                    let windowX = buttonRect.midX - (window.frame.width / 2)
                    let windowY = buttonRect.minY - window.frame.height - 8
                    window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
                }
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            // Post notification to show settings
            NotificationCenter.default.post(name: NSNotification.Name("ShowSettings"), object: nil)
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
