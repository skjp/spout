import configparser
import csv
import hashlib
import os
import time
from functools import wraps
from pathlib import Path


class APIMetricsLogger:
    def __init__(self, filename="api_metrics.csv"):
        # Get the config directory path
        self.config_dir = self._get_config_dir()
        self.filename = os.path.join(self.config_dir, filename)
        self.header = [
            "Start Time",
            "Duration(s)",
            "Model Id",
            "Skill Name",
            "Input Tokens",
            "Output Tokens",
            "Input Hash",
            "Output Hash",
        ]

    def _get_config_dir(self):
        """Get or create the config directory path"""
        try:
            # First try to get config dir from settings.ini
            config = configparser.ConfigParser()
            project_root = Path(__file__).resolve().parent.parent
            settings_path = project_root / 'config' / 'settings.ini'
            
            if settings_path.exists():
                config.read(settings_path)
                if 'General' in config and 'ConfigDir' in config['General']:
                    config_dir = Path(config['General']['ConfigDir'])
                else:
                    config_dir = project_root / 'config'
            else:
                config_dir = project_root / 'config'
            
            # Create config directory if it doesn't exist
            if not config_dir.exists():
                config_dir.mkdir(parents=True, exist_ok=True)
            
            return str(config_dir)
        except Exception:
            # Fallback to package directory if there's any error
            package_root = Path(__file__).resolve().parent.parent
            config_dir = package_root / 'config'
            config_dir.mkdir(parents=True, exist_ok=True)
            return str(config_dir)

    def _write_row(self, row_data):
        with open(self.filename, "a+", newline="") as file:
            writer = csv.writer(file)
            file.seek(0)
            if not file.read(1):  # File is empty, write header
                writer.writerow(self.header)
            writer.writerow(row_data)

    def log_api_call(
        self,
        start_time,
        duration,
        model_id,
        skill_name,
        input_tokens,
        output_tokens,
        input_hash,
        output_hash,
    ):
        formatted_start_time = time.strftime(
            "%Y-%m-%d %H:%M:%S", time.localtime(start_time)
        )
        data_row = [
            formatted_start_time,
            round(duration, 3),
            model_id,
            skill_name,
            input_tokens,
            output_tokens,
            input_hash,
            output_hash,
        ]
        self._write_row(data_row)

    def log_kernel_invoke(self, func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            model_id = skill_name = input_tokens = output_tokens = input_hash = output_hash = None

            try:
                input_text = str(kwargs)
                input_hash = self._compute_hash(input_text, method="md5")

                result = await func(*args, **kwargs)
                inner_content = self._get_inner_content(result)
                if hasattr(result, "input_tokens") and hasattr(result, "output_tokens"):
                    input_tokens, output_tokens = (
                        result.input_tokens,
                        result.output_tokens,
                    )
                else:
                    input_tokens, output_tokens = self._get_token_counts(
                        inner_content, kwargs
                    )
                model_id = self._get_model_id(result, inner_content)
                skill_name = self._get_skill_name(result, args, kwargs)

                output_text = str(inner_content)
                output_hash = self._compute_hash(output_text, method="md5")

                return result
            except Exception as e:
                output_hash = self._compute_hash(str(e), method="md5")
                raise
            finally:
                duration = time.time() - start_time
                if model_id and model_id != "none":
                    self.log_api_call(
                        start_time,
                        duration,
                        model_id,
                        skill_name,
                        input_tokens,
                        output_tokens,
                        input_hash,
                        output_hash,
                    )

        return wrapper

    def _get_inner_content(self, result):
        if hasattr(result, "get_inner_content"):
            return result.get_inner_content()
        return result

    def _get_token_counts(self, inner_content, kwargs):
        if hasattr(inner_content, "usage"):
            return (
                getattr(inner_content.usage, "prompt_tokens", "none"),
                getattr(inner_content.usage, "completion_tokens", "none"),
            )
        else:
            return (101, 202)

    def _get_model_id(self, result, inner_content):
        if hasattr(result, "model"):
            return result.model
        elif hasattr(inner_content, "model_id"):
            return inner_content.model_id
        elif hasattr(inner_content, "model"):
            return inner_content.model
        return "Unknown"
    def _get_skill_name(self, result, args, kwargs):
        if hasattr(result, "skill_name"):
            skill_name = result.skill_name
        elif args and hasattr(args[0], "skill_name"):
            skill_name = args[0].skill_name
        elif args and hasattr(args[0], "metadata"):
            skill_name = args[0].metadata.skill_name
        elif "skill_name" in kwargs:
            skill_name = kwargs["skill_name"]
        else:
            skill_name = "Unknown"

        if hasattr(result, "plugin_name"):
            plugin_name = result.plugin_name
        elif args and hasattr(args[0], "plugin_name"):
            plugin_name = args[0].plugin_name
        elif args and hasattr(args[0], "metadata"):
            plugin_name = args[0].metadata.plugin_name
        elif "plugin_name" in kwargs:
            plugin_name = kwargs["plugin_name"]
        else:
            plugin_name = "Unknown"

        # Get source from config if available
        source = None
        if hasattr(result, "source"):
            source = result.source
        
        # Add symbol based on source
        symbol = ""
        if source == "local":
            symbol = "*"
        elif source == "pro":
            symbol = "^"
        
        # If it's the default spoutlet, just return the module name with symbol
        if skill_name == "default":
            return f"{plugin_name}{symbol}"
        
        # Return in module:spoutlet format with symbol after spoutlet
        return f"{plugin_name}:{skill_name}{symbol}"

    def _compute_hash(self, text, method="sha256", length=8):
        if method == "md5":
            return hashlib.md5(text.encode("utf-8")).hexdigest()[:length]
        elif method == "sha1":
            return hashlib.sha1(text.encode("utf-8")).hexdigest()[:length]
        else:  # default to sha256
            return hashlib.sha256(text.encode("utf-8")).hexdigest()[:length]
