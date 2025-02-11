import asyncio
import sys

import pyperclip

from spout.shared.base_handler import BaseHandler


class SpoutMutate(BaseHandler):
    async def mutate(self, num_variants: str = "2", substring: str = "*", mutation_level: str = "1", input: str = None, spoutlet: str = None):
        try:
            if not input:
                input = pyperclip.paste()
            if not substring or substring == "*":
                substring = input
            elif isinstance(substring, str) and isinstance(input, str) and substring not in input:
                substring = input
                
            result = await self.process_with_plugin(
                plugin_name="Mutate",
                input=input,
                num_variants=num_variants,
                substring=substring,
                mutation_level=mutation_level,
                spoutlet=spoutlet
            )
            
            if 'python.exe' in sys.executable:
                print(result)
            else: 
                return result
        except Exception as e:
            self.show_error_popup(f"An error occurred: {str(e)}")
            sys.exit(1)

if __name__ == "__main__":
    try:
        if len(sys.argv) > 3:
            num_variants = sys.argv[1] 
            substring = sys.argv[2]
            mutation_level = sys.argv[3]
            input_text = sys.argv[4] if len(sys.argv) > 4 else None
            spoutlet = sys.argv[5] if len(sys.argv) > 5 else None
            mutator = SpoutMutate()
            asyncio.run(mutator.mutate(num_variants, substring, mutation_level, input_text, spoutlet))
        else:
            error_message = f"Incorrect number of arguments provided. Expected at least 4, got {len(sys.argv)}.\nUsage: python mutate.py <num_variants> <substring> <mutation_level> <input_text> [spoutlet]"
            SpoutMutate().show_error_popup(error_message)
            sys.exit(1)
    except Exception as e:
        SpoutMutate().show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)
