from spout.shared.plugin_options import PluginDefinition, PluginOption

PLUGIN_DEFINITION = PluginDefinition(
    name="mutate",
    description="Generate context-appropriate variants of an input text",
    options=[
        PluginOption(
            name="num_variants",
            flags=["--num_variants", "-n"],
            help="Number of text variants to generate (default: 1)",
            required=True
        ),
        PluginOption(
            name="substring",
            flags=["--substring", "-s"],
            help="Specific substring to modify. If not provided or '*', uses entire input",
            required=False
        ),
        PluginOption(
            name="mutation_level",
            flags=["--mutation_level", "-l"],
            help="Mutation intensity level (1-5), where 1 is subtle and 5 is dramatic (default: 1)",
            required=True
        ),
        PluginOption(
            name="input",
            flags=["--input", "-i"],
            help="Text to modify. If not provided, will use clipboard content",
            required=False
        )
    ],
    help_text="""
    The mutate plugin generates variations of text by replacing specified substrings with contextually appropriate alternatives.
    
    
    Features:

    - Generate multiple variants of the same text

    - Control mutation intensity (levels 1-5)

    - Target specific substrings or entire text

    - Maintains grammatical correctness and coherence

    Mutation Levels:

    1: Subtle changes that preserve meaning

    2: Minor alterations that slightly shift meaning

    3: Moderate changes that modify intent

    4: Significant alterations that transform meaning

    5: Dramatic changes that may invert or radically change meaning

    If no input text is provided, the content will be read from your clipboard. Results are returned in JSON format with the original substring and variants.
    """,
    examples=[
        "spout mutate --input 'The quick brown fox jumps over the lazy dog' --substring 'jumps over' --num_variants 3 --mutation_level 1",
        "spout mutate -i 'The scientist conducted groundbreaking research' -s 'conducted groundbreaking research' -n 2 -l 3",
        "spout mutate --input 'Hello world' --num_variants 2 --mutation_level 4  # modifies entire text",
        "spout mutate -i 'Important meeting tomorrow' -n 3 -l 2  # generates 3 variants of entire text"
    ]
)