from spout.shared.plugin_options import PluginDefinition

PLUGIN_DEFINITION = PluginDefinition(
    name="expand",
    description="Elaborate and expand upon an input text",
    options=[],
    help_text="""
    The expand plugin elaborates and expands upon your input text.

    Features:

    - Adds relevant details and examples

    - Elaborates on key points

    - Provides additional context

    - Maintains original tone and style

    This plugin is ideal for:

    - Developing brief notes into full content

    - Adding depth to simple explanations

    - Creating more comprehensive documentation
    """,
    examples=[
        "spout expand 'AI is changing technology'",
        "spout expand  # uses clipboard content"
    ]
)