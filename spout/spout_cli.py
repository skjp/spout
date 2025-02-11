import asyncio
import configparser
import importlib
import sys
import time
from pathlib import Path
from typing import Optional, Type

import click

from spout.shared.spout_base_functions import SpoutBaseFunctionHandler
from spout.shared.test_runner import SharedSpoutletTester

# List of plugins that use SpoutBaseFunctionHandler
BASE_HANDLER_PLUGINS = set(['reduce', 'enhance', 'expand', 'search'])

class PluginRegistry:
    """Manages plugin registration and handler mapping"""
    
    def __init__(self):
        
        self.plugins = {}
        self.addon_plugins = {}
        self.handlers = {}
        # Set up proper Python path
        self.setup_python_path()
        self.load_plugins()
        self.load_addon_plugins()
    
    def setup_python_path(self) -> None:
        """Ensure all necessary paths are in sys.path"""
        project_root = Path(__file__).resolve().parent
        core_path = project_root / 'core'
        shared_path = project_root / 'shared'
        
        # Add paths if they're not already in sys.path
        for path in [project_root, core_path, shared_path]:
            path_str = str(path)
            if path_str not in sys.path:
                sys.path.append(path_str)
    
    def load_plugins(self) -> None:
        """Load all plugin definitions and handlers from core"""
        project_root = Path(__file__).resolve().parent
        core_path = project_root / 'core'
        
        for plugin_dir in core_path.iterdir():
            # Skip non-directories and __pycache__
            if not plugin_dir.is_dir() or plugin_dir.name == '__pycache__':
                continue
                
            plugin_name = plugin_dir.name.lower()
            
            # Load cli_info.py
            try:
                module = importlib.import_module(f"spout.core.{plugin_name}.cli_info")
                if hasattr(module, 'PLUGIN_DEFINITION'):
                    self.plugins[plugin_name] = module.PLUGIN_DEFINITION
            except ImportError as e:
                print(f"Failed to load plugin definition for {plugin_name}: {e}", file=sys.stderr)
                continue
            
            # Load custom handler if not a base plugin
            if plugin_name not in BASE_HANDLER_PLUGINS:
                try:
                    handler_module = importlib.import_module(f"spout.core.{plugin_name}.spout_{plugin_name}")
                    handler_class = getattr(handler_module, f"Spout{plugin_name.capitalize()}")
                    self.handlers[plugin_name] = handler_class
                except (ImportError, AttributeError) as e:
                    print(f"Failed to load handler for {plugin_name}: {e}", file=sys.stderr)
                    continue
    
    def load_addon_plugins(self) -> None:
        """Load all addon plugin definitions from addons directory"""
        project_root = Path(__file__).resolve().parent
        addons_path = project_root / 'addons'
        
        if not addons_path.exists():
            return
        
        for plugin_dir in addons_path.iterdir():
            # Skip non-directories and __pycache__
            if not plugin_dir.is_dir() or plugin_dir.name == '__pycache__':
                continue
            
            plugin_name = plugin_dir.name.lower()
            cli_info_path = plugin_dir / 'cli_info.py'
            handler_path = plugin_dir / f'spout_{plugin_name}.py'
            
            # Check for cli_info.py and absence of spout_addonmodulename.py
            if cli_info_path.exists() and not handler_path.exists():
                try:
                    module = importlib.import_module(f"spout.addons.{plugin_name}.cli_info")
                    if hasattr(module, 'PLUGIN_DEFINITION'):
                        self.addon_plugins[plugin_name] = module.PLUGIN_DEFINITION
                        # Automatically add to BASE_HANDLER_PLUGINS
                        BASE_HANDLER_PLUGINS.add(plugin_name)
                except ImportError as e:
                    print(f"Failed to load addon plugin definition for {plugin_name}: {e}", file=sys.stderr)
                    continue
    
    def get_handler(self, plugin_name: str) -> Type:
        """Get the appropriate handler class for a plugin"""
        if plugin_name in BASE_HANDLER_PLUGINS:
            return SpoutBaseFunctionHandler
        return self.handlers.get(plugin_name, SpoutBaseFunctionHandler)
    async def execute_plugin(self, plugin_name: str, handler, **kwargs):
        """Execute the plugin with the appropriate handler method"""
        plugin_name = plugin_name.lower()
        
        try:
            if plugin_name in BASE_HANDLER_PLUGINS:
                return await handler.process_function(
                    plugin_name.capitalize(),
                    spoutlet=kwargs.get('spoutlet'),
                    input=kwargs.get('parameters', {}).get('input') or kwargs.get('input')
                )
            
            # For custom handlers, call the plugin's main method
            if hasattr(handler, plugin_name):
                return await getattr(handler, plugin_name)(**kwargs)
            
            raise click.ClickException(f"Handler method '{plugin_name}' not found")
        except Exception as e:
            raise click.ClickException(f"Plugin execution failed: {str(e)}")

