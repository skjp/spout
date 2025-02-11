import configparser
import json
import os
import re
from functools import partial
from pathlib import Path
from typing import Any, Callable, Dict

import anthropic
import google.generativeai as genai
import openai  # Add this import
import replicate
import tiktoken


class ConnectorEngine:
    def __init__(self):
        self.plugins = {}
        self.services = {}

    def add_plugin(
        self, parent_directory: str, plugin_name: str
    ) -> Dict[str, Callable]:
        plugin_functions = {}
        
        # Convert plugin_name to lowercase for consistency
        plugin_name = plugin_name.lower()
        
        # Get the base directory name (e.g., 'reduce')
        base_name = os.path.basename(parent_directory)
        parent_dir = os.path.dirname(parent_directory)
        
        # Check each plugin directory in order of precedence
        for suffix in ["local", "pro", "plugins"]:
            plugin_dir = os.path.join(parent_dir, base_name, f"{base_name}_{suffix}")
            
            if os.path.exists(plugin_dir):
                spoutlet_dir = os.path.join(plugin_dir, plugin_name)
                
                if os.path.exists(spoutlet_dir):
                    # Find all JSON and TXT files
                    json_files = [f for f in os.listdir(spoutlet_dir) if f.endswith('.json')]
                    txt_files = [f for f in os.listdir(spoutlet_dir) if f.endswith('.txt')]
                    
                    # Check for required files and warn about extras
                    if not json_files or not txt_files:
                        continue  # Skip if missing required files
                    
                    if len(json_files) > 1 or len(txt_files) > 1:
                        print(f"Warning: Multiple JSON or TXT files found in {spoutlet_dir}. Using first files found.")
                    
                    config_path = os.path.join(spoutlet_dir, json_files[0])
                    prompt_path = os.path.join(spoutlet_dir, txt_files[0])
                    
                    with open(config_path, "r") as config_file:
                        config = json.load(config_file)
                        config["plugin_name"] = base_name
                        config["skill_name"] = plugin_name
                        # Add source information
                        config["source"] = suffix  # Store where we found the spoutlet
                        
                    with open(prompt_path, "r") as prompt_file:
                        prompt = prompt_file.read()

                    plugin_functions[plugin_name] = partial(
                        self._run_function, config, prompt, plugin_name
                    )
                    break

        if not plugin_functions:
            raise FileNotFoundError(f"Plugin {plugin_name} not found in any directory")

        self.plugins[plugin_name] = plugin_functions
        return plugin_functions

    def add_service(self, service):
        self.services[service.service_id] = service

    async def _run_function(
        self, config: Dict[str, Any], prompt: str, skill_name: str, **kwargs
    ):
        service = self.services.get("default")
        if not service:
            raise ValueError("No default service configured")

        execution_settings = config.get("execution_settings", {}).get("default", {})
        input_variables = {
            var["name"]: kwargs.get(var["name"], var.get("defaultValue"))
            for var in config.get("input_variables", [])
        }

        def replace_var(match):
            var_name = match.group(1)
            return str(input_variables.get(var_name, match.group(0)))

        formatted_prompt = re.sub(r"\{\{\$(.*?)\}\}", replace_var, prompt)

        content, input_tokens, output_tokens = await service.complete(
            formatted_prompt, **execution_settings
        )
        
        return ConnectorResult(
            content,
            model=service.model,
            skill_name=skill_name,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            plugin_name=config["plugin_name"],
            source=config.get("source")
        )

    async def invoke(self, function, **kwargs):
        return await function(**kwargs)


