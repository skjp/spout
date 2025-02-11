from spout.shared.plugin_options import PluginDefinition, PluginOption

PLUGIN_DEFINITION = PluginDefinition(
    name="converse",
    description="Apply the conversational intelligence of an LLM",
    options=[
        PluginOption(
            name="primer",
            flags=["--primer", "-p"],
            help="Initial context or instructions for the conversation",
            required=True
        ),
        PluginOption(
            name="history_file",
            flags=["--history-file", "-f"],
            help="Path to the conversation history file",
            required=False
        ),
        PluginOption(
            name="recent_message",
            flags=["--recent-message", "-r"],
            help="The most recent message in the conversation",
            required=True
        ),
        PluginOption(
            name="model",
            flags=["--model", "-m"],
            help="AI model to use for the conversation",
            default=None
        )
    ],
    help_text="""
    The converse plugin enables interactive conversations with an AI assistant.

    Features:

    - Maintains conversation context and history

    - Customizable conversation primer and rules 

    - Support for different AI models

    - Persistent conversation storage

The conversation history can be saved to a file to maintain continuity across sessions. The primer helps establish the AI assistant's role and behavior. Different AI models can be selected based on needed capabilities.
    """,
    examples=[
        "spout converse --primer 'You are a helpful assistant' --history_file 'chat_history.txt' --recent_message 'Hello'",
        "spout converse -p 'You are a coding tutor' -f 'python_help.txt' -r 'How do I use lists?' -m gpt-4o"
    ]
)