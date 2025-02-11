from spout.shared.plugin_options import PluginDefinition

PLUGIN_DEFINITION = PluginDefinition(
    name="search",
    description="Generate a list of relevant URLs for research on a given topic",
    options=[],  # Basic plugins don't need options as they use input text directly
    help_text="""
    The search plugin generates a comprehensive list of web URLs related to your topic.

    Features:

    - Provides 10-25 relevant URLs

    - Includes multiple search engines

    - Incorporates academic sources 

    - Uses specific search parameters

    This plugin is ideal for:

    - Academic research and papers

    - Technical documentation lookup

    - Finding educational resources

    - Comprehensive topic research

    Source Types:

    - Direct resource websites

    - Search engine queries

    - Academic databases

    - Technical documentation

    - Educational resources

    Note: Excludes social media posts and comments (Reddit, Twitter, etc.)
    """,
    examples=[
        "spout search 'Python async programming'",
        "spout search 'Climate change research methods'",
        "spout search 'Machine learning optimization techniques'",
        "spout search  # uses clipboard content"
    ]
)