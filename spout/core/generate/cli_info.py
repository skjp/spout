from spout.shared.plugin_options import PluginDefinition, PluginOption

PLUGIN_DEFINITION = PluginDefinition(
    name="generate",
    description="Generate text items based on a description and example",
    options=[
        PluginOption(
            name="description",
            flags=["--description", "-d"],
            help="Description of what to generate",
            required=True
        ),
        PluginOption(
            name="example",
            flags=["--example", "-e"],
            help="Example to base the generation on",
            required=False,
            default=" "
        ),
        PluginOption(
            name="batch_size",
            flags=["--batch-size", "-b"],
            help="Number of items to generate (defaults to 5 in CLI, 1 in GUI)",
            required=False
        ),
        PluginOption(
            name="already_gen",
            flags=["--already-gen", "-a"],
            help="List of already generated items to avoid duplicates",
            required=False,
            default=[]
        )
    ],
    help_text="""
    The generate plugin creates new content based on a description and example.

    Features:

    - Generates content matching your description

    - Uses provided examples as reference

    - Can generate multiple items in a batch

    - Avoids duplicates with already generated content

    This plugin is ideal for:

    - Creating variations of example content

    - Generating multiple related items

    - Producing unique content that follows patterns

    Note: When run from command line (python.exe), batch_size defaults to 5.
    When run from GUI (pythonw.exe), batch_size defaults to 1.
    """,
    examples=[
        "spout generate -d 'Product name for a coffee shop' -e 'Morning Brew'",
        "spout generate --description 'Blog title about AI' --example 'The Future of Machine Learning' --batch-size 3",
        "spout generate -d 'Marketing slogan' -e 'Just Do It' -b 5 -a 'Be Bold, Think Different' "
    ]
)