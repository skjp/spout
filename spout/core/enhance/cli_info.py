from spout.shared.plugin_options import PluginDefinition

PLUGIN_DEFINITION = PluginDefinition(
    name="enhance",
    description="Improve the quality and clarity of an input text",
    options=[],
    help_text="""
    The enhance plugin improves your text by:

    - Refining grammar and word choice

    - Improving clarity and readability

    - Strengthening the overall structure

    - Maintaining the original meaning and intent

    This plugin is ideal for:

    - Polishing written content

    - Improving professional communications

    - Enhancing documentation quality
    """,
    examples=[
        "spout enhance 'Text that needs improvement'",
        "spout enhance  # uses clipboard content"
    ]
)