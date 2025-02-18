#!/usr/bin/env node

import { $, fs } from 'zx';
import { argv } from 'zx';
import { fileURLToPath } from 'url';
import { resolve, join } from 'path';

const {
    threads = 1,
    genre,
    style,
    outline
} = argv;

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
        const objective = `Write a 7 part outline for a ${genre ? genre : 'comedy'} story ${style ? `with a ${style} writing style` : ''}`
            .replace(/'/g, "'\\''")
            .replace(/"/g, '\\"')
            .replace(/\$/g, '\\$');
            
        const context = `Outline for a ${genre ? genre : 'comedy'} story ${style ? `using ${style} writing style` : ''}`
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

        const outline = await $`spout imagine -u outline \
            --objective "${objective}" \
            --context "${context}" \
            --output-format "${format}" \
            --stipulations "${stipulations}"`;

        // Try to parse the JSON output
        try {
            const parsedOutline = JSON.parse(outline.stdout.trim());
            return parsedOutline;
        } catch (parseError) {
            console.error('Failed to parse outline JSON:', parseError);
            console.log('Raw output:', outline.stdout);
            throw new Error('Invalid outline format received');
        }

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
    
    // Validate outline data structure
    if (!outlineData || !outlineData.Plan || !Array.isArray(outlineData.Plan)) {
        throw new Error('Invalid outline data structure');
    }
    
    // Create a pool of promises to handle parallel processing
    const maxConcurrent = parseInt(threads) || 2;
    
    // Process chapters in batches
    for (let i = 0; i < outlineData.Plan.length; i += maxConcurrent) {
        const batch = outlineData.Plan.slice(i, i + maxConcurrent);
        const batchPromises = batch.map(async (chapter, batchIndex) => {
            const index = i + batchIndex;
            console.log(`Expanding chapter ${index + 1}...`);
            try {
                if (!chapter.Description || !chapter.Details) {
                    throw new Error(`Invalid chapter data for chapter ${index + 1}`);
                }

                const prompt = `[${chapter.Description}] (${chapter.Details.join(', ')}) {use ${style ? style : 'child-friendly'} language, maintain appropriate tone for ${genre ? genre : 'general'} genre}`
                    .replace(/'/g, "'\\''")
                    .replace(/"/g, '\\"')
                    .replace(/\$/g, '\\$');

                const expanded = await $`spout expand -u develop "${prompt}"`;
                return expanded.stdout.trim();
            } catch (error) {
                console.error(`Error expanding chapter ${index + 1}:`, error);
                return `[Error expanding chapter ${index + 1}]`;
            }
        });

        try {
            const batchResults = await Promise.all(batchPromises);
            expandedSections.push(...batchResults);
        } catch (error) {
            console.error('Error processing batch:', error);
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
        const outlineData = await generateInitialOutline();
        
        // Validate outline data
        if (!outlineData || !outlineData.Plan) {
            throw new Error('Invalid outline data received');
        }
        
        // Format the outline in the desired structure
        const formattedOutline = outlineData.Plan.map(chapter => {
            if (!chapter.Description || !chapter.Details) {
                throw new Error('Invalid chapter data structure');
            }
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
        // Create error log file
        const errorLog = `Error occurred at ${new Date().toISOString()}\n${error.stack || error}`;
        await fs.writeFile(
            `${projectDir}/error.log`,
            errorLog
        ).catch(console.error);
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
