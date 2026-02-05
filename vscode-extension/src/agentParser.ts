import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'yaml';

export interface AgentDefinition {
    name: string;
    description: string;
    tools: string[];
    content: string;
    filePath: string;
}

export class AgentParser {
    private agentsDir: string;

    constructor(configDir: string = '') {
        // Default to looking for agents relative to the extension
        this.agentsDir = configDir || path.join(__dirname, '..', '..', '.github', 'agents');
    }

    /**
     * Parse frontmatter from markdown content
     */
    private parseFrontmatter(content: string): { frontmatter: any; content: string } {
        const lines = content.split('\n');
        
        // Check if the file starts with frontmatter delimiter
        if (lines[0].trim() !== '---') {
            return { frontmatter: {}, content };
        }

        // Find the end of frontmatter
        let endIndex = -1;
        for (let i = 1; i < lines.length; i++) {
            if (lines[i].trim() === '---') {
                endIndex = i;
                break;
            }
        }

        if (endIndex === -1) {
            return { frontmatter: {}, content };
        }

        // Extract and parse frontmatter
        const frontmatterText = lines.slice(1, endIndex).join('\n');
        const markdownContent = lines.slice(endIndex + 1).join('\n');

        let frontmatter = {};
        try {
            frontmatter = yaml.parse(frontmatterText) || {};
        } catch (error) {
            console.error(`Error parsing frontmatter: ${error}`);
        }

        return { frontmatter, content: markdownContent };
    }

    /**
     * Load all agent definitions from the agents directory
     */
    public loadAgents(): AgentDefinition[] {
        const agents: AgentDefinition[] = [];

        if (!fs.existsSync(this.agentsDir)) {
            console.warn(`Agents directory not found: ${this.agentsDir}`);
            return agents;
        }

        const files = fs.readdirSync(this.agentsDir);
        
        for (const file of files) {
            if (!file.endsWith('.agent.md')) {
                continue;
            }

            const filePath = path.join(this.agentsDir, file);
            
            try {
                const content = fs.readFileSync(filePath, 'utf-8');
                const { frontmatter, content: markdownContent } = this.parseFrontmatter(content);

                if (frontmatter.name && frontmatter.description) {
                    agents.push({
                        name: frontmatter.name,
                        description: frontmatter.description,
                        tools: frontmatter.tools || [],
                        content: markdownContent,
                        filePath
                    });
                } else {
                    console.warn(`Agent file missing required frontmatter: ${file}`);
                }
            } catch (error) {
                console.error(`Error loading agent file ${file}: ${error}`);
            }
        }

        return agents;
    }

    /**
     * Update the agents directory path
     */
    public setAgentsDir(dir: string): void {
        this.agentsDir = dir;
    }
}