def run_module_tests(module_name: str, spoutlet: Optional[str] = None, 
                    examples: bool = False, test_file: Optional[str] = None) -> None:
    """Run tests for a specific module"""
    try:
        # Convert empty string to None for test_file
        if test_file == '':
            test_file = None
            
        # Create tester instance with optional test file
        tester = SharedSpoutletTester(module_name, test_cases_path=test_file)
        results = tester.run_module_tests(spoutlet, examples)
        
        click.echo(results)
        
    except Exception as e:
        raise click.ClickException(f"Error running tests: {str(e)}")

def update_preferred_model(model_name: str) -> None:
    """Update the preferred model in settings.ini if valid"""
    config_dir = Path(__file__).resolve().parent / 'config'
    
    # Read models.ini to validate model name
    models_config = configparser.ConfigParser()
    models_config.read(config_dir / 'models.ini', encoding='utf-8-sig')
    
    # Check if model exists in any section
    model_exists = False
    for section in models_config.sections():
        if model_name in models_config[section]:
            model_exists = True
            break
    
    if not model_exists:
        raise click.ClickException(f"Model '{model_name}' not found in models.ini")
    
    # Read existing settings file to preserve format
    settings_path = config_dir / 'settings.ini'
    with open(settings_path, 'r', encoding='utf-8-sig') as f:
        lines = f.readlines()
    
    # Find the General section and update/add the preferredmodel
    in_general = False
    found = False
    new_lines = []
    
    for line in lines:
        stripped = line.strip()
        if stripped == '[General]':
            in_general = True
        elif stripped.startswith('[') and stripped.endswith(']'):
            in_general = False
            
        if in_general and stripped.lower().startswith('preferredmodel='):
            new_lines.append(f'PreferredModel={model_name}\n')
            found = True
        else:
            new_lines.append(line)
    
    # Add preferredmodel if not found
    if not found:
        # Find the General section or create it
        if '[General]' not in ''.join(new_lines):
            new_lines.insert(0, '[General]\n')
        general_index = next(i for i, line in enumerate(new_lines) if '[General]' in line)
        new_lines.insert(general_index + 1, f'PreferredModel={model_name}\n')
    
    # Write back the file
    with open(settings_path, 'w', encoding='utf-8-sig') as f:
        f.writelines(new_lines)
    
    click.echo(f"Preferred model updated to: {model_name}")

