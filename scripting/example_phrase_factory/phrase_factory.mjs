#!/usr/bin/env zx

import fs from 'fs/promises';
import path from 'path';
import { question } from 'zx';

/**
 * SPOUT Phrase Factory Script
 * -------------------------
 * This script generates and evaluates marketing taglines/phrases using SPOUT's
 * mutate, generate, and evaluate modules in a multi-stage process:
 * 
 * 1. Variant Generation:
 *    - Takes a base description and example
 *    - Creates multiple variants using SPOUT's mutate module
 * 
 * 2. Phrase Generation:
 *    - Uses each variant pair to generate unique phrases
 *    - Runs in parallel for efficiency
 *    - Removes duplicates automatically
 * 
 * 3. Tournament Evaluation:
 *    - Evaluates generated phrases in a tournament style
 *    - Compares phrases in small batches (default 5)
 *    - Advances winners through elimination rounds
 *    - Produces detailed evaluation results
 * 
 * Usage:
 * ------
 * ./phrasefactory.mjs [options]
 * 
 * Options:
 * --numVariants       Number of variants threads to create (default: 6)
 * --maxItems         Maximum number of items to generate per variant (default: 20)
 * --batchSize         Items per generation batch (default: 10)
 * --description        Base description for generation
 * --example         Example phrase for generation
 * --outputFile        Name of results file (default: phrase_factory_results.txt)
 * --outputDir        Output directory (default: output/factory_output)
 * --runTournament     Whether to run evaluation tournament (default: true)
 * --tournamentBatchSize Number of items per tournament batch (default: 4)
 * --evaluationCriteria    Criteria for evaluation (default: "quality, appropriateness")
 * 
 * Example:
 * -------
 * ./phrasefactory.mjs --maxItems 50 --description "Marketing taglines for SPOUT" \
 *                     --example "Enhance Productivity with SPOUT"
 * 
 * Output:
 * -------
 * - Creates numbered output directory if needed
 * - Generates phrase_factory_results.txt with all unique phrases
 * - Creates variant-specific files for each description/example pair
 * - Produces tournament_results.txt with detailed evaluation results
 */


// Find next available directory
async function getNextAvailableDir(baseDir) {
  // Ensure base directory path is absolute and normalized
  const absoluteBaseDir = path.resolve(__dirname, baseDir);
  let currentDir = absoluteBaseDir;
  let counter = 1;

  try {
    // Create parent directories if they don't exist
    await fs.mkdir(path.dirname(absoluteBaseDir), { recursive: true });

    // Check if base directory exists and has content
    const exists = await fs.access(absoluteBaseDir).then(() => true).catch(() => false);
    if (exists) {
      const files = await fs.readdir(absoluteBaseDir);
      if (files.length > 0) {
        // Find next available numbered directory
        while (true) {
          currentDir = `${absoluteBaseDir}_${counter}`;
          const dirExists = await fs.access(currentDir).then(() => true).catch(() => false);
          if (!dirExists) break;
          counter++;
        }
      }
    }
  } catch (error) {
    console.warn('Directory creation warning:', error.message);
    // If there's any error, use the base directory
    currentDir = absoluteBaseDir;
  }

  // Create the directory
  await fs.mkdir(currentDir, { recursive: true });
  return currentDir;
}

// Default configuration
const DEFAULT_CONFIG = {
  maxItems: 30,
  batchSize: 5,
  description: "5 word name for an AI software product that could be abbreviated with S.P.O.U.T.; must have 5 words each starting with S P O U T. the last word must be either 'Transformers' or 'Transformations'",
  example: "Synergistic Plugins Optimizing Usability of Transformers",
  outputFile: "phrase_factory_results.txt",
  outputDir: "../output/phrase_factory/phrase_factory_output/",
  numVariants: 1,
  maxThreads: 3,
  runTournament: true,
  tournamentBatchSize: 4,
  evaluationCriteria: "originality, coolness, appropriateness",
};

// Parse command line arguments
const argv = process.argv.slice(3);
const args = {};
for (let i = 0; i < argv.length; i += 2) {
  if (argv[i].startsWith('--')) {
    args[argv[i].slice(2)] = argv[i + 1];
  }
}

