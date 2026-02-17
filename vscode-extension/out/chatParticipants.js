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
exports.ChatParticipantManager = void 0;
const vscode = __importStar(require("vscode"));
class ChatParticipantManager {
    constructor() {
        this.participants = [];
    }
    /**
     * Register all agents as chat participants
     */
    registerAgents(agents) {
        // Clear existing participants
        this.dispose();
        for (const agent of agents) {
            const participant = this.createChatParticipant(agent);
            this.participants.push(participant);
        }
        console.log(`Registered ${agents.length} MSLearn agents as chat participants`);
    }
    /**
     * Create a chat participant for a single agent
     */
    createChatParticipant(agent) {
        const participant = vscode.chat.createChatParticipant(agent.name, this.createRequestHandler(agent));
        // Set participant properties
        participant.iconPath = vscode.Uri.file(
        // Use a default icon, you can customize this
        vscode.extensions.getExtension('mslearn.mslearn-copilot-agents')?.extensionPath + '/icon.png');
        participant.followupProvider = {
            provideFollowups: (result, context, token) => {
                return this.getFollowupQuestions(agent, result, context);
            }
        };
        console.log(`Registered chat participant: @${agent.name}`);
        return participant;
    }
    /**
     * Create the request handler for an agent
     */
    createRequestHandler(agent) {
        return async (request, context, stream, token) => {
            try {
                // Add agent description as context
                stream.markdown(`**${agent.name}**: ${agent.description}\n\n`);
                // Parse the user's request
                const userPrompt = request.prompt || '';
                // Create the agent prompt by combining the user request with the agent's content
                const agentPrompt = this.buildAgentPrompt(agent, userPrompt, context);
                // Select a chat model (prefer Claude, fall back to any Copilot model)
                const models = await vscode.lm.selectChatModels({
                    vendor: 'copilot'
                });
                if (models.length === 0) {
                    stream.markdown('❌ No language models available. Please ensure GitHub Copilot is enabled.');
                    return { errorDetails: { message: 'No models available' } };
                }
                const model = models[0];
                const messages = [
                    vscode.LanguageModelChatMessage.User(agentPrompt)
                ];
                // Send the request and stream the response
                const response = await model.sendRequest(messages, {}, token);
                for await (const fragment of response.text) {
                    if (token.isCancellationRequested) {
                        break;
                    }
                    stream.markdown(fragment);
                }
                return { metadata: { command: agent.name } };
            }
            catch (error) {
                stream.markdown(`❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
                return { errorDetails: { message: 'Failed to process request' } };
            }
        };
    }
    /**
     * Build the complete prompt for the agent
     */
    buildAgentPrompt(agent, userPrompt, context) {
        const systemPrompt = `You are ${agent.name}. ${agent.description}

${agent.content}

---

User Request: ${userPrompt}

Please respond according to your agent instructions above.`;
        return systemPrompt;
    }
    /**
     * Get followup questions for an agent
     */
    getFollowupQuestions(agent, result, context) {
        // Provide some generic followup questions based on the agent type
        const followups = [];
        if (agent.name.includes('research')) {
            followups.push({ prompt: 'Can you analyze the codebase structure?', label: '🔍 Analyze codebase' }, { prompt: 'What are the key dependencies?', label: '📦 Check dependencies' }, { prompt: 'Generate architecture diagram', label: '📊 Architecture diagram' });
        }
        else if (agent.name.includes('planning')) {
            followups.push({ prompt: 'Create implementation timeline', label: '📅 Timeline' }, { prompt: 'Break down into smaller tasks', label: '✅ Task breakdown' }, { prompt: 'Identify potential risks', label: '⚠️ Risk analysis' });
        }
        else if (agent.name.includes('review')) {
            followups.push({ prompt: 'Review for security issues', label: '🔒 Security review' }, { prompt: 'Check coding standards', label: '📋 Standards check' }, { prompt: 'Performance analysis', label: '⚡ Performance' });
        }
        return followups;
    }
    /**
     * Dispose of all registered participants
     */
    dispose() {
        this.participants.forEach(p => p.dispose());
        this.participants = [];
    }
}
exports.ChatParticipantManager = ChatParticipantManager;
