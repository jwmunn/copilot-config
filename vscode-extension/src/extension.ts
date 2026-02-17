import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { AgentParser, AgentDefinition } from './agentParser';

// Agent IDs that match package.json chatParticipants
const AGENT_PARTICIPANT_IDS = [
	'mslearn-research',
	'mslearn-planning',
	'mslearn-implementation',
	'mslearn-code-review',
	'mslearn-test',
];

let participants: vscode.Disposable[] = [];
let loadedAgents: AgentDefinition[] = [];

// ── Activation ────────────────────────────────────────────────────────────────
export function activate(context: vscode.ExtensionContext) {
	console.log('MSLearn Copilot Agents extension activating…');

	loadAndRegister(context);

	context.subscriptions.push(
		vscode.commands.registerCommand('mslearn-copilot-agents.reload', () =>
			loadAndRegister(context)
		),
		vscode.commands.registerCommand('mslearn-copilot-agents.showInfo', showAgentsInfo)
	);

	// Hot-reload when agent files change
	const agentsDir = findAgentsDirectory();
	if (agentsDir) {
		const watcher = vscode.workspace.createFileSystemWatcher(
			new vscode.RelativePattern(vscode.Uri.file(agentsDir), '*.agent.md')
		);
		watcher.onDidChange(() => loadAndRegister(context));
		watcher.onDidCreate(() => loadAndRegister(context));
		watcher.onDidDelete(() => loadAndRegister(context));
		context.subscriptions.push(watcher);
	}
}

export function deactivate() {
	disposeParticipants();
}

// ── Core logic ────────────────────────────────────────────────────────────────
function loadAndRegister(context: vscode.ExtensionContext) {
	disposeParticipants();

	const agentsDir = findAgentsDirectory();

	if (!agentsDir) {
		console.log('MSLearn Copilot Agents: agents directory not found.');
		return;
	}

	const parser = new AgentParser(agentsDir);
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

		const handler: vscode.ChatRequestHandler = async (request, chatContext, stream, token) => {
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
async function handleAgentRequest(
	agent: AgentDefinition,
	request: vscode.ChatRequest,
	chatContext: vscode.ChatContext,
	stream: vscode.ChatResponseStream,
	token: vscode.CancellationToken
): Promise<vscode.ChatResult> {
	try {
		const systemPrompt = [
			`You are the "${agent.name}" agent. ${agent.description}`,
			'',
			agent.content,
		].join('\n');

		const messages: vscode.LanguageModelChatMessage[] = [
			vscode.LanguageModelChatMessage.User(systemPrompt),
		];

		for (const turn of chatContext.history) {
			if (turn instanceof vscode.ChatRequestTurn) {
				messages.push(vscode.LanguageModelChatMessage.User(turn.prompt));
			} else if (turn instanceof vscode.ChatResponseTurn) {
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
	} catch (err) {
		const msg = err instanceof Error ? err.message : String(err);
		stream.markdown(`\n\n**Error:** ${msg}`);
		return { errorDetails: { message: msg } };
	}
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function findAgentsDirectory(): string | null {
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
