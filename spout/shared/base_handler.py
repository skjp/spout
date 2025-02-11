import configparser
import tkinter as tk
from pathlib import Path
from tkinter import messagebox
from typing import Optional

import pyperclip

from spout.shared.api_logging import APIMetricsLogger
from spout.shared.connector import ConnectorEngine, ConnectorService


class BaseHandler:
    def __init__(self):
        self.service_id = "default"
        self.api_metrics_logger = APIMetricsLogger()
        self.config_dir = self._get_config_dir()
        self.preferred_spoutlets = {}
        
    def _get_config_dir(self):
        """Get or create the config directory path"""
        package_root = Path(__file__).resolve().parent.parent
        config_dir = package_root / 'config'
        
        # Create config directory if it doesn't exist
        if not config_dir.exists():
            config_dir.mkdir(parents=True, exist_ok=True)
            
        return config_dir

    async def initialize_kernel(self, model: Optional[str] = None) -> ConnectorEngine:
        settings = configparser.ConfigParser()
        
        settings_path = self.config_dir / 'settings.ini'
        if not settings_path.exists():
            # Create empty settings file if it doesn't exist
            settings_path.write_text('')
            
        with open(settings_path, "r", encoding="utf-8-sig") as settings_file:
            settings.read_file(settings_file)

        preferred_model = model if model else settings.get("General", "PreferredModel", fallback="gpt-3.5-turbo")
        
        # Get preferred spoutlets for each module from settings
        self.preferred_spoutlets = {}
        for module in ["Reduce", "Expand", "Enhance", "Iterate", "Mutate", "Imagine", "Converse", "Search", "Parse", "Evaluate", "Translate", "Generate"]:
            try:
                self.preferred_spoutlets[module] = settings.get(module, "PreferredSpoutlet", fallback="default")
            except configparser.Error:
                self.preferred_spoutlets[module] = "default"

        kernel = ConnectorEngine()
        
        if "gpt" in preferred_model.lower() or "o1-" in preferred_model.lower():
            api_key = settings.get("OpenAI", "ApiKey", fallback="")
            org_id = settings.get("OpenAI", "OrgId", fallback="")
        elif "claude" in preferred_model.lower():
            api_key = settings.get("Anthropic", "ApiKey", fallback="")
        elif "gemini" in preferred_model.lower():
            api_key = settings.get("Google", "ApiKey", fallback="")
        elif "deepseek" in preferred_model.lower():
            api_key = settings.get("DeepSeek", "ApiKey", fallback="")
        else:
            api_key = settings.get("Replicate", "ApiKey", fallback="")

        kernel.add_service(
            ConnectorService(
                service_id=self.service_id,
                model=preferred_model,
                api_token=api_key,
                org_id=org_id if "gpt" in preferred_model.lower() or "o1-" in preferred_model.lower() else None,
                base_url="https://api.deepseek.com" if "deepseek" in preferred_model.lower() else None
            )
        )

        return kernel

    def show_error_popup(self, message: str):
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror("Error", message)
        root.destroy()

    async def process_with_plugin(self, plugin_name: str, spoutlet: str = None, **kwargs):
        try:
            kernel = await self.initialize_kernel(kwargs.get('model'))
            
            # Convert plugin_name and spoutlet to lowercase for consistency
            plugin_name = plugin_name.lower()
            requested_spoutlet = spoutlet.lower() if spoutlet else "default"
            
            # Determine base plugin directory
            core_plugins = ["translate", "generate", "iterate", "mutate", "imagine", "converse", 
                           "search", "parse", "evaluate", "enhance", "expand", "search", "reduce", "expand"]
            base_dir = "core" if plugin_name in core_plugins else "addons"
            
            # Get the parent directory for this plugin
            base_path = Path(__file__).resolve().parent.parent
            parent_dir = str(base_path / base_dir / plugin_name)
            
            plugin = kernel.add_plugin(
                parent_directory=parent_dir,
                plugin_name=requested_spoutlet
            )

            logged_invoke = self.api_metrics_logger.log_kernel_invoke(kernel.invoke)
            result = await logged_invoke(plugin[requested_spoutlet], **kwargs)
             
            output = str(result)
            
            # Only copy to clipboard if not in CLI mode
            if not kwargs.get('is_cli', False):
                pyperclip.copy(output)
                
            return output

        except Exception as e:
            self.show_error_popup(f"An error occurred: {str(e)}")
            raise