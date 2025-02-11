import asyncio
import os
import sys

from spout.shared.base_handler import BaseHandler


class SpoutConverse(BaseHandler):
    def read_file_with_fallback_encoding(self, file_path: str) -> str:
        encodings = ['utf-8', 'windows-1252', 'iso-8859-1']
        for encoding in encodings:
            try:
                with open(file_path, 'r', encoding=encoding) as file:
                    return file.read()
            except UnicodeDecodeError:
                continue
        raise ValueError(f"Unable to read the file {file_path} with any of the attempted encodings.")

    async def converse(self, primer: str, history_file: str, recent_message: str, model: str = None, spoutlet: str = None):
        is_cli = 'python.exe' in sys.executable
        if is_cli and not history_file:
            # Get the current script's directory
            current_dir = os.path.dirname(os.path.abspath(__file__))
            # Construct path to cli.txt relative to current script
            history_file = os.path.join(current_dir, "options", "cli.txt")
            # Append the user message to the history file
            try:
                with open(history_file, 'a', encoding='utf-8') as f:
                    f.write(f"\n<USER> {recent_message}\n")
            except Exception as e:
                self.show_error_popup(f"Failed to append message to history file: {str(e)}")
                sys.exit(1)
        try:
            # Check if history file is empty placeholder
            history = "" if history_file in [" ", "_"] else self.read_file_with_fallback_encoding(history_file)
            if len(history) > 3000:
                history = "History concatenated to stay under token limit; most recent history: " + history[-3000:]
            result = await self.process_with_plugin(
                plugin_name="converse",
                primer=primer,
                history=history,
                recent_message=recent_message,
                model=model,
                spoutlet=spoutlet
            )
            
            if is_cli and history_file not in [" ", "_"]:  # Only save history if not using placeholder
                # Append the model's response to the history file
                try:
                    with open(history_file, 'a', encoding='utf-8') as f:
                        f.write(f"\n<ASSISTANT> {result}\n")
                except Exception as e:
                    self.show_error_popup(f"Failed to append response to history file: {str(e)}")
                    sys.exit(1)
            print(result)
            return result
        except Exception as e:
            self.show_error_popup(f"An error occurred: {str(e)}")
            sys.exit(1)

if __name__ == "__main__":
    try:
        if len(sys.argv) > 4:
            primer = sys.argv[1]
            history_file = sys.argv[2]
            recent_message = sys.argv[3]
            model = sys.argv[4]
            spoutlet = sys.argv[5] if len(sys.argv) > 5 else None
            
            chat = SpoutConverse()
            asyncio.run(chat.converse(primer, history_file, recent_message, model, spoutlet))
        else:
            SpoutConverse().show_error_popup("Unacceptable number of parameters")
            sys.exit(1)
    except Exception as e:
        SpoutConverse().show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)