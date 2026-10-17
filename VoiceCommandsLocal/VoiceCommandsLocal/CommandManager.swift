//
//  CommandManager.swift
//  VoiceCommandsLocal
//
//  Manages loading, saving, and executing dynamic commands
//

import Foundation
import AppKit

/**
 Manages dynamic command registries - loading from JSON, saving, and executing commands.
 */
class CommandManager: ObservableObject {
    
    @Published var commands: [DynamicCommand] = []
    @Published var currentRegistryPath: String? = nil
    
    private let settingsStoragePath: String
    private let defaultCommandsFileName = "voice-commands.json"
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] CommandMgr: \(message)\n"
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
    
    private func getDefaultCommandsPath() -> String {
        return "\(settingsStoragePath)/\(defaultCommandsFileName)"
    }
    
    init() {
        // Use Documents/Voice Commands Local folder for JSON storage
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appFolder = documents.appendingPathComponent("Voice Commands Local")
        self.settingsStoragePath = appFolder.path
        
        // Create Voice Commands Local directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        log("📁 CommandManager init - settings path: \(settingsStoragePath)")
        
        // Migrate from old location if needed
        migrateFromOldLocation()
        
        // SIMPLIFIED: Always load from voice-commands.json (just like settings.json)
        let defaultPath = getDefaultCommandsPath()
        log("🔍 Looking for commands at: \(defaultPath)")
        
        if FileManager.default.fileExists(atPath: defaultPath) {
            log("✅ Found voice-commands.json, loading...")
            loadFromDefaultPath()
        } else {
            log("⚠️  voice-commands.json not found - no commands loaded")
        }
        
        log("📊 CommandManager initialized with \(commands.count) commands")
    }
    
    // MARK: - Migration
    
    /// Migrate files from old project location to Documents folder
    private func migrateFromOldLocation() {
        let oldPaths = [
            "\(NSHomeDirectory())/Documents/VoiceCommandsLocal"  // Old folder without spaces
        ]
        
        for oldPath in oldPaths {
            guard FileManager.default.fileExists(atPath: oldPath) else { continue }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: oldPath)
                for file in files where file.hasSuffix(".json") {
                    let oldFile = "\(oldPath)/\(file)"
                    let newFile = "\(settingsStoragePath)/\(file)"
                    
                    // Only copy if file doesn't exist in new location
                    if !FileManager.default.fileExists(atPath: newFile) {
                        try FileManager.default.copyItem(atPath: oldFile, toPath: newFile)
                        print("Migrated: \(file) from \(oldPath)")
                    }
                }
            } catch {
                print("Migration error from \(oldPath): \(error)")
            }
        }
    }
    
    // MARK: - Registry Management
    
    /// Load commands from the default voice-commands.json file
    private func loadFromDefaultPath() {
        let path = getDefaultCommandsPath()
        
        guard FileManager.default.fileExists(atPath: path) else {
            log("❌ Default commands file not found: \(path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let registry = try decoder.decode(DynamicCommandRegistry.self, from: data)
            
            // Load SYNCHRONOUSLY so commands are available immediately
            self.commands = registry.commands
            self.currentRegistryPath = path
            log("✅ Loaded \(self.commands.count) commands from voice-commands.json")
        } catch {
            log("❌ Error loading commands from \(path): \(error)")
        }
    }
    
    /// Save commands to the default voice-commands.json file
    func saveToDefaultPath() {
        let path = getDefaultCommandsPath()
        var registry = DynamicCommandRegistry(commands: commands)
        registry.modifiedAt = Date()
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(registry)
            try data.write(to: URL(fileURLWithPath: path))
            self.currentRegistryPath = path
            log("💾 Saved \(commands.count) commands to voice-commands.json")
        } catch {
            log("❌ Error saving commands: \(error)")
        }
    }
    
    /// Load a command registry from a JSON file (for import)
    func loadRegistry(from path: String) {
        guard FileManager.default.fileExists(atPath: path) else {
            log("Registry file not found: \(path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let registry = try decoder.decode(DynamicCommandRegistry.self, from: data)
            self.commands = registry.commands
            self.currentRegistryPath = path
            log("✅ Imported \(commands.count) commands from \(path)")
            
            // After importing, save to default location
            saveToDefaultPath()
            
            // Trigger UI update
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            log("❌ Error loading registry from \(path): \(error)")
        }
    }
    
    /// Save current commands to a JSON file (for export)
    func saveRegistry(to path: String) {
        var registry = DynamicCommandRegistry(commands: commands)
        registry.modifiedAt = Date()
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(registry)
            try data.write(to: URL(fileURLWithPath: path))
            log("💾 Exported \(commands.count) commands to \(path)")
        } catch {
            log("❌ Error exporting registry: \(error)")
        }
    }
    
    /// Save to current registry path (deprecated - use saveToDefaultPath)
    func saveCurrentRegistry() {
        saveToDefaultPath()
    }
    
    /// Create a new empty registry
    func newRegistry(name: String) {
        commands = []
        saveToDefaultPath()
    }
    
    // MARK: - Command Management
    
    /// Add a new command
    func addCommand(_ command: DynamicCommand) {
        commands.append(command)
        saveToDefaultPath()
    }
    
    /// Update an existing command
    func updateCommand(_ command: DynamicCommand) {
        if let index = commands.firstIndex(where: { $0.id == command.id }) {
            var updated = command
            updated.modifiedAt = Date()
            commands[index] = updated
            saveToDefaultPath()
        }
    }
    
    /// Delete a command
    func deleteCommand(_ command: DynamicCommand) {
        commands.removeAll { $0.id == command.id }
        saveToDefaultPath()
    }
    
    /// Toggle command enabled status
    func toggleCommand(_ command: DynamicCommand) {
        if let index = commands.firstIndex(where: { $0.id == command.id }) {
            commands[index].enabled.toggle()
            commands[index].modifiedAt = Date()
            saveToDefaultPath()
        }
    }
    
    // MARK: - Command Execution
    
    /// Execute a command based on its action type
    func executeCommand(_ command: DynamicCommand) {
        guard command.enabled else { return }
        
        switch command.actionType {
        case .openFile:
            openFile(path: command.actionData)
        case .openURL:
            openURL(urlString: command.actionData)
        case .runShell:
            runShellScript(script: command.actionData)
        case .runAppleScript:
            runAppleScript(script: command.actionData)
        }
    }
    
    /// Match spoken text against command triggers and execute if found
    func matchAndExecute(_ text: String) -> DynamicCommand? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for command in commands where command.enabled {
            for trigger in command.triggers {
                if lower.contains(trigger.lowercased()) {
                    executeCommand(command)
                    return command
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Action Implementations
    
    private func openFile(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
        print("Opened file: \(path)")
    }
    
    private func openURL(urlString: String) {
        // Ensure URL has a scheme
        var finalURLString = urlString
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            finalURLString = "https://" + urlString
        }
        
        guard let url = URL(string: finalURLString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        NSWorkspace.shared.open(url)
        print("Opened URL: \(finalURLString)")
    }
    
    private func runShellScript(script: String) {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", script]
        
        do {
            try task.run()
            print("Executed shell script")
        } catch {
            print("Error running shell script: \(error)")
        }
    }
    
    private func runAppleScript(script: String) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            } else {
                print("Executed AppleScript")
            }
        }
    }
    
    // MARK: - Import/Export
    
    /// Import commands from a JSON file
    func importCommands(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let registry = try decoder.decode(DynamicCommandRegistry.self, from: data)
            
            // Merge imported commands with existing ones (avoid duplicates by ID)
            for importedCommand in registry.commands {
                if !commands.contains(where: { $0.id == importedCommand.id }) {
                    commands.append(importedCommand)
                }
            }
            
            saveCurrentRegistry()
            print("Imported \(registry.commands.count) commands from \(url.lastPathComponent)")
            
            // Trigger UI update
            objectWillChange.send()
        } catch {
            print("Error importing commands: \(error)")
        }
    }
    
    /// Export commands to a JSON file
    func exportCommands(to url: URL) {
        var registry = DynamicCommandRegistry(commands: commands)
        registry.modifiedAt = Date()
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(registry)
            try data.write(to: url)
            print("Exported \(commands.count) commands to \(url.lastPathComponent)")
        } catch {
            print("Error exporting commands: \(error)")
        }
    }
    
    /// Get list of available registry files
    func availableRegistries() -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: settingsStoragePath)
            return files.filter { $0.hasSuffix(".json") }
        } catch {
            print("Error listing registries: \(error)")
            return []
        }
    }
}
