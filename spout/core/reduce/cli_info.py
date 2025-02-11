from spout.shared.plugin_options import PluginDefinition

PLUGIN_DEFINITION = PluginDefinition(
    name="reduce",
    description="Generate a more concise version of an input text",
    options=[],
    help_text="""
    The reduce plugin creates a concise version of the input text.

    Features:

    - Reduces text length while preserving meaning

    - Extracts key points and main ideas

    - Maintains original context and tone

    - Supports direct text or clipboard input

    This plugin is ideal for:

    - Condensing long documents

    - Creating brief overviews

    - Extracting main points

    - Quick content digests

    Note: If no input text is provided, content will be read from clipboard
    """,
    examples=[
        "spout reduce 'Your long text here'",
        "spout reduce  # uses clipboard content"
    ]
)