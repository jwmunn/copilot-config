#!/usr/bin/env node

const { exec, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 MSLearn Copilot Agents - Installation Script');
console.log('================================================');

const extensionDir = __dirname;
process.chdir(extensionDir);

async function runCommand(command, description) {
    return new Promise((resolve, reject) => {
        console.log(`\\n📦 ${description}...`);
        exec(command, (error, stdout, stderr) => {
            if (error) {
                console.error(`❌ Error: ${error.message}`);
                reject(error);
                return;
            }
            if (stderr) {
                console.log(`⚠️  ${stderr}`);
            }
            console.log(stdout);
            resolve(stdout);
        });
    });
}

async function main() {
    try {
        // Check if npm is available
        await runCommand('npm --version', 'Checking npm');

        // Install dependencies
        await runCommand('npm install', 'Installing dependencies');

        // Compile TypeScript
        await runCommand('npm run compile', 'Compiling TypeScript');

        // Package the extension
        console.log('\\n📦 Packaging extension...');
        await runCommand('npm run package', 'Creating VSIX package');

        // Find the generated VSIX file
        const files = fs.readdirSync(extensionDir);
        const vsixFile = files.find(file => file.endsWith('.vsix'));

        if (!vsixFile) {
            throw new Error('VSIX file not found after packaging');
        }

        console.log(`\\n✅ Extension packaged: ${vsixFile}`);

        // Install the extension
        console.log('\\n🔧 Installing extension in VS Code...');
        await runCommand(`code --install-extension ${vsixFile}`, 'Installing extension');

        console.log('\\n🎉 Installation completed successfully!');
        console.log('\\n📋 Next steps:');
        console.log('1. Restart VS Code');
        console.log('2. Open a workspace with copilot-config directory');
        console.log('3. Use @mslearn-research, @mslearn-planning, etc. in the chat');
        console.log('\\n💡 Use Ctrl+Shift+P and search "MSLearn" to see available commands');

    } catch (error) {
        console.error('\\n❌ Installation failed:', error.message);
        console.log('\\n🔧 Manual installation steps:');
        console.log('1. cd vscode-extension');
        console.log('2. npm install');
        console.log('3. npm run compile');
        console.log('4. npm run package');
        console.log('5. code --install-extension *.vsix');
        process.exit(1);
    }
}

main();