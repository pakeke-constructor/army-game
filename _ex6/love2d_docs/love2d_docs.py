
'''
Love2D API documentation lookup tool for coding agents.

Parses the love2d API (from love2d_docs.json) into typed dataclasses,
and exposes a single `love2d_docs(query, verbosity)` function for lookup.
Agents can quickly check function signatures, object methods, and module
contents without reading the massive JSON directly.

Usage:
  love2d_docs("love.graphics")           -- list all functions/types in a module
  love2d_docs("love.graphics.newCanvas")  -- look up a specific function
  love2d_docs("love.audio.newSource")     -- look up a specific function
  love2d_docs("Canvas")                   -- look up a type and its methods
  love2d_docs("Canvas:getFilter")         -- look up a specific method on a type

Verbosity:
  0 (default) -- signatures only, concise. Good for browsing.
  1           -- full descriptions, all variants, argument details.

Example output (verbosity=0):
  love2d_docs("love.graphics.rectangle")
  => rectangle(mode: DrawMode, x: number, y: number, width: number, height: number)
     rectangle(mode: DrawMode, x: number, y: number, width: number, height: number, rx: number, ry: number)

  love2d_docs("Canvas")
  => Canvas
     Supertypes: Texture, Drawable, Object
       getFilter() -> min, mag, anisotropy
       getDimensions() -> width, height
       ...
'''


from __future__ import annotations
from dataclasses import dataclass, field
import json, os


@dataclass
class Argument:
    name: str = ""
    type: str = ""
    description: str = ""
    default: str = ""
    table: list[Argument] = field(default_factory=list)


@dataclass
class ReturnValue:
    name: str = ""
    type: str = ""
    description: str = ""


@dataclass
class Variant:
    description: str = ""
    arguments: list[Argument] = field(default_factory=list)
    returns: list[ReturnValue] = field(default_factory=list)


@dataclass
class Function:
    name: str = ""
    description: str = ""
    variants: list[Variant] = field(default_factory=list)


@dataclass
class EnumConstant:
    name: str = ""
    description: str = ""


@dataclass
class Enum:
    name: str = ""
    description: str = ""
    constants: list[EnumConstant] = field(default_factory=list)


@dataclass
class LoveType:
    name: str = ""
    description: str = ""
    supertypes: list[str] = field(default_factory=list)
    functions: list[Function] = field(default_factory=list)
    constructors: list[str] = field(default_factory=list)


@dataclass
class Module:
    name: str = ""
    description: str = ""
    functions: list[Function] = field(default_factory=list)
    types: list[LoveType] = field(default_factory=list)
    enums: list[Enum] = field(default_factory=list)


@dataclass
class LoveAPI:
    version: str = ""
    functions: list[Function] = field(default_factory=list)
    modules: list[Module] = field(default_factory=list)
    types: list[LoveType] = field(default_factory=list)
    callbacks: list[Function] = field(default_factory=list)


def _make(cls, data):
    """Recursively construct a dataclass from a dict."""
    if not isinstance(data, dict):
        return data
    hints = cls.__dataclass_fields__
    kwargs = {}
    for k, v in data.items():
        if k not in hints:
            continue
        ft = hints[k].type
        if isinstance(v, list):
            # resolve the inner type from e.g. "list[Argument]"
            inner = _resolve_type(ft)
            if inner and hasattr(inner, '__dataclass_fields__'):
                kwargs[k] = [_make(inner, item) for item in v]
            else:
                kwargs[k] = v
        elif isinstance(v, dict):
            inner = _resolve_type(ft)
            if inner and hasattr(inner, '__dataclass_fields__'):
                kwargs[k] = _make(inner, v)
            else:
                kwargs[k] = v
        else:
            kwargs[k] = v
    return cls(**kwargs)


_TYPE_MAP = {
    'Argument': Argument, 'ReturnValue': ReturnValue, 'Variant': Variant,
    'Function': Function, 'EnumConstant': EnumConstant, 'Enum': Enum,
    'LoveType': LoveType, 'Module': Module, 'LoveAPI': LoveAPI,
}

def _resolve_type(type_str: str):
    """Extract inner class from type strings like 'list[Function]' or 'Function'."""
    m = __import__('re').match(r'list\[(\w+)\]', type_str)
    if m:
        return _TYPE_MAP.get(m.group(1))
    return _TYPE_MAP.get(type_str)


JSON_PATH = os.path.join(os.path.dirname(__file__), "love2d_docs.json")

with open(JSON_PATH, "r") as f:
    _DATA: LoveAPI = _make(LoveAPI, json.load(f))

# Build lookup indices
_MODULES: dict[str, Module] = {m.name: m for m in _DATA.modules}
_TYPES: dict[str, LoveType] = {}
for t in _DATA.types:
    _TYPES[t.name] = t
for mod in _DATA.modules:
    for t in mod.types:
        _TYPES[t.name] = t


