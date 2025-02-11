from spout.shared.plugin_options import PluginDefinition, PluginOption

PLUGIN_DEFINITION = PluginDefinition(
    name="evaluate",
    description="Compare multiple inputs based on specified criteria",
    options=[
        PluginOption(
            name="combined_inputs",
            flags=["--combined-inputs", "-i"],
            help="Multiple inputs to evaluate, combined into a single string",
            required=True
        ),
        PluginOption(
            name="separator",
            flags=["--separator", "-s"],
            help="Character or string that separates the inputs",
            required=False,
            default="@@"
        ),
        PluginOption(
            name="judging_criteria",
            flags=["--judging-criteria", "-c"],
            help="Criteria for evaluating and comparing the inputs",
            required=True
        ),
        PluginOption(
            name="explanation",
            flags=["--explanation", "-e"],
            help="Additional context or explanation for the evaluation",
            required=False,
            default=False
        )
    ],
    help_text="""
    The evaluate plugin compares and ranks multiple inputs based on specified criteria.

    Features:

    - Detailed ranking of multiple inputs with scores

    - Customizable evaluation criteria with optional weights

    - Optional explanations for each ranking

    - JSON output with rankings, scores, and explanations

    Output Format:

    - Rank: Numerical ranking from best to worst

    - Name/Input: The evaluated text

    - Score: Numerical score based on criteria (0-10)

    - Explanation: Optional justification for the ranking
    """,
    examples=[
        "spout evaluate -i 'beonte@@onetuh@@tesknot@@romeniu@@zovesty' -c 'appropriateness as a first name'",
        "spout evaluate --combined_inputs 'sally sells wood chucks at the sea shore@@How many sea shells could sally sell to a wood chuck.' --separator '@@' --judging_criteria 'clarity:0.6,conciseness:0.4' --explanation false",
        "spout evaluate -i 'The cat sat on the mat@@A feline rested upon the floor covering@@The small cat positioned itself atop the mat' -c 'simplicity,directness' -e true",
        "spout evaluate --combined_inputs 'Option A: Expand into new markets@@Option B: Focus on existing customer base@@Option C: Diversify product line' --separator '@@' --judging_criteria 'risk:0.3,potential_roi:0.4,feasibility:0.3' --explanation true"
    ]
)