from spout.shared.plugin_options import PluginDefinition, PluginOption

PLUGIN_DEFINITION = PluginDefinition(
    name="translate",
    description="Modify an input text with a specified parameter",
    options=[
        PluginOption(
            name="specification",
            flags=["--specification", "-s"],
            help="Target language or format specification (e.g., 'to Spanish', 'to JSON')",
            required=True
        ),
        PluginOption(
            name="input",
            flags=["--input", "-i"],
            help="Text to translate. If not provided, will use clipboard content",
            required=False
        )
    ],
    help_text="""
    The translate plugin converts text between different languages or formats.

    Features:

    - Language translation (e.g., English to Spanish)

    - Format conversion (e.g., text to JSON)

    - Maintains formatting and context

    - Supports clipboard input

    This plugin is ideal for:

    - Converting between languages

    - Transforming data formats

    - Maintaining consistent translations

    - Quick format conversions

    Note: If no input text is provided, content will be read from clipboard
    """,
    examples=[
        "spout translate --specification 'to Spanish' --input 'Hello world'",
        "spout translate -s 'to JSON' -i 'name: John, age: 30'",
        "spout translate -s 'to French'  # uses clipboard content"
    ]
)