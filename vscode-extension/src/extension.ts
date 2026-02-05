import * as vscode from 'vscode';
import * as path from 'path';
import { AgentParser } from './agentParser';
import { ChatParticipantManager } from './chatParticipants';

let participantManager: ChatParticipantManager;

export function activate(context: vscode.ExtensionContext) {
    console.log('MSLearn Copilot Agents extension is now active');

    // Initialize the participant manager
    participantManager = new ChatParticipantManager();

    // Load and register agents
    loadAndRegisterAgents(context);

    // Register command to reload agents
    const reloadCommand = vscode.commands.registerCommand(
        'mslearn-copilot-agents.reload',
        () => loadAndRegisterAgents(context)
    );

    // Register command to show agents info
    const showAgentsCommand = vscode.commands.registerCommand(
        'mslearn-copilot-agents.showInfo',
        showAgentsInfo
    );

    context.subscriptions.push(reloadCommand, showAgentsCommand);

    // Watch for changes to agent files
    watchAgentFiles(context);
}

export function deactivate() {
    if (participantManager) {
        participantManager.dispose();
    }
}

function loadAndRegisterAgents(context: vscode.ExtensionContext) {
    try {
        // Try to find the agents directory
        const agentsDir = findAgentsDirectory(context);
        
        if (!agentsDir) {
            vscode.window.showWarningMessage(
                'MSLearn Copilot Agents: Could not find agents directory. Please ensure the extension is in a workspace with copilot-config.'
            );
            return;
        }

        // Load agents
        const parser = new AgentParser(agentsDir);
        const agents = parser.loadAgents();

        if (agents.length === 0) {
            vscode.window.showInformationMessage('No agent files found in the copilot-config directory.');
            return;
        }

        // Register agents as chat participants
        participantManager.registerAgents(agents);

        vscode.window.showInformationMessage(
            `MSLearn Copilot Agents: Loaded ${agents.length} agents (${agents.map(a => '@' + a.name).join(', ')})`
        );

    } catch (error) {
        console.error('Error loading agents:', error);
        vscode.window.showErrorMessage(
            `MSLearn Copilot Agents: Error loading agents - ${error instanceof Error ? error.message : 'Unknown error'}`
        );
    }
}

function findAgentsDirectory(context: vscode.ExtensionContext): string | null {
    // Look for agents directory in workspace folders
    const workspaceFolders = vscode.workspace.workspaceFolders;
    
    if (workspaceFolders) {
        for (const folder of workspaceFolders) {
            const possiblePaths = [
                path.join(folder.uri.fsPath, 'copilot-config', '.github', 'agents'),
                path.join(folder.uri.fsPath, '.github', 'agents'),
                path.join(folder.uri.fsPath, '..', 'copilot-config', '.github', 'agents')
            ];
            
            for (const possiblePath of possiblePaths) {
                try {
                    const fs = require('fs');
                    if (fs.existsSync(possiblePath)) {
                        console.log(`Found agents directory: ${possiblePath}`);
                        return possiblePath;
                    }
                } catch (error) {
                    // Continue searching
                }
            }
        }
    }

    return null;
}

function watchAgentFiles(context: vscode.ExtensionContext) {
    const agentsDir = findAgentsDirectory(context);
    if (!agentsDir) {
        return;
    }

    // Watch for changes to agent files
    const watcher = vscode.workspace.createFileSystemWatcher(
        new vscode.RelativePattern(agentsDir, '*.agent.md')
    );

    watcher.onDidCreate(() => {
        console.log('Agent file created, reloading...');
        loadAndRegisterAgents(context);
    });

    watcher.onDidChange(() => {
        console.log('Agent file changed, reloading...');
        loadAndRegisterAgents(context);
    });

    watcher.onDidDelete(() => {
        console.log('Agent file deleted, reloading...');
        loadAndRegisterAgents(context);
    });

    context.subscriptions.push(watcher);
}

function showAgentsInfo() {
    const agentParser = new AgentParser();
    const agents = agentParser.loadAgents();
    
    const info = agents.map(agent => 
        `**@${agent.name}**: ${agent.description}`
    ).join('\\n\\n');
    
    vscode.window.showInformationMessage(
        `Available MSLearn Agents:\\n\\n${info}`,
        { modal: true, detail: 'Use @agent-name in the chat to invoke any of these agents.' }
    );
}