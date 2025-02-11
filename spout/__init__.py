"""
Spout: Synergistic Plugins Optimizing Usability of Transformers

A modular framework for text processing and AI interaction.
"""
# Import commonly used classes for easier access
try:
    from .core.converse.spout_converse import SpoutConverse
    from .core.evaluate.spout_evaluate import SpoutEvaluate
    from .core.generate.spout_generate import SpoutGenerate
    from .core.imagine.spout_imagine import SpoutImagine
    from .core.iterate.spout_iterate import SpoutIterate
    from .core.parse.spout_parse import SpoutParse
    from .shared.api_logging import APIMetricsLogger
    from .shared.base_handler import BaseHandler
    from .shared.connector import ConnectorEngine, ConnectorResult, ConnectorService
    from .shared.plugin_options import PluginDefinition, PluginOption
    from .shared.spout_base_functions import SpoutBaseFunctionHandler

    __all__ = [
        'SpoutEvaluate',
        'SpoutGenerate',
        'SpoutIterate',
        'SpoutImagine',
        'SpoutParse',
        'SpoutConverse',
        'BaseHandler',
        'SpoutBaseFunctionHandler',
        'PluginDefinition',
        'PluginOption',
        'ConnectorEngine',
        'ConnectorService',
        'ConnectorResult',
        'APIMetricsLogger'
    ]
except ImportError as e:
    print(f"Warning: Not all modules could be imported: {e}")