def _sig(fn: Function, variant: Variant | None = None):
    """One-line signature: name(arg: type, ...) -> ret_type"""
    v = variant or (fn.variants[0] if fn.variants else None)
    args = ""
    ret = ""
    if v:
        args = ", ".join(f"{a.name}: {a.type}" for a in v.arguments)
        if v.returns:
            ret = " -> " + ", ".join(r.type for r in v.returns)
    return f"{fn.name}({args}){ret}"


def _fmt_variant(v: Variant):
    lines = []
    if v.description:
        lines.append(v.description)
    if v.arguments:
        lines.append("  Arguments:")
        for a in v.arguments:
            lines.append(f"    {a.name} ({a.type or '?'}): {a.description}")
    if v.returns:
        lines.append("  Returns:")
        for r in v.returns:
            lines.append(f"    {r.name} ({r.type or '?'}): {r.description}")
    return "\n".join(lines)


def _fmt_function(fn: Function, verbosity: int = 0):
    if verbosity == 0:
        lines = []
        for i, v in enumerate(fn.variants):
            lines.append(_sig(fn, v))
        return "\n".join(lines)
    lines = [f"{fn.name}: {fn.description}"]
    for i, v in enumerate(fn.variants):
        if len(fn.variants) > 1:
            lines.append(f"  Variant {i+1}: {_sig(fn, v)}")
        lines.append(_fmt_variant(v))
    return "\n".join(lines)


def _fmt_module(mod: Module, verbosity: int = 0):
    if verbosity == 0:
        lines = [f"love.{mod.name}"]
        for fn in mod.functions:
            lines.append(f"  {_sig(fn)}")
        if mod.types:
            lines.append(f"Types: {', '.join(t.name for t in mod.types)}")
        if mod.enums:
            lines.append(f"Enums: {', '.join(e.name for e in mod.enums)}")
        return "\n".join(lines)
    lines = [f"love.{mod.name}: {mod.description}"]
    fns = [f.name for f in mod.functions]
    if fns:
        lines.append(f"Functions: {', '.join(fns)}")
    types = [t.name for t in mod.types]
    if types:
        lines.append(f"Types: {', '.join(types)}")
    enums = [e.name for e in mod.enums]
    if enums:
        lines.append(f"Enums: {', '.join(enums)}")
    return "\n".join(lines)


def _fmt_type(t: LoveType, verbosity: int = 0):
    if verbosity == 0:
        lines = [t.name]
        if t.supertypes:
            lines.append(f"Supertypes: {', '.join(t.supertypes)}")
        for fn in t.functions:
            lines.append(f"  {_sig(fn)}")
        return "\n".join(lines)
    lines = [f"{t.name}: {t.description}"]
    if t.supertypes:
        lines.append(f"Supertypes: {', '.join(t.supertypes)}")
    fns = [f.name for f in t.functions]
    if fns:
        lines.append(f"Methods: {', '.join(fns)}")
    return "\n".join(lines)


def love2d_docs(query: str, verbosity: int = 0):
    # "love.X" -> module
    # "love.X.func" -> module function
    # "TypeName" -> type lookup
    # "TypeName:method" -> type method lookup
    parts = query.split(".")

    if parts[0] == "love" and len(parts) == 2:
        mod = _MODULES.get(parts[1])
        if mod:
            return _fmt_module(mod, verbosity)
        return f"Module '{parts[1]}' not found"

    if parts[0] == "love" and len(parts) == 3:
        mod = _MODULES.get(parts[1])
        if not mod:
            return f"Module '{parts[1]}' not found"
        for fn in mod.functions:
            if fn.name == parts[2]:
                return _fmt_function(fn, verbosity)
        return f"Function '{parts[2]}' not found in love.{parts[1]}"

    # Type or Type:method
    if ":" in query:
        type_name, method_name = query.split(":", 1)
        t = _TYPES.get(type_name)
        if not t:
            return f"Type '{type_name}' not found"
        for fn in t.functions:
            if fn.name == method_name:
                return _fmt_function(fn, verbosity)
        return f"Method '{method_name}' not found on {type_name}"

    # Plain type name
    t = _TYPES.get(query)
    if t:
        return _fmt_type(t, verbosity)

    return f"'{query}' not found"


# Quick smoke test when run directly
if __name__ == "__main__":
    print("=== love.graphics v0 ===")
    print(love2d_docs("love.graphics")[:600])
    print()
    print("=== love.graphics.newCanvas v0 ===")
    print(love2d_docs("love.graphics.newCanvas"))
    print()
    print("=== love.graphics.newCanvas v1 ===")
    print(love2d_docs("love.graphics.newCanvas", 1))
    print()
    print("=== Canvas v0 ===")
    print(love2d_docs("Canvas"))
    print()
    print("=== Canvas:getFilter v0 ===")
    print(love2d_docs("Canvas:getFilter"))
    print()
    print("=== Canvas:getFilter v1 ===")
    print(love2d_docs("Canvas:getFilter", 1))
