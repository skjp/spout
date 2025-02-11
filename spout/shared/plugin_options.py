from dataclasses import dataclass
from typing import List, Optional


@dataclass
class PluginOption:
    name: str
    flags: List[str]
    help: str
    type: type = str # type: ignore
    default: Optional[any] = None
    required: bool = False
    is_flag: bool = False

@dataclass
class PluginDefinition:
    name: str
    description: str
    options: List[PluginOption]
    required_args: List[str] = None
    help_text: str = ""
    examples: List[str] = None