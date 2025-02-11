#!/usr/bin/env node

import { $, fs } from 'zx';
import { argv } from 'zx';
import { fileURLToPath } from 'url';
import { resolve } from 'path';
import readline from 'readline';

console.log('\n🚀 Script is loading...');

/**
 * Text Evolution Script
 * 
 * Modules used: Mutate, Evaluate, Reduce
 * 
 * This script takes a text input and evolves it sentence by sentence, generating 
 * and evaluating variants to create an improved version of the text. It uses the
 * reduce module to generate a description of the input text, which is then used
 * to guide the evaluation of variants.
 * 
 * Usage:
 *   ./text_evolve_pipeline.mjs [options]
 * 
 * Options:
 *   --example         Example text to evolve (default: story about animals meeting)
 *   --criteria        Comma-separated list of evaluation criteria 
 *                     (default: "quality, interesting, creative, coherent")
 *   --variants        Number of variants to generate per sentence (default: 5)
 *   --mutation        Level of mutation for variants (default: 1)
 *   --description     Optional custom description to guide evaluation
 * 
 * Process:
 *   1. Takes input text (from --example or default)
 *   2. Generates a description using reduce module with "description" spoutlet
 *   3. For each sentence:
 *      - Generates variants using mutate module
 *      - Evaluates variants considering both criteria and text description
 *      - Selects best variant for final composition
 *   4. Outputs evolved text and evaluation details
 * 
 * Examples:
 *   ./text_evolve_pipeline.mjs --example "The cat sat on the mat."
 *   ./text_evolve_pipeline.mjs --criteria "quality,creativity" --variants 3
 *   ./text_evolve_pipeline.mjs --example "Long text..." --mutation 2
 *   ./text_evolve_pipeline.mjs --criteria "humor,engagement" --variants 8 --mutation 3
 * 
 * Output:
 *   Creates a markdown file in ../output/text_evolve_pipeline_output/ containing:
 *   - Original text
 *   - Generated description
 *   - Evolution process for each sentence
 *   - Final evolved text
 */

// Default values
const DEFAULT_CRITERIA = "quality, interesting, creative, coherent";
const DEFAULT_NUM_VARIANTS = 5;
const DEFAULT_MUTATION_LEVEL = 1;
const DEFAULT_INPUT = "No input text provided.";

// Generate description using Reduce if not provided
async function generateDescription(input) {
    try {
        console.log('🎯 Generating story description...');
        const reduced = await $`spout reduce "${input}" --spoutlet "describe"`;
        return reduced.stdout.trim();
    } catch (error) {
        console.warn('⚠️ Description generation failed:', error);
        return "no description available";
    }
}

