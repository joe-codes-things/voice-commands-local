//
//  CommandSettingsView.swift
//  VoiceCommandsLocal
//
//  Modal UI for managing dynamic voice commands
//

import SwiftUI
import UniformTypeIdentifiers

struct CommandSettingsView: View {
    @ObservedObject var commandManager: CommandManager
    @Binding var isPresented: Bool
    
    @State private var showingAddCommand = false
    @State private var editingCommand: DynamicCommand?
    @State private var searchText = ""
    
    var filteredCommands: [DynamicCommand] {
        if searchText.isEmpty {
            return commandManager.commands
        }
        return commandManager.commands.filter { command in
            command.triggers.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        // Modal content
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Search bar
            searchBar
            
            // Command list
            commandList
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Footer with actions
            footer
        }
        .background(Color.deepBlack)
        .sheet(isPresented: $showingAddCommand) {
            CommandEditView(commandManager: commandManager, command: nil, isPresented: $showingAddCommand)
        }
        .sheet(item: $editingCommand) { command in
            CommandEditView(commandManager: commandManager, command: command, isPresented: Binding(
                get: { editingCommand != nil },
                set: { if !$0 { editingCommand = nil } }
            ))
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Voice Commands")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(commandManager.commands.count) commands")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Search commands...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Command List
    
    private var commandList: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredCommands) { command in
                        CommandRow(command: command,
                                 onToggle: { commandManager.toggleCommand(command) },
                                 onEdit: { editingCommand = command },
                                 onDelete: { commandManager.deleteCommand(command) })
                    }
                }
                .padding(20)
            }
            
            // Display loaded filename at bottom right
            HStack {
                Spacer()
                if let path = commandManager.currentRegistryPath {
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 12) {
            Button(action: { showingAddCommand = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Command")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.neonBlue)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: importCommands) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Open")
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            
            Button(action: exportCommands) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Save")
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
    
    // MARK: - Import/Export Functions
    
    private func importCommands() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        panel.message = "Select a JSON file to import commands"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                commandManager.importCommands(from: url)
            }
        }
    }
    
    private func exportCommands() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "voice-commands.json"
        panel.message = "Export commands to JSON file"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                commandManager.exportCommands(to: url)
            }
        }
    }
}

// MARK: - Command Row

