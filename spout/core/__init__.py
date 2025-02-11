# spout/core/__init__.py

# Import specific classes or functions from submodules
from .converse.spout_converse import SpoutConverse
from .evaluate.spout_evaluate import SpoutEvaluate
from .generate.spout_generate import SpoutGenerate
from .imagine.spout_imagine import SpoutImagine
from .iterate.spout_iterate import SpoutIterate
from .mutate.spout_mutate import SpoutMutate
from .parse.spout_parse import SpoutParse
from .translate.spout_translate import SpoutTranslate

# Optionally, define what is available for import with *
__all__ = [
    "SpoutMutate",
    "SpoutTranslate",
    "SpoutParse",
    "SpoutConverse",
    "SpoutEvaluate",
    "SpoutGenerate",
    "SpoutIterate",
    "SpoutImagine"
]

# You can also include any package-level documentation or metadata
__version__ = "1.0.0"
__author__ = "Your Name"
