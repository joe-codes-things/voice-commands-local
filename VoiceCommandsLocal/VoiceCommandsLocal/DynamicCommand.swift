//
//  DynamicCommand.swift
//  VoiceCommandsLocal
//
//  Data model for user-configurable voice commands
//

import Foundation

/**
 Represents a user-configurable voice command that can be saved to/loaded from JSON.
 */
struct DynamicCommand: Identifiable, Codable {
    var id: UUID
    var title: String
    var triggers: [String]
    var actionType: ActionType
    var actionData: String
    var category: String
    var enabled: Bool
    var createdAt: Date
    var modifiedAt: Date
    
    enum ActionType: String, Codable, CaseIterable {
        case openFile = "Open File"
        case openURL = "Open URL"
        case runShell = "Run Shell Script"
        case runAppleScript = "Run AppleScript"
        
        var icon: String {
            switch self {
            case .openFile: return "doc.fill"
            case .openURL: return "link"
            case .runShell: return "terminal.fill"
            case .runAppleScript: return "applescript"
            }
        }
    }
    
    init(id: UUID = UUID(),
         title: String,
         triggers: [String],
         actionType: ActionType,
         actionData: String,
         category: String = "Custom",
         enabled: Bool = true) {
        self.id = id
        self.title = title
        self.triggers = triggers
        self.actionType = actionType
        self.actionData = actionData
        self.category = category
        self.enabled = enabled
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

/**
 Container for a collection of dynamic commands that can be saved as a registry file.
 */
struct DynamicCommandRegistry: Codable {
    var commands: [DynamicCommand]
    var version: String = "1.0"
    var createdAt: Date
    var modifiedAt: Date
    
    init(commands: [DynamicCommand] = []) {
        self.commands = commands
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}
