import asyncio
import sys

from spout.shared.base_handler import BaseHandler


class SpoutGenerate(BaseHandler):
    async def generate(self, description: str, example: str, batch_size: str = "3", already_gen: str = None, spoutlet: str = None):
        
        try:
            if already_gen is None:
                already_gen = ""
                
            result = await self.process_with_plugin(
                plugin_name="Generate",
                description=description,
                example=example or " ",
                batch_size=batch_size or "3",
                already_gen=already_gen,
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
        if len(sys.argv) >= 3:  # Only require description and example
            description = sys.argv[1]
            example = sys.argv[2]
            batch_size = sys.argv[3] if len(sys.argv) > 3 else "1"
            already_gen = sys.argv[4] if len(sys.argv) > 4 else None
            spoutlet = sys.argv[5] if len(sys.argv) > 5 else None
            
            generator = SpoutGenerate()
            asyncio.run(generator.generate(description, example, batch_size, already_gen, spoutlet))
        else:
            SpoutGenerate().show_error_popup("Incorrect number of parameters: " + str(len(sys.argv)))
            sys.exit(1)
    except Exception as e:
        SpoutGenerate().show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)
