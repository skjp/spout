import asyncio
import sys

from spout.shared.base_handler import BaseHandler


class SpoutIterate(BaseHandler):
    def read_file_with_fallback_encoding(self, file_path):
        encodings = ['utf-8', 'windows-1252', 'iso-8859-1']
        for encoding in encodings:
            try:
                with open(file_path, 'r', encoding=encoding) as file:
                    return file.read()
            except UnicodeDecodeError:
                continue
        raise ValueError(f"Unable to read the file {file_path} with any of the attempted encodings.")

    async def iterate(self, example_preprocessed_line: str, example_processed_line: str, 
                     description: str, lines_per_call: str, preprocessed_lines: str, spoutlet: str = None):
        try:
            result = await self.process_with_plugin(
                plugin_name="Iterate",
                example_preprocessed_line=example_preprocessed_line,
                example_processed_line=example_processed_line,
                description=description,
                lines_per_call=lines_per_call or "1",
                preprocessed_lines=preprocessed_lines,
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
        if len(sys.argv) >= 6:  # Require all parameters including optional spoutlet
            example_preprocessed_line = sys.argv[1]
            example_processed_line = sys.argv[2]
            description = sys.argv[3]
            lines_per_call = sys.argv[4]
            preprocessed_lines = sys.argv[5]
            spoutlet = sys.argv[6] if len(sys.argv) > 6 else None
            
            iterator = SpoutIterate()
            asyncio.run(iterator.iterate(example_preprocessed_line, example_processed_line, 
                                      description, lines_per_call, preprocessed_lines, spoutlet))
        else:
            SpoutIterate().show_error_popup("Incorrect number of parameters: " + str(len(sys.argv)))
            sys.exit(1)
    except Exception as e:
        SpoutIterate().show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)