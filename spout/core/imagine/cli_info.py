from spout.shared.plugin_options import PluginDefinition, PluginOption

PLUGIN_DEFINITION = PluginDefinition(
    name="imagine",
    description="Generate plans and ideas based on specified objectives",
    options=[
        PluginOption(
            name="objective",
            flags=["--objective", "-o"],
            help="Main goal or objective to imagine",
            required=True
        ),
        PluginOption(
            name="context",
            flags=["--context", "-c"],
            help="Additional context, constraints, or information. Use @SpoutCLI to include all module examples, or @Spout{ModuleName} for specific module examples.",
            required=True
        ),
        PluginOption(
            name="output_format",
            flags=["--output-format", "-f"],
            help="Output format for the generated plan",
            default="json",
            required=False
        ),
        PluginOption(
            name="stipulations",
            flags=["--stipulations", "-s"],
            help="Additional stipulations or constraints for the plan",
            default="",
            required=False
        )
    ],
    help_text="""
    The imagine plugin generates detailed descriptions or scenarios based on your objectives.

    Features:

    - Creates structured, step-by-step plans

    - Incorporates additional context and constraints

    - Supports multiple output formats

    - Includes module-specific examples via @Spout tags

    Special Context Tags:

    - @SpoutCLI: Include examples from all core modules

    - @Spout{ModuleName}: Include examples from a specific module
      Example: @SpoutExpand, @SpoutTranslate, etc.

    This plugin is ideal for:

    - Planning complex projects or tasks

    - Generating creative ideas and solutions

    - Breaking down objectives into actionable steps

    - Creating structured outlines""",
    examples=[
        'spout imagine -o "Design a garden" -c "Small urban space, shade-loving plants" -s "Budget: $500"',
        'spout imagine --objective "Write a story" --context "@SpoutCLI" --format "json"',
        'spout imagine -o "Plan website" -c "@SpoutExpand Low-cost hosting options" -s "Complete in 2 weeks"'
    ]
)