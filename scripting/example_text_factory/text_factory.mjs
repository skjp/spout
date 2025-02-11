#!/usr/bin/env zx

/**
 * Test Text Factory
 * 
 * Purpose:
 * Generates test content of varying lengths and complexities using spout.
 * Creates a mix of phrases, sentences, and paragraphs with random variations.
 * The content is generated progressively and saved to a timestamped file,
 * ensuring no content is lost in case of errors.
 * 
 * Usage:
 * ./testscriptfactory.mjs [--threads <number>] [--theme <word>]
 * 
 * Options:
 * --threads  Number of concurrent generation threads (default: 1, max: 8)
 *           Higher thread counts will generate more content in parallel
 * --theme    Custom theme word to use (default: random from predefined list)
 *           Example: --theme "cyberpunk" or --theme "meditation"
 * 
 * Output:
 * - Creates files in ../output/text_factory_output/
 * - Files are named with timestamp: test-text_YYYYMMDDHHMMSS.txt
 * - Content is generated in increasing complexity:
 *   1. Short phrases (3-7 words)
 *   2. Medium sentences (10-15 words)
 *   3. Complex sentences (15-25 words)
 *   4. Short paragraphs (2-3 sentences)
 *   5. Medium paragraphs (4-6 sentences)
 *   6. Long paragraphs (6-8 sentences)
 *   7. Multi-paragraph content (4-5 paragraphs)
 *   8. Extra-long content (6-8 paragraphs)
 * 
 * Examples:
 * ./testscriptfactory.mjs                        # Run with single thread, random theme
 * ./testscriptfactory.mjs --threads 4            # Run with 4 parallel threads
 * ./testscriptfactory.mjs --theme "cyberpunk"    # Run with custom theme
 * ./testscriptfactory.mjs --threads 4 --theme "meditation"  # Both options
 * 
 * Dependencies:
 * - Requires spout CLI to be installed and configured
 * - Uses zx for shell operations and file handling
 */

import { $, fs, argv } from 'zx';

// Theme word pools for random selection if no theme provided
const baseThemes = ['forest', 'ocean', 'mountain', 'desert', 'river', 'garden', 'storm', 'sunrise', 'valley', 'wildlife',
                   'city', 'street', 'building', 'traffic', 'park', 'market', 'subway', 'cafe', 'museum', 'bridge',
                   'computer', 'robot', 'network', 'device', 'software', 'digital', 'virtual', 'cyber', 'quantum', 'data',
                   'joy', 'sorrow', 'excitement', 'peace', 'wonder', 'mystery', 'passion', 'tension', 'harmony', 'chaos',
                   'dance', 'explore', 'create', 'build', 'discover', 'learn', 'grow', 'transform', 'connect', 'inspire'];

// Get random item from an array
function getRandomItem(array) {
    return array[Math.floor(Math.random() * array.length)];
}

// Generate theme words using expand
async function generateThemeWords(baseTheme) {
    try {
        console.log(`🎨 Expanding theme words for: ${baseTheme}`);
        const expanded = await $`spout expand "List 20 single words related to ${baseTheme}. Only output the words separated by commas, no numbering or formatting."`;
        return expanded.stdout.split(',').map(word => word.trim());
    } catch (error) {
        console.warn(`⚠️ Theme expansion failed, using base theme: ${error.message}`);
        return [baseTheme];
    }
}

// Get random theme from expanded words
function getRandomTheme(themeWords) {
    return getRandomItem(themeWords);
}

// Add thread count parameter with default and validation
const threadCount = Math.min(8, Math.max(1, parseInt(argv.threads || '1')));
console.log(`🧵 Running with ${threadCount} threads`);

// Add helper function for parallel processing
async function processInParallel(count, generator) {
    const promises = Array(count).fill().map(() => generator());
    return await Promise.all(promises);
}

