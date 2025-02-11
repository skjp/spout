import asyncio
import os
import re
import sys

from spout.shared.base_handler import BaseHandler


class SpoutImagine(BaseHandler):
    async def imagine(self, objective: str, context: str, output_format: str = "json", stipulations: str = "", spoutlet: str = None):
        """
        Generate a structured plan based on the provided parameters.
        """
        try:
            # Process special tags in context
            processed_context = self.process_special_tags(context)
            
            result = await self.process_with_plugin(
                plugin_name="Imagine",
                objective=objective,
                context=processed_context,
                output_format=output_format,
                stipulations=stipulations if stipulations else "",
                spoutlet=spoutlet
            )
            
            if 'python.exe' in sys.executable:
                print(result)
            else:
                return result
            
        except Exception as e:
            self.show_error_popup(f"An error occurred: {str(e)}")
            sys.exit(1)

    def process_special_tags(self, context: str) -> str:
        """Process special @Spout tags in the context."""
        context_lower = context.lower()
        
        if '@spout' not in context_lower:
            return context

        # Get the base directory for core modules
        current_dir = os.path.dirname(os.path.abspath(__file__))
        core_dir = os.path.join(os.path.dirname(os.path.dirname(current_dir)), "core")
        
        additional_context = ""

        if '@spoutcli' in context_lower:
            additional_context = "=== Spout CLI Examples ===\n\n"
            try:
                for module in sorted(os.listdir(core_dir)):
                    module_path = os.path.join(core_dir, module)
                    if os.path.isdir(module_path) and not module.startswith('__'):
                        samples_path = os.path.join(module_path, 'tests', 'samples')
                        
                        if os.path.exists(samples_path):
                            default_files = [f for f in os.listdir(samples_path) 
                                          if f.endswith('_default.txt')]
                            
                            if default_files:
                                additional_context += f"--- {module.upper()} Module Examples ---\n"
                                for sample in default_files:
                                    sample_path = os.path.join(samples_path, sample)
                                    content = None
                                    
                                    # Try different encodings
                                    encodings = ['utf-8', 'utf-8-sig', 'latin-1', 'cp1252']
                                    for encoding in encodings:
                                        try:
                                            with open(sample_path, 'r', encoding=encoding) as f:
                                                content = f.read().strip()
                                                break
                                        except UnicodeDecodeError:
                                            continue
                                        except Exception:
                                            break
                                    
                                    if content:
                                        additional_context += f"{content}\n\n"
            except Exception:
                return context
            
            # Remove any other @Spout tags since @SpoutCLI takes precedence
            context = re.sub(r'@Spout\w+', '', context, flags=re.IGNORECASE)
            
            # Combine the original context with the additional context
            if additional_context:
                return f"{context.strip()}\n\n{additional_context.strip()}"
        
        else:
            # Handle individual module tags
            for module in os.listdir(core_dir):
                module_tag = f'@spout{module.lower()}'
                if module_tag in context_lower:
                    module_path = os.path.join(core_dir, module)
                    samples_path = os.path.join(module_path, 'tests', 'samples')
                    if os.path.exists(samples_path):
                        additional_context += f"Spout {module} module examples:\n\n"
                        for sample in os.listdir(samples_path):
                            try:
                                with open(os.path.join(samples_path, sample), 'r', encoding='utf-8') as f:
                                    additional_context += f"{f.read()}\n"
                            except Exception:
                                continue
                        additional_context += "\n"
                    # Remove the processed tag
                    context = re.sub(f'@Spout{module}', '', context, flags=re.IGNORECASE)

        # Remove any remaining @Spout tags
        context = re.sub(r'@Spout\w+', '', context, flags=re.IGNORECASE)
        
        # Combine the original context (without tags) with the additional context
        if additional_context:
            return f"{context.strip()}\n\n{additional_context.strip()}"
        return context.strip()

if __name__ == "__main__":
    try:
        if len(sys.argv) >= 5:
            objective = sys.argv[1]
            context = sys.argv[2]
            output_format = sys.argv[3]
            stipulations = sys.argv[4]
            spoutlet = sys.argv[5] if len(sys.argv) > 5 else None
            
            imaginer = SpoutImagine()
            asyncio.run(imaginer.imagine(
                objective=objective,
                context=context,
                output_format=output_format,
                stipulations=stipulations,
                spoutlet=spoutlet
            ))
        else:
            SpoutImagine().show_error_popup("Incorrect number of parameters")
            sys.exit(1)
    except Exception as e:
        SpoutImagine().show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)
