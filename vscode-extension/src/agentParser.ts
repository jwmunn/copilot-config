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
	constructor(private agentsDir: string) {}

	/**
	 * Parse YAML frontmatter from a chatagent/markdown file
	 */
	private parseFrontmatter(raw: string): { frontmatter: Record<string, unknown>; body: string } {
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
			return { frontmatter: (yaml.parse(fmText) as Record<string, unknown>) ?? {}, body };
		} catch {
			return { frontmatter: {}, body: raw };
		}
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

		for (const file of fs.readdirSync(this.agentsDir)) {
			if (!file.endsWith('.agent.md')) {
				continue;
			}

			const filePath = path.join(this.agentsDir, file);

			try {
				const raw = fs.readFileSync(filePath, 'utf-8');
				const { frontmatter, body } = this.parseFrontmatter(raw);

				const name = frontmatter.name as string | undefined;
				const description = frontmatter.description as string | undefined;

				if (name && description) {
					agents.push({
						name,
						description,
						tools: (frontmatter.tools as string[]) ?? [],
						content: body,
						filePath,
					});
				}
			} catch (err) {
				console.error(`Error loading agent file ${file}:`, err);
			}
		}

		return agents;
	}
}