// Add this helper function at the top level
function sanitizeText(text) {
    return text
        // Replace em dashes and en dashes with regular hyphens
        .replace(/[��–]/g, '-')
        // Replace smart quotes with regular quotes
        .replace(/[""]/g, '"')
        .replace(/['']/g, "'")
        // Remove any other problematic characters
        .replace(/[`]/g, "'")
        // Escape remaining quotes
        .replace(/"/g, '\\"');
}

// Add function to get user input
async function promptUser(question) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            rl.close();
            resolve(answer);
        });
    });
}

async function evolveText(params = {}) {
    // Initialize parameters with defaults
    const criteria = params.criteria || argv.criteria || DEFAULT_CRITERIA;
    const numVariants = parseInt(params.variants || argv.variants) || DEFAULT_NUM_VARIANTS;
    const mutationLevel = parseInt(params.mutation || argv.mutation) || DEFAULT_MUTATION_LEVEL;
    
    // Get input text with user prompt if not provided
    let input = params.input || argv.input;
    if (!input || input === DEFAULT_INPUT) {
        console.log('\n📝 No input text provided.');
        input = await promptUser('Please enter the text you would like to evolve:\n> ');
        if (!input.trim()) {
            console.error('❌ No text provided. Exiting...');
            process.exit(1);
        }
    }
    
    // Get description (generate if not provided)
    const description = params.description || argv.description || await generateDescription(input);

    console.log('\n🌟 Starting Text Evolution Process');
    console.log('📋 Configuration:');
    console.log(`   Criteria: ${criteria}`);
    console.log(`   Variants: ${numVariants}`);
    console.log(`   Mutation Level: ${mutationLevel}`);
    console.log(`   Description: ${description}`);
    console.log(`   Example: ${input}`);
    
    const outputDir = '../output/text_evolve_pipeline_output';
    const timestamp = new Date().toISOString().replace(/[:\-T]/g, '').split('.')[0];
    const outputPath = `${outputDir}/evolution_${timestamp}.md`;
    await fs.mkdir(outputDir, { recursive: true });

    // Write initial content immediately
    await fs.writeFile(outputPath, '# Text Evolution Process\n\n');
    await fs.appendFile(outputPath, '## Original Text\n\n' + input + '\n\n');
    await fs.appendFile(outputPath, '## Generated Description\n\n' + description + '\n\n');
    
    // Split text into sentences
    const sentences = input
        .split(/(?<=[.!?])\s+/)
        .filter(s => s.trim().length > 0)
        .map(s => s.trim());
    
    const sentenceCount = sentences.length;
    console.log(`📝 Found ${sentenceCount} sentences to process`);
    
    // Track best variants for final composition
    const bestVariants = [];
    
    // Process each sentence
    for (let i = 0; i < sentenceCount; i++) {
        await fs.appendFile(outputPath, `\n## Sentence ${i + 1}\n\n`);
        await fs.appendFile(outputPath, `Original: "${sentences[i]}"\n\n`);
        
        const { variants, bestVariant, rankings } = await generateVariants(
            sentences[i],
            input,
            sentences,
            i,
            numVariants,
            mutationLevel,
            criteria,
            description
        );
        
        // Write variants concisely
        await fs.appendFile(outputPath, 'Generated Variants:\n');
        const variantsList = variants.map((variant, idx) => `${idx + 1}. "${variant}"`).join('\n');
        await fs.appendFile(outputPath, variantsList + '\n\n');
        
        // Write evaluation results in a clear format
        await fs.appendFile(outputPath, 'Evaluation Results:\n');
        if (rankings && rankings.length > 0) {
            const rankingsList = rankings.map(r => 
                `Rank ${r.Rank} (Score: ${r.Score})\n` +
                `Text: "${r.Text}"\n` +
                `Explanation: ${r.Explanation}\n`
            ).join('\n');
            await fs.appendFile(outputPath, rankingsList + '\n');
        }
        
        await fs.appendFile(outputPath, `Selected Best Variant: "${bestVariant}"\n\n`);
        bestVariants.push(bestVariant);
    }
    
    // Write final evolved text
    const finalParagraph = bestVariants.join(' ');
    await fs.appendFile(outputPath, '\n## Final Evolved Text\n\n' + finalParagraph + '\n');
}

// Update generateVariants to accept numVariants and mutationLevel
async function generateVariants(sentence, fullText, sentences, currentIndex, numVariants, mutationLevel, criteria, description) {
    console.log(`\n🧬 Generating variants for: "${sentence}"`);
    try {
        const mutations = await $`spout mutate --input "${sentence}" --num_variants "${numVariants}" --mutation_level "${mutationLevel}"`;
        
        const cleanOutput = mutations.stdout
            .replace(/```json\n?/g, '')
            .replace(/```\n?/g, '')
            .trim();
            
        const result = JSON.parse(cleanOutput);
        
        if (!result.variants || result.variants.length === 0) {
            console.warn('⚠️  No variants generated');
            return { variants: [], bestVariant: sentence };
        }
        
        // Clean up variants by removing any quote markers
        const cleanVariants = result.variants.map(variant => 
            variant.replace(/^\$?'|'$/g, '').trim()
        );
        
        // Create full paragraph variants
        const fullVariants = cleanVariants.map(variant => {
            const newSentences = [...sentences];
            newSentences[currentIndex] = variant;
            return newSentences.join(' ');
        });
        
        const { variant: bestVariant, rankings } = await evaluateVariants(fullVariants, criteria, description);
        
        const bestSentences = bestVariant.split(/(?<=[.!?])\s+/).filter(s => s.trim().length > 0);
        const bestSentence = bestSentences[currentIndex].replace(/^\$?'|'$/g, '').trim();
        
        return { 
            variants: fullVariants,
            bestVariant: bestSentence,
            rankings
        };
    } catch (error) {
        console.error('🚫 Error in generateVariants:', error);
        throw error;
    }
}

async function evaluateVariants(variants, criteria, description) {
    console.log('\n⚖️  Evaluating variants...');
    try {
        const combinedInputs = variants.join('@@');
        const contextualCriteria = `${criteria}, appropriateness for use in the following type of text: ${description}`;
        
        process.env.SPOUT_INPUTS = combinedInputs;
        process.env.SPOUT_CRITERIA = contextualCriteria;
        
        const evaluation = await $`spout evaluate --combined-inputs "$SPOUT_INPUTS" --separator "@@" --judging-criteria "$SPOUT_CRITERIA" --explanation True`;
        
        delete process.env.SPOUT_INPUTS;
        delete process.env.SPOUT_CRITERIA;
        
        const cleanOutput = evaluation.stdout
            .replace(/```json\n?/g, '')
            .replace(/```\n?/g, '')
            .trim();
            
        let result;
        try {
            result = JSON.parse(cleanOutput);
        } catch (parseError) {
            console.error('🚫 Error parsing evaluation output:', parseError);
            return {
                variant: variants[0],
                rankings: []
            };
        }
        
        if (!result.Rankings || !Array.isArray(result.Rankings)) {
            console.error('🚫 Unexpected evaluation output format');
            return {
                variant: variants[0],
                rankings: []
            };
        }

        const rankedVariants = result.Rankings;
        rankedVariants.forEach((r, idx) => {
            r.Text = variants[idx];
        });
        
        return {
            variant: rankedVariants[0].Text,
            rankings: rankedVariants
        };
    } catch (error) {
        console.error('🚫 Error evaluating variants:', error);
        return {
            variant: variants[0],
            rankings: []
        };
    }
}

console.log('✨ Functions defined');

// Main execution
console.log('🔍 Checking execution context...');
const currentFilePath = fileURLToPath(import.meta.url);
const executedFilePath = resolve(process.argv[1]);
console.log('Current file path:', currentFilePath);
console.log('Executed file path:', executedFilePath);

// Check if running through zx, npm script, or directly
if (executedFilePath.includes('zx') || process.env.npm_lifecycle_event?.startsWith('evolve:') || currentFilePath === executedFilePath) {
    console.log('✅ Running script execution');
    
    (async () => {
        try {
            console.log('🎬 Starting script execution...');
            // Parse command line arguments if provided
            const args = process.argv.slice(2);
            console.log('📥 Arguments:', args);
            
            const params = {};
            for (let i = 0; i < args.length; i++) {
                const arg = args[i];
                if (arg.startsWith('--')) {
                    const [key, value] = arg.slice(2).split('=');
                    if (value) {
                        // If the argument contains an equals sign
                        params[key] = value;
                    } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
                        // If the value is in the next argument
                        params[key] = args[++i];
                    }
                }
            }
            console.log('🔧 Parsed parameters:', params);
            
            await evolveText(params);
        } catch (error) {
            console.error('\n❌ Error during script execution:', error);
            console.error('Stack trace:', error.stack);
            process.exit(1);
        }
    })();
} else {
    console.log('ℹ️ Running as module');
}


export { evolveText };