class ConnectorService:
    def __init__(self, service_id: str, model: str, api_token: str, org_id: str = None, base_url: str = None):
        self.service_id = service_id
        self.model = model
        self.api_token = api_token
        self.base_url = base_url
        self.encoding = self._get_tiktoken_encoding()
        
        # Initialize service clients
        if 'gemini' in model.lower():
            genai.configure(api_key=api_token)
        elif 'claude' in model.lower():
            self.anthropic_client = anthropic.Anthropic(api_key=api_token)
        elif 'gpt' in model.lower() or 'o1-' in model.lower() or 'deepseek' in model.lower():
            openai.api_key = api_token
            if org_id:  # Set organization ID if provided
                openai.organization = org_id

    def _get_tiktoken_encoding(self):
        config = configparser.ConfigParser()
        project_root = Path(__file__).resolve().parent.parent
        settings_path = project_root / 'config' / 'settings.ini'
        
        # Create config directory if it doesn't exist
        settings_path.parent.mkdir(parents=True, exist_ok=True)
        
        if not settings_path.exists():
            # Create empty settings file if it doesn't exist
            settings_path.write_text('')
        
        with open(settings_path, "r", encoding="utf-8-sig") as config_file:
            config.read_file(config_file)
        token_model = config.get("General", "TokenCountModel", fallback="gpt-3.5-turbo")
        return tiktoken.encoding_for_model(token_model)

    async def complete(self, prompt: str, **kwargs):
        try:
            if 'gemini' in self.model.lower():
                return await self._complete_with_gemini(prompt, **kwargs)
            elif 'claude' in self.model.lower():
                return await self._complete_with_anthropic(prompt, **kwargs)
            elif 'gpt' in self.model.lower() or 'o1-' in self.model.lower() or 'deepseek' in self.model.lower():
                return await self._complete_with_openai(prompt, **kwargs)
            else:
                return await self._complete_with_llm(prompt, **kwargs)
        except Exception as e:
            print(f"Error in complete method: {str(e)}")
            raise

    async def _complete_with_gemini(self, prompt: str, **kwargs):
        supported_params = [
            "max_tokens",
            "temperature",
        ]
        
        # Rename 'max_tokens' to 'max_output_tokens' for Gemini
        if 'max_tokens' in kwargs:
            kwargs['max_output_tokens'] = kwargs.pop('max_tokens')
        
        filtered_kwargs = {k: v for k, v in kwargs.items() if k in supported_params}

        input_tokens = len(self.encoding.encode(prompt))

        model = genai.GenerativeModel(self.model)
        
        generation_config = genai.types.GenerationConfig(
            candidate_count=1,
            **filtered_kwargs
        )

        response = model.generate_content(
            prompt,
            generation_config=generation_config
        )

        output = response.text
        output_tokens = len(self.encoding.encode(output))

        return output, input_tokens, output_tokens

    async def _complete_with_anthropic(self, prompt: str, **kwargs):
        supported_params = [
            "max_tokens",
            "temperature",
        ]
        filtered_kwargs = {k: v for k, v in kwargs.items() if k in supported_params}

        input_tokens = len(self.encoding.encode(prompt))

        response = self.anthropic_client.messages.create(
            model=self.model,
            max_tokens=filtered_kwargs.get("max_tokens", 1000),
            temperature=filtered_kwargs.get("temperature", 0.7),
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        output = response.content[0].text
        output_tokens = len(self.encoding.encode(output))

        return output, input_tokens, output_tokens

    async def _complete_with_openai(self, prompt: str, **kwargs):
        supported_params = [
            "max_tokens",
            "temperature",
            "top_p",
            "presence_penalty",
            "frequency_penalty",
        ]
        filtered_kwargs = {k: v for k, v in kwargs.items() if k in supported_params}

        input_tokens = len(self.encoding.encode(prompt))

        client = openai.AsyncOpenAI(
            api_key=self.api_token,
            base_url=self.base_url if self.base_url else None
        )
        response = await client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            **filtered_kwargs
        )

        output = response.choices[0].message.content
        output_tokens = len(self.encoding.encode(output))

        return output, input_tokens, output_tokens

    async def _complete_with_llm(self, prompt: str, **kwargs):
        os.environ["REPLICATE_API_TOKEN"] = self.api_token

        supported_params = [
            "max_tokens",
            "temperature",
            "top_p",
            "presence_penalty",
            "frequency_penalty",
        ]
        filtered_kwargs = {k: v for k, v in kwargs.items() if k in supported_params}

        input_tokens = len(self.encoding.encode(prompt))

        if 'mixtral' in self.model:
            if 'max_tokens' in filtered_kwargs:
                filtered_kwargs['max_new_tokens'] = filtered_kwargs.pop('max_tokens')
        response = replicate.run(
            self.model, input={"prompt": prompt, **filtered_kwargs}
        )
        output = "".join(response)
        output_tokens = len(self.encoding.encode(output))

        return output, input_tokens, output_tokens


class ConnectorResult:
    def __init__(
        self,
        content: str,
        model: str,
        skill_name: str,
        input_tokens: int,
        output_tokens: int,
        plugin_name: str,
        source: str = None
    ):
        self.content = content
        self.model = model
        self.skill_name = skill_name
        self.input_tokens = input_tokens
        self.output_tokens = output_tokens
        self.plugin_name = plugin_name
        self.source = source

    def __str__(self):
        return self.content

    def get_inner_content(self):
        return self.content