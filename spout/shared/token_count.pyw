import tiktoken
import configparser
import sys
import tkinter as tk
from tkinter import messagebox
import pyperclip
from pathlib import Path

def count_llm_tokens_fast(text: str) -> int:
    root = tk.Tk()
    root.withdraw()
    
    # Read settings from config/settings.ini
    config = configparser.ConfigParser()
    
    # Get the config file path
    config_dir = Path(__file__).resolve().parent.parent / 'config'
    settings_path = config_dir / 'settings.ini'
    
    try:
        with open(settings_path, 'r', encoding='utf-8-sig') as config_file:
            config.read_file(config_file)
        # Get model from config
        model = config.get('General', 'TokenCountModel')

    except (configparser.NoSectionError, configparser.NoOptionError) as e:
        messagebox.showerror("Error", f"Error reading config: {e}")
        sys.exit(1)
    except FileNotFoundError:
        messagebox.showerror("Error", f"Settings file not found at: {settings_path}")
        sys.exit(1)

    try:
        try:
            # Initialize the tokenizer for a specific model
            encoding = tiktoken.encoding_for_model(model)
        except:
            # If the first attempt fails, try again with 'gpt-3.5-turbo'
            try:
                encoding = tiktoken.encoding_for_model('gpt-3.5-turbo')
            except Exception as e:
                messagebox.showerror("Error", f"Error initializing tokenizer: {e}")
                sys.exit(1)
        # Encode the text to get the tokens
        tokens = encoding.encode(text)
    except Exception as e:
        messagebox.showerror("Error", f"Error in tokenization: {e}")
        tokens = []  # Set an empty list as a fallback
    
    # Get the number of tokens
    token_count = len(tokens)
    
    # Show a popup message box with the token count and model specification
    messagebox.showinfo("Token Count: ("+model +") ", f"Total tokens: {token_count}")
    # Destroy the root window
    root.destroy()

if __name__ == "__main__":
    # Get command-line arguments
    if len(sys.argv) > 1:
        # If arguments are provided, join them into a single string
        input_text = ' '.join(sys.argv[1:])
    else:
        # If no arguments, use clipboard content
        input_text = pyperclip.paste()
    # Count tokens
    count_llm_tokens_fast(input_text)