struct CommandRow: View {
    let command: DynamicCommand
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Enable/Disable toggle
            Button(action: onToggle) {
                Image(systemName: command.enabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(command.enabled ? .neonBlue : .white.opacity(0.3))
            }
            .buttonStyle(.plain)
            
            // Action type icon
            Image(systemName: command.actionType.icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)
            
            // Command info
            VStack(alignment: .leading, spacing: 4) {
                Text(command.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(command.enabled ? .white : .white.opacity(0.5))
                
                // Trigger phrases
                Text(command.triggers.joined(separator: ", "))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
                
                Text(command.actionType.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.neonBlue)
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(command.enabled ? 0.05 : 0.02))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(command.enabled ? Color.neonBlue.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Command Edit View

struct CommandEditView: View {
    @ObservedObject var commandManager: CommandManager
    let command: DynamicCommand?
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var triggers: String = ""
    @State private var actionType: DynamicCommand.ActionType = .openURL
    @State private var actionData: String = ""
    @State private var enabled: Bool = true
    
    var isEditing: Bool { command != nil }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Command" : "New Command")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Command Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Command Title")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        TextField("Open Firefox", text: $title)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    // Trigger phrase(s)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trigger Phrase(s)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        TextField("open youtube, close all apps, etc.", text: $triggers)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        
                        Text("Separate multiple phrases with commas")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Action type - Individual buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Action Type")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            // Open File button
                            Button(action: { actionType = .openFile }) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .frame(width: 20)
                                    Text("Open File")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                    Spacer()
                                    if actionType == .openFile {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.neonBlue)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(12)
                                .background(actionType == .openFile ? Color.neonBlue.opacity(0.2) : Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(actionType == .openFile ? Color.neonBlue : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Open URL button
                            Button(action: { actionType = .openURL }) {
                                HStack {
                                    Image(systemName: "link")
                                        .frame(width: 20)
                                    Text("Open URL")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                    Spacer()
                                    if actionType == .openURL {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.neonBlue)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(12)
                                .background(actionType == .openURL ? Color.neonBlue.opacity(0.2) : Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(actionType == .openURL ? Color.neonBlue : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Run Shell Script button
                            Button(action: { actionType = .runShell }) {
                                HStack {
                                    Image(systemName: "terminal.fill")
                                        .frame(width: 20)
                                    Text("Run Shell Script")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                    Spacer()
                                    if actionType == .runShell {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.neonBlue)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(12)
                                .background(actionType == .runShell ? Color.neonBlue.opacity(0.2) : Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(actionType == .runShell ? Color.neonBlue : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Run AppleScript button
                            Button(action: { actionType = .runAppleScript }) {
                                HStack {
                                    Image(systemName: "applescript")
                                        .frame(width: 20)
                                    Text("Run AppleScript")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                    Spacer()
                                    if actionType == .runAppleScript {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.neonBlue)
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(12)
                                .background(actionType == .runAppleScript ? Color.neonBlue.opacity(0.2) : Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(actionType == .runAppleScript ? Color.neonBlue : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Action data
                    VStack(alignment: .leading, spacing: 8) {
                        Text(actionDataLabel)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if actionType == .openFile {
                            // File picker button
                            HStack {
                                Text(actionData.isEmpty ? "No file selected" : actionData)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(actionData.isEmpty ? .white.opacity(0.5) : .white)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
                                Button(action: selectFile) {
                                    Text("Browse...")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.neonBlue)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        } else if actionType == .runShell || actionType == .runAppleScript {
                            ZStack(alignment: .topLeading) {
                                if actionData.isEmpty {
                                    Text(actionType == .runShell ? "Paste Shell Script here" : "Paste AppleScript here")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.5))
                                        .padding(8)
                                }
                                TextEditor(text: $actionData)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(height: 150)
                                    .padding(8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        } else {
                            TextField(actionDataPlaceholder, text: $actionData)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(20)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Footer
            HStack {
                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: saveCommand) {
                    Text(isEditing ? "Save Changes" : "Create Command")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.neonBlue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
            .padding(20)
        }
        .frame(width: 600, height: 600)
        .background(Color.deepBlack)
        .cornerRadius(16)
        .onAppear {
            if let command = command {
                title = command.title
                triggers = command.triggers.joined(separator: ", ")
                actionType = command.actionType
                actionData = command.actionData
                enabled = command.enabled
            }
        }
    }
    
    private var actionDataLabel: String {
        switch actionType {
        case .openFile: return "File"
        case .openURL: return "URL"
        case .runShell: return "Shell Script"
        case .runAppleScript: return "AppleScript"
        }
    }
    
    private var actionDataPlaceholder: String {
        switch actionType {
        case .openFile: return "/path/to/file"
        case .openURL: return "https://example.com"
        case .runShell: return "echo 'Hello'"
        case .runAppleScript: return "display dialog \"Hello\""
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !triggers.isEmpty && !actionData.isEmpty
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select a file to open with this command"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                actionData = url.path
            }
        }
    }
    
    private func saveCommand() {
        let triggerArray = triggers.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        if let existing = command {
            var updated = existing
            updated.title = title
            updated.triggers = triggerArray
            updated.actionType = actionType
            updated.actionData = actionData
            updated.enabled = enabled
            commandManager.updateCommand(updated)
        } else {
            let newCommand = DynamicCommand(
                title: title,
                triggers: triggerArray,
                actionType: actionType,
                actionData: actionData,
                category: "Custom",
                enabled: enabled
            )
            commandManager.addCommand(newCommand)
        }
        
        isPresented = false
    }
}
