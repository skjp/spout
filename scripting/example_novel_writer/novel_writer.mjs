#!/usr/bin/env node

import { $, fs } from 'zx';
import { argv } from 'zx';
import { fileURLToPath } from 'url';
import { resolve, join } from 'path';

console.log('\n📚 Book Writer Pipeline Initializing...');

/**
 * Creates the project directory structure
 */
async function createProjectStructure(timestamp) {
    const baseDir = `../output/book_writer_output/${timestamp}`;
    const dirs = ['outline'];

    for (const dir of dirs) {
        await fs.mkdir(join(baseDir, dir), { recursive: true });
    }
    return baseDir;
}

/**
 * Generates the initial story outline using Imagine module
 */
async function generateInitialOutline() {
    console.log('🌟 Generating story outline...');
    try {
        console.log('Executing spout imagine command...');
        
        // Create the input text with proper escaping
        const objective = "Write a 7 part outline for a comedy movie about a talking horse who lives in Florida"
            .replace(/'/g, "'\\''")
            .replace(/"/g, '\\"')
            .replace(/\$/g, '\\$');
            
        const context = "Outline for a comedy movie about a talking horse who lives in Florida"
            .replace(/'/g, "'\\''")
            .replace(/"/g, '\\"')
            .replace(/\$/g, '\\$');
            
        const format = "JSON with multisectional structure; each section should have a Description describing the section and Details listing key scenes"
            .replace(/'/g, "'\\''")
            .replace(/"/g, '\\"')
            .replace(/\$/g, '\\$');
            
        const stipulations = "Use whimsical tone, ensure family-friendly content, maintain narrative flow between sections, and interesting characters and topics"
            .replace(/'/g, "'\\''")
            .replace(/"/g, '\\"')
            .replace(/\$/g, '\\$');

        // Log the command for debugging
        console.log('Command parameters:');
        console.log('- Objective:', objective);
        console.log('- Context:', context);
        console.log('- Format:', format);
        console.log('- Stipulations:', stipulations);

        const outline = await $`spout imagine -u outline \
            --objective "${objective}" \
            --context "${context}" \
            --output-format "${format}" \
            --stipulations "${stipulations}"`;

        // Log the raw output
        console.log('\nRaw output from spout:');
        console.log(outline.stdout);
        console.log('\nAttempting to parse output...');

        // For now, just return the raw output
        return outline.stdout;

    } catch (error) {
        console.error('Error in outline generation:', error);
        throw error;
    }
}

/**
 * Expands each section of the outline into detailed text
 */
async function expandSections(outlineData, projectDir) {
    console.log('📝 Expanding sections into detailed text...');
    const expandedSections = [];

    for (const [index, chapter] of outlineData.Plan.entries()) {
        console.log(`Expanding chapter ${index + 1}...`);
        try {
            // Create the input prompt in the correct format
            const prompt = `[${chapter.Description}] (${chapter.Details.join(', ')}) {use child-friendly language, include dialogue, and maintain a whimsical tone}`
                .replace(/'/g, "'\\''")
                .replace(/"/g, '\\"')
                .replace(/\$/g, '\\$');

            const expanded = await $`spout expand -u develop "${prompt}"`;
            expandedSections.push(expanded.stdout);
        } catch (error) {
            console.error(`Error expanding chapter ${index + 1}:`, error);
            throw error;
        }
    }

    // Write all expanded sections to a single file
    const fullStory = expandedSections.join('\n\n');
    await fs.writeFile(
        `${projectDir}/outline/expanded_story.txt`,
        fullStory
    );

    console.log('✨ Section expansion complete!');
    return fullStory;
}

/**
 * Main book generation process
 */
async function generateBook() {
    const timestamp = new Date().toISOString().replace(/[:\-T]/g, '').split('.')[0];
    const projectDir = await createProjectStructure(timestamp);
    
    try {
        // Phase 1: Generate Initial Outline
        const outline = await generateInitialOutline();
        
        // Parse the JSON output
        const outlineData = JSON.parse(outline);
        
        // Format the outline in the desired structure
        const formattedOutline = outlineData.Plan.map(chapter => {
            return `[${chapter.Description}](${chapter.Details.join(')(')})`;
        }).join('\n\n');
        
        // Save the formatted output
        await fs.writeFile(
            `${projectDir}/outline/structure.txt`, 
            formattedOutline
        );

        // Phase 2: Expand sections into full story
        await expandSections(outlineData, projectDir);
        
        console.log('📖 Book generation complete!');
        console.log(`📂 Output directory: ${projectDir}`);
        return projectDir;
    } catch (error) {
        console.error('Error during book generation:', error);
        throw error;
    }
}

// Command line execution
if (import.meta.url.startsWith('file:')) {
    generateBook().catch(error => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
}

export { generateBook };