// Merge defaults with provided arguments
const config = {
  ...DEFAULT_CONFIG,
  ...args
};
// Add interactive prompts if description or example are missing or using defaults
if (!config.description || !config.example) {
  console.log('\nMissing or default input parameters. Please provide the following:\n');
  
  if (!config.description || config.description === DEFAULT_CONFIG.description) {
    const description = await question('Enter description of phrases to generate: ');
    config.description = description.trim();
  }
  
  if (!config.example || config.example === DEFAULT_CONFIG.example) {
    const example = await question('Enter example of phrases to generate: ');
    config.example = example.trim();
  }
  
  console.log('\nThank you! Proceeding with generation...\n');
}

// Main execution
// Get next available directory
config.outputDir = await getNextAvailableDir(config.outputDir);
console.log(`Using output directory: ${config.outputDir}`);

// Generate variants of description and example
async function generateVariants(text, numVariants) {
  try {
    console.log(`Generating variants for: "${text}"`);
    const mutations = await $`spout mutate --input "${text}" --num_variants "${numVariants}" --mutation_level "1"`;
    
    if (!mutations || !mutations.stdout) {
      return [text];
    }

    try {
      const result = JSON.parse(mutations.stdout);
      return result.variants?.map(v => v.replace(/^\$?'|'$/g, '').trim()) || [text];
    } catch (parseError) {
      if (typeof mutations.stdout !== 'string') {
        return [text];
      }

      // Only attempt cleaning if we have markdown markers
      if (mutations.stdout.includes('```json')) {
        try {
          const parts = mutations.stdout.split('```json\n');
          if (parts.length > 1) {
            const jsonContent = parts[1].split('```')[0].trim();
            const result = JSON.parse(jsonContent);
            return result.variants?.map(v => v.replace(/^\$?'|'$/g, '').trim()) || [text];
          }
        } catch (cleaningError) {
          // Only log if cleaning actually failed
          if (cleaningError.message !== 'Unexpected end of JSON input') {
            console.error('Error cleaning markdown output:', cleaningError);
          }
        }
      }

      return [text];
    }
  } catch (error) {
    console.error('Error generating variants:', error.message);
    return [text];
  }
}

