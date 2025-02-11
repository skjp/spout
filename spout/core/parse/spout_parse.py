import asyncio
import sys

import pyperclip

from spout.shared.base_handler import BaseHandler


class SpoutParse(BaseHandler):
    async def parse(self, input: str = None, categories: str = None, spoutlet: str = None):
        try:
            # Validate required parameters
            if categories is None:
                raise ValueError("Categories parameter is required")
                
            # Use provided input or fallback to clipboard
            if input is None:
                try:
                    input = pyperclip.paste()
                    if not input:
                        raise ValueError("No input provided and clipboard is empty")
                except Exception as clip_error:
                    raise ValueError(f"Failed to read clipboard: {str(clip_error)}")
                
            result = await self.process_with_plugin(
                plugin_name="Parse",
                input=input,  # Exactly matching config.json input_variables
                categories=categories,
                spoutlet=spoutlet
            )
            
            # Copy result to clipboard first
            try:
                pyperclip.copy(result)
            except Exception as clip_error:
                print(f"Warning: Could not copy to clipboard: {str(clip_error)}")
            
            # Then handle output based on execution context
            if 'python.exe' in sys.executable:
                print(result)
            else:
                return result
            
        except Exception as e:
            self.show_error_popup(f"An error occurred: {str(e)}")
            sys.exit(1)

if __name__ == "__main__":
    try:
        if len(sys.argv) >= 2:
            categories = sys.argv[1]
            input_text = sys.argv[2] if len(sys.argv) > 2 else None
            spoutlet = sys.argv[3] if len(sys.argv) > 3 else None
            
            parser = SpoutParse()
            asyncio.run(parser.parse(
                input=input_text,
                categories=categories,
                spoutlet=spoutlet
            ))
        else:
            SpoutParse().show_error_popup("Missing required parameter: categories")
            sys.exit(1)
    except Exception as e:
        SpoutParse().show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)
