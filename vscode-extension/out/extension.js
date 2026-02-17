"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const path = __importStar(require("path"));
const fs = __importStar(require("fs"));
const agentParser_1 = require("./agentParser");
// Agent IDs that match package.json chatParticipants
const AGENT_PARTICIPANT_IDS = [
    'mslearn-research',
    'mslearn-planning',
    'mslearn-implementation',
    'mslearn-code-review',
    'mslearn-test',
];
let participants = [];
let loadedAgents = [];
// ── Activation ────────────────────────────────────────────────────────────────
function activate(context) {
    console.log('MSLearn Copilot Agents extension activating…');
    loadAndRegister(context);
    context.subscriptions.push(vscode.commands.registerCommand('mslearn-copilot-agents.reload', () => loadAndRegister(context)), vscode.commands.registerCommand('mslearn-copilot-agents.showInfo', showAgentsInfo));
    // Hot-reload when agent files change
    const agentsDir = findAgentsDirectory();
    if (agentsDir) {
        const watcher = vscode.workspace.createFileSystemWatcher(new vscode.RelativePattern(vscode.Uri.file(agentsDir), '*.agent.md'));
        watcher.onDidChange(() => loadAndRegister(context));
        watcher.onDidCreate(() => loadAndRegister(context));
        watcher.onDidDelete(() => loadAndRegister(context));
        context.subscriptions.push(watcher);
    }
}
function deactivate() {
    disposeParticipants();
}
// ── Core logic ────────────────────────────────────────────────────────────────
function loadAndRegister(context) {
    disposeParticipants();
    const agentsDir = findAgentsDirectory();
    if (!agentsDir) {
        console.log('MSLearn Copilot Agents: agents directory not found.');
        return;
    }
    const parser = new agentParser_1.AgentParser(agentsDir);
    loadedAgents = parser.loadAgents();
    if (loadedAgents.length === 0) {
        console.log('MSLearn Copilot Agents: no .agent.md files found.');
        return;
    }
    // Register agent participants only
    for (const agent of loadedAgents) {
        if (!AGENT_PARTICIPANT_IDS.includes(agent.name)) {
            continue;
        }
        const handler = async (request, chatContext, stream, token) => {
            return handleAgentRequest(agent, request, chatContext, stream, token);
        };
        const participant = vscode.chat.createChatParticipant(agent.name, handler);
        participant.iconPath = vscode.Uri.joinPath(context.extensionUri, 'icon.png');
        participants.push(participant);
        console.log(`Registered @${agent.name}`);
    }
    console.log(`MSLearn: ${participants.length} agents loaded.`);
}
// ── Agent handler ─────────────────────────────────────────────────────────────
async function handleAgentRequest(agent, request, chatContext, stream, token) {
    try {
        const systemPrompt = [
            `You are the "${agent.name}" agent. ${agent.description}`,
            '',
            agent.content,
        ].join('\n');
        const messages = [
            vscode.LanguageModelChatMessage.User(systemPrompt),
        ];
        for (const turn of chatContext.history) {
            if (turn instanceof vscode.ChatRequestTurn) {
                messages.push(vscode.LanguageModelChatMessage.User(turn.prompt));
            }
            else if (turn instanceof vscode.ChatResponseTurn) {
                let text = '';
                for (const part of turn.response) {
                    if (part instanceof vscode.ChatResponseMarkdownPart) {
                        text += part.value.value;
                    }
                }
                if (text) {
                    messages.push(vscode.LanguageModelChatMessage.Assistant(text));
                }
            }
        }
        messages.push(vscode.LanguageModelChatMessage.User(request.prompt));
        const chatResponse = await request.model.sendRequest(messages, {}, token);
        for await (const fragment of chatResponse.text) {
            if (token.isCancellationRequested) {
                break;
            }
            stream.markdown(fragment);
        }
        return {};
    }
    catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        stream.markdown(`\n\n**Error:** ${msg}`);
        return { errorDetails: { message: msg } };
    }
}
// ── Helpers ───────────────────────────────────────────────────────────────────
function findAgentsDirectory() {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders) {
        return null;
    }
    const candidates = folders.flatMap(f => [
        path.join(f.uri.fsPath, '.github', 'agents'),
        path.join(f.uri.fsPath, 'copilot-config', '.github', 'agents'),
    ]);
    for (const f of folders) {
        const sibling = path.join(f.uri.fsPath, '..', 'copilot-config', '.github', 'agents');
        candidates.push(path.resolve(sibling));
    }
    for (const candidate of candidates) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    return null;
}
function showAgentsInfo() {
    const agentLines = loadedAgents
        .filter(a => AGENT_PARTICIPANT_IDS.includes(a.name))
        .map(a => `@${a.name}`);
    const message = agentLines.length
        ? `Agents: ${agentLines.join(', ')}\n\nWorkflows: /mslearn-* (native VS Code prompts)\nSkills: .github/skills/ (SKILL.md packages)`
        : 'No agents loaded.';
    vscode.window.showInformationMessage(message);
}
function disposeParticipants() {
    for (const p of participants) {
        p.dispose();
    }
    participants = [];
}
