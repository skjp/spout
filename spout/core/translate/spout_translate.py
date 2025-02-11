import asyncio
import sys

import pyperclip

from spout.shared.base_handler import BaseHandler


class SpoutTranslate(BaseHandler):
    async def translate(self, specification: str, spoutlet: str = None, input: str = None):
        # Use provided text or fallback to clipboard
        input = input or pyperclip.paste()
        result = await self.process_with_plugin(
            plugin_name="Translate",
            input=input,
            specification=specification,
            spoutlet=spoutlet
        )
        
        # Check if the script is being run with python.exe or pythonw.exe
        if 'python.exe' in sys.executable:
            print(result)  # Print to console
        else:
            pyperclip.copy(result)  # Copy to clipboard

if __name__ == "__main__":
    try:
        if len(sys.argv) == 4:
            specification = sys.argv[1]
            spoutlet = sys.argv[2]
            text = sys.argv[3]
            translator = SpoutTranslate()
            asyncio.run(translator.translate(specification, spoutlet, text))
        else:
            translator = SpoutTranslate()
            translator.show_error_popup("Missing required parameters. Usage: <specification> <spoutlet> <input_text>")
            sys.exit(1)
    except Exception as e:
        translator = SpoutTranslate()
        translator.show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)