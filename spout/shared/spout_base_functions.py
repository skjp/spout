import asyncio
import sys

import pyperclip

from spout.shared.base_handler import BaseHandler


class SpoutBaseFunctionHandler(BaseHandler):
    def __init__(self):
        super().__init__()
        # Check if running from python.exe (CLI) or pythonw.exe (GUI)
        self.is_cli = 'pythonw.exe' not in sys.executable.lower()

    def show_error_popup(self, message: str):
        if self.is_cli:
            print(f"Error: {message}", file=sys.stderr)
        else:
            super().show_error_popup(message)

    async def process_function(self, title: str, spoutlet: str = "default", input: str = None):
        try:
            # Use provided input if available, otherwise use clipboard
            if input is None:
                input = pyperclip.paste()
            
            result = await self.process_with_plugin(
                plugin_name=title,
                spoutlet=spoutlet,
                input=input,
                is_cli=self.is_cli
            )
            
            if self.is_cli:
                print(result)
            return result
            
        except Exception as e:
            self.show_error_popup(f"An error occurred: {str(e)}")
            sys.exit(1)

if __name__ == "__main__":
    try:
        if len(sys.argv) == 4:
            title = sys.argv[1]
            spoutlet = sys.argv[2]
            input_text = sys.argv[3]
            handler = SpoutBaseFunctionHandler()
            asyncio.run(handler.process_function(title, spoutlet, input_text))
        else:
            handler = SpoutBaseFunctionHandler()
            handler.show_error_popup("Missing required parameters. Usage: <title> <spoutlet> <input_text>")
            sys.exit(1)
    except Exception as e:
        handler = SpoutBaseFunctionHandler()
        handler.show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)