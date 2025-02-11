from spout.shared.plugin_options import PluginDefinition, PluginOption

PLUGIN_DEFINITION = PluginDefinition(
    name="parse",
    description="Extract and structure input text based on specified categories",
    options=[
        PluginOption(
            name="input",
            flags=["--input", "-i"],
            help="Text to parse and analyze",
            required=False
        ),
        PluginOption(
            name="categories",
            flags=["--categories", "-c"],
            help="Categories or fields to extract from the text",
            required=True
        )
    ],
    help_text="""
    The parse plugin extracts structured information from text based on specified categories.

    Features:

    - Identifies and extracts relevant information

    - Organizes data into requested categories

    - Handles multiple categories simultaneously

    - Maintains context while parsing

    This plugin is ideal for:

    - Extracting specific fields from unstructured text

    - Converting free text into structured data

    - Automated information extraction

    Category Types:

    - Single fields (e.g., "name", "date")

    - Multiple related fields (e.g., "contact_info: email, phone")

    - Complex structures (e.g., "product: name, price, description")
    """,
    examples=[
        "spout parse -i 'John Doe, Software Engineer, john@email.com' -c 'name, title, email'",
        "spout parse --input 'Product: Widget 2000, Cost: $19.99' --categories 'product_name, price'",
        "spout parse -i 'Meeting at 3pm with Alice about project X' -c 'time, attendees, topic'"
    ]
)