// Generate phrases using specific description and example
async function generatePhraseBatch(description, example, existingItems, config) {
  try {
    // Check if existingItems is too large (8000 char limit)
    if (existingItems.length > 8000) {
      console.log('Already-gen size limit reached. Stopping this variant set.');
      return [];
    }

    // Sanitize and properly escape the JSON string
    const items = JSON.parse(existingItems);
    const sanitizedItems = items.map(item => 
      typeof item === 'string' ? item.replace(/[\u0000-\u001F\u007F-\u009F]/g, '') : item
    );
    
    const escapedItems = JSON.stringify(sanitizedItems)
      .replace(/'/g, "'\\''")
      .replace(/"/g, '\\"')
      .replace(/\$/g, '\\$');
    
    const escapedDescription = description
      .replace(/'/g, "'\\''")
      .replace(/"/g, '\\"')
      .replace(/\$/g, '\\$');
    
    const escapedExample = example
      .replace(/'/g, "'\\''")
      .replace(/"/g, '\\"')
      .replace(/\$/g, '\\$');

    const generateCmd = await $`spout generate \
      --description "${escapedDescription}" \
      --example "${escapedExample}" \
      --batch-size "${config.batchSize}" \
      --already-gen '${escapedItems}'`;

    try {
      // First try direct JSON parse
      const newItems = JSON.parse(generateCmd.stdout).generated_items;
      return cleanItems(newItems);
    } catch (parseError) {
      // If direct parse fails, try to handle markdown-wrapped JSON
      if (generateCmd.stdout.includes('```json')) {
        try {
          const parts = generateCmd.stdout.split('```json\n');
          if (parts.length > 1) {
            const jsonContent = parts[1].split('```')[0].trim();
            const result = JSON.parse(jsonContent);
            return cleanItems(result.generated_items);
          }
        } catch (markdownError) {
          // If markdown parsing fails, return empty array to continue with next batch
          return [];
        }
      }
      // If no markdown or parsing fails, return empty array
      return [];
    }
  } catch (error) {
    // If any other error occurs, return empty array to continue with next batch
    return [];
  }
}

// Helper function to clean items
function cleanItems(items) {
  return items.map(item => 
    item
      .replace(/^\$'|'$/g, '')     // Remove $' prefix and trailing '
      .replace(/^\$/, '')          // Remove standalone $ prefix
      .replace(/[\u0000-\u001F\u007F-\u009F]/g, '')  // Remove control characters
      .replace(/['\\$]+$/, '')     // Remove trailing quotes, backslashes, and $ signs
      .replace(/\\+$/, '')         // Remove trailing backslashes
      .replace(/\\(?=[,\s])/g, '') // Remove backslashes before commas and spaces
      .replace(/^\\/, '')          // Remove leading backslashes
      .replace(/\\\\/g, '\\')      // Replace double backslashes with single
      .replace(/\\([^\\])/g, '$1') // Remove single backslashes except escaped ones
      .trim()                      // Remove whitespace
  );
}

// Add signal handler for graceful shutdown
let isShuttingDown = false;

process.on('SIGINT', async () => {
  console.log('\n\nInterrupt received, finishing up...');
  isShuttingDown = true;
});

// Generate phrases for a specific variant set
async function generateVariantSet(description, example, variantIndex, config) {
  const items = new Set();
  const outputPath = path.join(config.outputDir, `phrase_factory_variant_${variantIndex + 1}.txt`);

  console.log(`\nStarting generation for variant set ${variantIndex + 1}:`);
  console.log(`Description: ${description}`);
  console.log(`Example: ${example}\n`);

  let completed = false;
  
  while (items.size < config.maxItems && !isShuttingDown) {
    try {
      const existingItems = JSON.stringify([...items].map(item => item.trim()));
      const newItems = await generatePhraseBatch(description, example, existingItems, config);
      
      if (newItems.length === 0) {
        console.log(`Variant set ${variantIndex + 1}: Stopping generation (${items.size} items generated).`);
        completed = true;
        break;
      }

      newItems.forEach(item => items.add(item));
      console.log(`Variant set ${variantIndex + 1}: Generated ${items.size} unique items so far...`);
      
      // Save progress after each batch
      await fs.writeFile(outputPath, [...items].join('\n'));

      if (items.size >= config.maxItems) {
        completed = true;
        break;
      }
    } catch (error) {
      console.error(`Error in variant set ${variantIndex + 1}:`, error);
      break;
    }
  }

  return {
    items: [...items],
    outputPath,
    completed: completed || items.size >= config.maxItems
  };
}

// Main execution
console.log('\nGenerating description and example variants...');
const descriptionVariants = await generateVariants(config.description, config.numVariants);
const exampleVariants = await generateVariants(config.example, config.numVariants);

// Enforce max threads limit
if (config.numVariants > config.maxThreads) {
  console.warn(`Warning: Reducing number of variants from ${config.numVariants} to ${config.maxThreads} to respect maxThreads limit`);
  config.numVariants = config.maxThreads;
}

console.log('\nDescription variants:');
descriptionVariants.forEach((v, i) => console.log(`${i + 1}. ${v}`));
console.log('\nExample variants:');
exampleVariants.forEach((v, i) => console.log(`${i + 1}. ${v}`));

// Generate phrases for each variant set in parallel
const variantSetPromises = [];
for (let i = 0; i < config.numVariants; i++) {
  const description = descriptionVariants[i] || config.description;
  const example = exampleVariants[i] || config.example;
  variantSetPromises.push(generateVariantSet(description, example, i, config));
}

// Wait for all variant sets to complete
const variantSetResults = await Promise.all(variantSetPromises);

// Combine all unique items into main output file
const allItems = new Set();
let totalItems = 0;
let completedSets = 0;

variantSetResults.forEach(result => {
  if (result.completed) completedSets++;
  result.items.forEach(item => {
    totalItems++;
    allItems.add(item);
  });
});

const duplicatesRemoved = totalItems - allItems.size;
const mainOutputPath = path.join(config.outputDir, config.outputFile);
await fs.writeFile(mainOutputPath, [...allItems].join('\n'));

console.log('\nGeneration complete!');
if (isShuttingDown) {
  console.log('Process was interrupted!');
}
console.log(`${completedSets} of ${config.numVariants} variant sets completed`);
console.log(`Generated ${totalItems} total items across all variants`);
console.log(`Removed ${duplicatesRemoved} duplicates`);
console.log(`Final unique item count: ${allItems.size}`);
console.log('\nOutput files:');
console.log(`Main output: ${mainOutputPath}`);
variantSetResults.forEach((result, i) => {
  console.log(`Variant set ${i + 1}: ${result.outputPath} (${result.items.length} items)${result.completed ? ' - Completed' : ''}`);
});

if (config.runTournament && allItems.size > 0) {
  console.log('\n🏆 Running tournament evaluation...');
  
  async function evaluateBatch(items, criteria) {
    try {
      // Escape and sanitize inputs, but preserve full text
      const sanitizedInputs = items.map(item => 
        item
          .replace(/"/g, '\\"')
          .replace(/'/g, "\\'")
          .replace(/`/g, '\\`')
          .replace(/\$/g, '\\$')
          .replace(/\n/g, ' ')
          .trim()  // Only trim whitespace
      );
      
      const combinedInputs = sanitizedInputs.join('@@');
      const escapedCriteria = criteria
        .replace(/"/g, '\\"')
        .replace(/'/g, "\\'")
        .replace(/`/g, '\\`')
        .replace(/\$/g, '\\$');

      console.log(`Evaluating batch of ${items.length} items...`);
      
      const evaluation = await $`spout evaluate --combined-inputs "${combinedInputs}" --separator "@@" --judging-criteria "${escapedCriteria}" --explanation "True"`;
      
      if (!evaluation || !evaluation.stdout) {
        console.warn('No output from evaluation command');
        return createFallbackRankings(items);
      }

      const stdout = evaluation.stdout.toString();

      let result;
      try {
        // Extract and parse JSON content
        let jsonContent = stdout.trim();
        const startIndex = jsonContent.indexOf('{');
        const endIndex = jsonContent.lastIndexOf('}');
        
        if (startIndex !== -1 && endIndex !== -1) {
          jsonContent = jsonContent.substring(startIndex, endIndex + 1);
        }

        result = JSON.parse(jsonContent);

        if (!result || !result.Rankings || !Array.isArray(result.Rankings)) {
          throw new Error('Invalid result structure');
        }

        // Map the rankings, ensuring we use the original full text
        const rankedItems = result.Rankings.map(r => {
          let text;
          if (r.Name.startsWith('Input ')) {
            // Use the original full text from items array
            const index = parseInt(r.Name.replace('Input ', '')) - 1;
            text = items[index];
            if (!text) {
              console.warn(`Warning: Could not find original text for Input ${index + 1}`);
              text = r.Name;  // Fallback to the name if index not found
            }
          } else {
            // If direct name, still check against original items to ensure full text
            text = items.find(item => item.includes(r.Name)) || r.Name;
          }

          return {
            Rank: r.Rank || 0,
            Score: r.Score || 0,
            text: text,
            Explanation: r.Explanation || 'No explanation provided'
          };
        });

        // Verify we have all items accounted for
        if (rankedItems.length !== items.length) {
          console.warn(`Warning: Rankings count (${rankedItems.length}) doesn't match input count (${items.length})`);
        }

        return rankedItems;

      } catch (error) {
        console.warn('Parsing error:', error.message);
        return createFallbackRankings(items);
      }
    } catch (error) {
      console.warn('Evaluation error:', error.message);
      return createFallbackRankings(items);
    }
  }

  // Helper function to create fallback rankings
  function createFallbackRankings(items) {
    return items
      .filter(text => text && text !== 'undefined')
      .map((text, i) => ({ 
        Score: 0, 
        text: text.replace(/[""]/g, '"').replace(/['']/g, "'"),  // Normalize quotes
        Rank: i + 1,
        Explanation: 'Fallback due to evaluation error'
      }));
  }

  async function runTournament(items) {
    const validItems = [...new Set([...items].filter(item => 
        item && 
        item !== 'undefined' && 
        typeof item === 'string' && 
        item.trim().length > 0
    ))];
    
    if (validItems.length === 0) {
      console.log('No valid items to evaluate in tournament.');
      return null;
    }

    console.log(`Starting tournament with ${validItems.length} valid items`);
    const tournamentPath = path.join(config.outputDir, 'tournament_results.txt');
    const results = ['# Tournament Results\n'];
    let currentRound = validItems;
    let roundNum = 1;

    while (currentRound.length > 1) {
      results.push(`\n## Round ${roundNum}\n`);
      console.log(`\nRound ${roundNum}: ${currentRound.length} items remaining`);
      
      const numBatches = Math.ceil(currentRound.length / config.tournamentBatchSize);
      const maxConcurrentBatches = Math.min(config.maxThreads, numBatches);
      console.log(`Processing ${numBatches} batches in groups of ${maxConcurrentBatches}...`);
      
      // Process batches in chunks respecting maxThreads
      const allBatchResults = [];
      for (let i = 0; i < numBatches; i += maxConcurrentBatches) {
        const batchPromises = [];
        
        // Create batch promises for current chunk
        for (let j = 0; j < maxConcurrentBatches && (i + j) < numBatches; j++) {
          const batchNum = i + j;
          const startIdx = batchNum * config.tournamentBatchSize;
          const batch = currentRound.slice(startIdx, startIdx + config.tournamentBatchSize);
          
          const promise = (async () => {
            console.log(`Starting batch ${batchNum + 1} of ${numBatches}`);
            try {
              const rankings = await evaluateBatch(batch, config.evaluationCriteria);
              
              // Write results immediately for this batch
              results.push(`\nBatch ${batchNum + 1}:`);
              rankings.forEach(r => {
                results.push(`\nRank ${r.Rank} (Score: ${r.Score})`);
                results.push(`Text: "${r.text}"`);
                if (r.Explanation) results.push(`Explanation: ${r.Explanation}`);
              });
              
              // Write intermediate results to file
              await fs.writeFile(tournamentPath, results.join('\n'));
              
              return {
                batchNum: batchNum + 1,
                rankings,
                error: null,
                processed: true
              };
            } catch (error) {
              console.error(`Error in batch ${batchNum + 1}:`, error);
              const fallbackRankings = batch.map((text, i) => ({ 
                Score: 0, 
                text, 
                Rank: i + 1,
                Explanation: 'Fallback due to evaluation error'
              }));
              
              // Write fallback results
              results.push(`\nBatch ${batchNum + 1} (Error fallback):`);
              fallbackRankings.forEach(r => {
                results.push(`\nRank ${r.Rank} (Score: ${r.Score})`);
                results.push(`Text: "${r.text}"`);
                if (r.Explanation) results.push(`Explanation: ${r.Explanation}`);
              });
              
              // Write intermediate results to file
              await fs.writeFile(tournamentPath, results.join('\n'));
              
              return {
                batchNum: batchNum + 1,
                rankings: fallbackRankings,
                error,
                processed: true
              };
            }
          })();
          
          batchPromises.push(promise);
        }

        // Wait for current chunk of batches to complete
        const chunkResults = await Promise.all(batchPromises);
        allBatchResults.push(...chunkResults);
      }

      // Process winners after all batches complete
      const nextRound = allBatchResults
        .sort((a, b) => a.batchNum - b.batchNum)
        .filter(result => result.rankings && result.rankings.length > 0)
        .map(result => result.rankings[0].text)
        .filter(text => text && text !== 'undefined');

      // Ensure we have items for the next round
      if (nextRound.length === 0) {
        console.error('No winners advanced to next round!');
        break;
      }
      
      // Log round summary
      results.push(`\nRound ${roundNum} Summary:`);
      results.push(`\nStarted with ${currentRound.length} items`);
      results.push(`Processed ${numBatches} batches in groups of ${maxConcurrentBatches}`);
      results.push(`Advanced ${nextRound.length} winners to next round\n`);
      
      currentRound = nextRound;
      roundNum++;
      
      console.log(`Round ${roundNum-1} complete. ${nextRound.length} items advancing to next round.`);
    }

    const winner = currentRound[0];
    if (winner) {
      results.push('\n## Final Winner\n');
      results.push(`"${winner}"\n`);
      
      await fs.writeFile(tournamentPath, results.join('\n'));
      console.log('\n🏆 Tournament complete!');
      console.log(`Winner: "${winner}"`);
      console.log(`Tournament results saved to: ${tournamentPath}`);
    }
    
    return winner;
  }

  await runTournament([...allItems]);
}