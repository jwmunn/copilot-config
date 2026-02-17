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
exports.AgentParser = void 0;
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const yaml = __importStar(require("yaml"));
class AgentParser {
    constructor(agentsDir) {
        this.agentsDir = agentsDir;
    }
    /**
     * Parse YAML frontmatter from a chatagent/markdown file
     */
    parseFrontmatter(raw) {
        const lines = raw.split('\n');
        // Skip optional code fence like ```chatagent
        let start = 0;
        if (/^```/.test(lines[0].trim())) {
            start = 1;
        }
        if (lines[start]?.trim() !== '---') {
            return { frontmatter: {}, body: raw };
        }
        let endIndex = -1;
        for (let i = start + 1; i < lines.length; i++) {
            if (lines[i].trim() === '---') {
                endIndex = i;
                break;
            }
        }
        if (endIndex === -1) {
            return { frontmatter: {}, body: raw };
        }
        const fmText = lines.slice(start + 1, endIndex).join('\n');
        const body = lines.slice(endIndex + 1).join('\n');
        try {
            return { frontmatter: yaml.parse(fmText) ?? {}, body };
        }
        catch {
            return { frontmatter: {}, body: raw };
        }
    }
    /**
     * Load all agent definitions from the agents directory
     */
    loadAgents() {
        const agents = [];
        if (!fs.existsSync(this.agentsDir)) {
            console.warn(`Agents directory not found: ${this.agentsDir}`);
            return agents;
        }
        for (const file of fs.readdirSync(this.agentsDir)) {
            if (!file.endsWith('.agent.md')) {
                continue;
            }
            const filePath = path.join(this.agentsDir, file);
            try {
                const raw = fs.readFileSync(filePath, 'utf-8');
                const { frontmatter, body } = this.parseFrontmatter(raw);
                const name = frontmatter.name;
                const description = frontmatter.description;
                if (name && description) {
                    agents.push({
                        name,
                        description,
                        tools: frontmatter.tools ?? [],
                        content: body,
                        filePath,
                    });
                }
            }
            catch (err) {
                console.error(`Error loading agent file ${file}:`, err);
            }
        }
        return agents;
    }
}
exports.AgentParser = AgentParser;
