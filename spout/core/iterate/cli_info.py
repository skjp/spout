from spout.shared.plugin_options import PluginDefinition, PluginOption

PLUGIN_DEFINITION = PluginDefinition(
    name="iterate",
    description="Process multiple items of text using an example transformation",
    options=[
        PluginOption(
            name="example_preprocessed_line",
            flags=["--example-preprocessed-line", "-e"],
            help="Example of input line before processing",
            required=True
        ),
        PluginOption(
            name="example_processed_line",
            flags=["--example-processed-line", "-o"],
            help="Example of how the input line should be processed",
            required=True
        ),
        PluginOption(
            name="description",
            flags=["--description", "-d"],
            help="Description of the transformation to perform",
            required=True
        ),
        PluginOption(
            name="lines_per_call",
            flags=["--lines-per-call", "-b"],
            help="Number of lines to process in each API call",
            default="1",
            required=False
        ),
        PluginOption(
            name="preprocessed_lines",
            flags=["--preprocessed-lines", "-l"],
            help="Lines to be processed, separated by newlines",
            required=True
        )
    ],
    help_text="""
    The iterate plugin processes multiple lines of text using an example transformation.

    Features:

    - Learns from an input/output example pair

    - Applies the learned transformation to multiple lines

    - Can process lines in batches for efficiency

    - Maintains consistent transformation across all lines

    This plugin is ideal for:

    - Batch processing text transformations

    - Applying consistent formatting rules

    - Converting data between formats

    - Automating repetitive text operations

    The transformation is defined by:

    - An example input line

    - How that line should be transformed

    - A description of the transformation rule
    """,
    examples=[
        "spout iterate -e 'data: 123' -o '123' -d 'Extract number' -l 'data: 456\\ndata: 789'",
        "spout iterate --example-preprocessed-line 'John Doe' --example-processed-line 'Doe, J.' --description 'Format as last name, first initial' --preprocessed-lines 'Jane Smith\\nBob Johnson' --lines-per-call 2",
        "spout iterate -e 'buy milk' -o '- [ ] buy milk' -d 'Convert to checkbox task' -l 'walk dog\\ndo laundry'"
    ]
)