async function generateDocument() {
    const outputDir = '../output/text_factory_output';
    const timestamp = new Date().toISOString().replace(/[:\-T]/g, '').split('.')[0];
    const outputPath = `${outputDir}/test-text_${timestamp}.txt`;
    await fs.mkdir(outputDir, { recursive: true });
    
    // Get base theme from input or random selection
    const baseTheme = argv.theme ? argv.theme.toLowerCase() : getRandomItem(baseThemes);
    console.log(`🎯 Base theme: ${baseTheme}${argv.theme ? ' (custom)' : ' (random)'}`);

    // Generate theme words at initialization
    const themeWords = await generateThemeWords(baseTheme);
    console.log(`📚 Generated ${themeWords.length} theme variations`);
    
    console.log(`🚀 Starting test text generation for ${outputPath}...\n`);

    // Write header immediately
    await fs.writeFile(outputPath, `This is a text file generated randomly for testing out text editing functions of various types.\nBase theme: ${baseTheme}\n\n\n`);

    try {
        // Generate short phrases (3-7 words)
        console.log('📝 Generating phrases...');
        const phraseResults = await processInParallel(threadCount, async () => {
            const phraseTheme = getRandomTheme(themeWords);
            const phrases = await $`spout generate --description "short action phrase about ${phraseTheme}" --example "The cat sat quietly" --batch-size 5`;
            return JSON.parse(phrases.stdout).generated_items;
        });
        await fs.appendFile(outputPath, phraseResults.flat().join('\n\n') + '\n\n\n');

        // Generate medium sentences (10-15 words)
        console.log('📝 Generating sentences...');
        const sentenceResults = await processInParallel(threadCount, async () => {
            const sentenceTheme = getRandomTheme(themeWords);
            const sentences = await $`spout generate --description "descriptive sentence about ${sentenceTheme}" --example "The autumn leaves danced gently in the cool morning breeze" --batch-size 5`;
            return JSON.parse(sentences.stdout).generated_items;
        });
        await fs.appendFile(outputPath, sentenceResults.flat().join('\n\n') + '\n\n\n');

        // Generate complex sentences (15-25 words)
        console.log('📝 Generating complex sentences...');
        const complexResults = await processInParallel(threadCount, async () => {
            const complexTheme = getRandomTheme(themeWords);
            const complexSentences = await $`spout generate --description "complex sentence about ${complexTheme}" --example "The advanced AI system processed millions of data points while simultaneously adapting its algorithms for optimal performance" --batch-size 5`;
            return JSON.parse(complexSentences.stdout).generated_items;
        });
        await fs.appendFile(outputPath, complexResults.flat().join('\n\n') + '\n\n\n');

        // Generate short paragraphs
        console.log('📝 Generating short paragraphs...');
        const shortParaResults = await processInParallel(threadCount, async () => {
            const shortParaTheme = getRandomTheme(themeWords);
            const shortParagraphs = await $`spout expand "Write a short paragraph about ${shortParaTheme}. Make it 2-3 sentences."`;
            return shortParagraphs.stdout;
        });
        await fs.appendFile(outputPath, shortParaResults.join('\n\n') + '\n\n\n');

        // Generate medium paragraphs
        console.log('📝 Generating medium paragraphs...');
        const mediumParaResults = await processInParallel(threadCount, async () => {
            const mediumParaTheme = getRandomTheme(themeWords);
            const mediumParagraphs = await $`spout expand "Write about ${mediumParaTheme}. Make it 4-6 sentences."`;
            return mediumParagraphs.stdout;
        });
        await fs.appendFile(outputPath, mediumParaResults.join('\n\n') + '\n\n\n');

        // Generate long paragraphs
        console.log('📝 Generating long paragraphs...');
        const longParaResults = await processInParallel(threadCount, async () => {
            const longParaTheme = getRandomTheme(themeWords);
            const longParagraphs = await $`spout expand "Write about ${longParaTheme}. Make it 6-8 sentences long."`;
            return longParagraphs.stdout;
        });
        await fs.appendFile(outputPath, longParaResults.join('\n\n') + '\n\n\n');

        // Generate multi-paragraph content
        console.log('📝 Generating multi-paragraph content...');
        const multiParaResults = await processInParallel(threadCount, async () => {
            const multiParaTheme = getRandomTheme(themeWords);
            const multiParagraphs = await $`spout expand "Write a detailed multi-paragraph text about ${multiParaTheme}. Include 4-5 paragraphs with different aspects or perspectives. Make it comprehensive and engaging."`;
            return multiParagraphs.stdout;
        });
        await fs.appendFile(outputPath, multiParaResults.join('\n\n\n') + '\n\n\n');

        // Generate extra-long content
        console.log('📝 Generating extra-long content...');
        const extraLongResults = await processInParallel(threadCount, async () => {
            const longTheme = getRandomTheme(themeWords);
            const extraLong = await $`spout expand "Write an extensive piece about ${longTheme}. Include 6-8 paragraphs, with a clear introduction, multiple detailed sections, and a conclusion. Make it thorough and well-structured."`;
            return extraLong.stdout;
        });
        await fs.appendFile(outputPath, extraLongResults.join('\n\n\n') + '\n\n\n');

        console.log(`\n✨ Test text generated successfully at ${outputPath}`);

    } catch (error) {
        console.error('\n❌ Error during generation:', error);
        console.log('💾 Partial results have been saved to:', outputPath);
        process.exit(1);
    }
}

// Execute the main function
console.log('🔧 Initializing Test Text Factory...\n');
generateDocument().catch(error => {
    console.error('\n❌ Unexpected error:', error);
    process.exit(1);
});