class SpoutCLI(click.MultiCommand):
    """Custom Click MultiCommand for Spout CLI"""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.registry = PluginRegistry()
        self.show_timer = False

    def list_commands(self, ctx: click.Context) -> list:
        # Return both core and addon commands
        return sorted(list(self.registry.plugins.keys()) + list(self.registry.addon_plugins.keys()))

    def format_commands(self, ctx: click.Context, formatter: click.HelpFormatter) -> None:
        """Override default command formatting to separate core and addon plugins"""
        core_commands = []
        addon_commands = []
        
        # Sort plugins into core and addon lists
        for name in sorted(self.registry.plugins.keys()):
            plugin = self.registry.plugins[name]
            core_commands.append((name, plugin.description))
            
        for name in sorted(self.registry.addon_plugins.keys()):
            plugin = self.registry.addon_plugins[name]
            addon_commands.append((name, plugin.description))

        # Display core commands
        with formatter.section('Core Commands'):
            formatter.write_dl(core_commands)
            
        # Display addon commands if any exist
        if addon_commands:
            with formatter.section('Add-on Commands'):
                formatter.write_dl(addon_commands)

    def get_command(self, ctx: click.Context, cmd_name: str) -> Optional[click.Command]:
        cmd_name = cmd_name.lower()
        
        # Check both core and addon plugins
        plugin = None
        if cmd_name in self.registry.plugins:
            plugin = self.registry.plugins[cmd_name]
        elif cmd_name in self.registry.addon_plugins:
            plugin = self.registry.addon_plugins[cmd_name]
            
        if not plugin:
            return None

        # Create a custom help text that includes examples and spoutlet option
        help_text = plugin.help_text
        
        if hasattr(plugin, 'examples') and plugin.examples:
            help_text += "\n\nExamples:\n"
            help_text += "\n".join(f"\n  {example}" for example in plugin.examples)
        
        @click.command(name=cmd_name, help=help_text, options_metavar="\n\nInputs:")
        @click.argument('text', required=False)
        @click.option('--spoutlet', '-u', help='Specify the spoutlet to use', default=None)
        @click.option('--test', '-t', help='Run tests for this module (optionally specify test file)', 
                      is_flag=False, flag_value='', default=None)
        @click.option('--examples', '-x', help='Test and generate example files (optionally specify test file)', 
                      is_flag=False, flag_value='', default=None)
        @click.pass_context
        def plugin_command(ctx: click.Context, text: Optional[str] = None, spoutlet: Optional[str] = None, 
                          test: Optional[str] = None, examples: Optional[str] = None, **kwargs):
            """Execute the plugin command"""
            try:
                # If either test flag is present, run tests
                if test is not None or examples is not None:
                    # Use the provided test file name if any, otherwise None for default
                    test_file = test if test is not None else examples
                    run_module_tests(cmd_name, spoutlet, bool(examples is not None), test_file)
                    return

                # Rest of the validation and execution logic...
                if text:
                    if kwargs.get('input'):
                        raise click.UsageError("Cannot use both direct text and --input option")
                    kwargs['input'] = text

                # Get and instantiate the appropriate handler
                handler_class = self.registry.get_handler(cmd_name)
                handler = handler_class()

                if spoutlet:
                    kwargs['spoutlet'] = spoutlet

                start_time = time.perf_counter()
                asyncio.run(self.registry.execute_plugin(cmd_name, handler, **kwargs))
                end_time = time.perf_counter()
                
                if ctx.obj.get('show_timer'):
                    elapsed_ms = (end_time - start_time) * 1000
                    click.echo(f"\nExecution time: {elapsed_ms:.2f}ms", err=True)

            except Exception as e:
                raise click.ClickException(str(e))

        # Add plugin-specific options, making them not required if in test mode
        for option in plugin.options:
            plugin_command = click.option(
                *option.flags,
                help=option.help,
                required=False if '--test' in sys.argv or '-t' in sys.argv or '--examples' in sys.argv or '-x' in sys.argv else option.required,
                default=None
            )(plugin_command)

        return plugin_command

def create_cli():
    """Create and configure the CLI"""
    # Ensure config directory exists
    config_dir = Path(__file__).resolve().parent / 'config'
    config_dir.mkdir(parents=True, exist_ok=True)
    
    @click.group(cls=SpoutCLI, context_settings={'help_option_names': ['-h', '--help']}, invoke_without_command=True)
    @click.option('-m', '--timer', is_flag=True, help='Display processing time')
    @click.option('-p', '--preferred_model', help='List available models or set preferred model', 
                  is_flag=False, flag_value='', default=None)
    @click.pass_context
    def cli(ctx, timer: bool, preferred_model: Optional[str]):
        """Spout CLI - Command line Interface for Spout plugins
        
        Run 'spout COMMAND --help' for plugin-specific help.
        """
        ctx.ensure_object(dict)
        ctx.obj['show_timer'] = timer
        
        # Handle preferred_model
        if preferred_model is not None:
            if preferred_model == '':
                # Show available models
                config_dir = Path(__file__).resolve().parent / 'config'
                models_config = configparser.ConfigParser()
                models_config.read(config_dir / 'models.ini', encoding='utf-8-sig')
                
                click.echo("Available models:")
                for section in models_config.sections():
                    click.echo(f"\n[{section}]")
                    for model, enabled in models_config[section].items():
                        if enabled == '1':
                            click.echo(f"  {model}")
            else:
                update_preferred_model(preferred_model)
            ctx.exit()
            
        # Only show the plugin list if no command is invoked
        if ctx.invoked_subcommand is None and len(sys.argv) == 1:
            # Don't show help text since it will show commands twice
            click.echo("Spout CLI - Command line Interface for Spout plugins\n")
            click.echo("Run 'spout COMMAND --help' for plugin-specific help.\n")
            click.echo("Available plugins:")
            # Show core plugins
            click.echo("\nCore plugins:")
            for name, plugin in sorted(ctx.command.registry.plugins.items()):
                click.echo(f"  {name}: {plugin.description}")
            # Show addon plugins
            if ctx.command.registry.addon_plugins:
                click.echo("\nAdd-on plugins:")
                for name, plugin in sorted(ctx.command.registry.addon_plugins.items()):
                    click.echo(f"  {name}: {plugin.description}")
            ctx.exit()
    
    return cli

cli = create_cli()

if __name__ == '__main__':
    cli()