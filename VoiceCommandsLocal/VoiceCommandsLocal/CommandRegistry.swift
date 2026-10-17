//
//  CommandRegistry.swift
//  VoiceCommandsLocal
//
//  Centralized voice command registration and execution
//

import Foundation
import AppKit

/**
 Represents a single voice command with its triggers and action.
 
 Example:
 ```
 VoiceCommand(
     triggers: ["google this", "search google"],
     description: "Opens Google in browser",
     category: .web
 ) {
     NSWorkspace.shared.open(URL(string: "https://google.com")!)
 }
 ```
 */
struct VoiceCommand {
    let triggers: [String]           // Phrases that trigger this command
    let description: String          // Human-readable description
    let category: CommandCategory    // Category for organization
    let action: () -> Void          // Code to execute
    
    enum CommandCategory: String {
        case web = "Web"
        case app = "Applications"
        case system = "System"
        case file = "Files"
        case media = "Media"
        case custom = "Custom"
    }
}

/**
 Central registry for all voice commands.
 
 Usage:
 ```
 let registry = CommandRegistry()
 registry.registerDefaultCommands()
 
 if let result = registry.execute("google this") {
     print("Executed: \(result.description)")
 }
 ```
 */
class CommandRegistry {
    
    // MARK: - Properties
    
    private var commands: [VoiceCommand] = []
    
    // MARK: - Registration
    
    /// Register a single command
    func register(_ command: VoiceCommand) {
        commands.append(command)
    }
    
    /// Register multiple commands at once
    func register(_ commands: [VoiceCommand]) {
        self.commands.append(contentsOf: commands)
    }
    
    /// Register all default commands
    func registerDefaultCommands() {
        // Web commands
        register(VoiceCommand(
            triggers: ["google this", "search google", "open google"],
            description: "Opens Google in browser",
            category: .web
        ) {
            NSWorkspace.shared.open(URL(string: "https://google.com")!)
        })
        
        // Add more default commands here as you build them
        // Example:
        // register(VoiceCommand(
        //     triggers: ["open youtube", "youtube"],
        //     description: "Opens YouTube",
        //     category: .web
        // ) {
        //     NSWorkspace.shared.open(URL(string: "https://youtube.com")!)
        // })
    }
    
    // MARK: - Execution
    
    /**
     Execute a command based on spoken text.
     
     - Parameter text: The transcribed speech text
     - Returns: The matched command if found, nil otherwise
     */
    func execute(_ text: String) -> VoiceCommand? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find first matching command
        for command in commands {
            for trigger in command.triggers {
                if lower.contains(trigger.lowercased()) {
                    command.action()
                    return command
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Query
    
    /// Get all registered commands
    func allCommands() -> [VoiceCommand] {
        return commands
    }
    
    /// Get commands by category
    func commands(in category: VoiceCommand.CommandCategory) -> [VoiceCommand] {
        return commands.filter { $0.category == category }
    }
    
    /// Get total number of registered commands
    var count: Int {
        return commands.count
    }
    
    /// Clear all registered commands
    func clear() {
        commands.removeAll()
    }
}
