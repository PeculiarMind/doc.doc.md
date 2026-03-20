#!/usr/bin/env python3
# plugin_info.py - Plugin Information component for doc.doc.md
# Part of doc.doc.md architecture (Level 3: Python Components)
# Implements plugin dependency tree rendering (DFS + cycle detection + ASCII)
# and parameter/command table formatting (column-aligned output).
#
# CLI Interface:
#   python3 plugin_info.py tree <plugins_dir>
#       - Render ASCII dependency tree of all plugins in <plugins_dir>
#       - Exit 0 on success, 1 on error (invalid dir, circular dep)
#       - Each plugin rendered with ANSI color: green=active, red=inactive
#   python3 plugin_info.py table
#       - Read TSV data from stdin, output column-aligned table to stdout
#       - Exit 0 on success, 1 on error (malformed input)
#
# Stdout contract:
#   tree: ASCII tree lines with ANSI color codes
#   table: space-padded columns matching input tab-separated columns

import json
import os
import sys

# ANSI color codes
_GREEN = "\033[32m"
_RED = "\033[31m"
_RESET = "\033[0m"


def _read_plugin(plugins_dir, plugin_name):
    """Read a plugin's descriptor.json and return a dict with its info.

    Returns None if descriptor is missing or invalid.
    """
    descriptor_path = os.path.join(plugins_dir, plugin_name, "descriptor.json")
    if not os.path.isfile(descriptor_path):
        return None
    try:
        with open(descriptor_path, "r") as f:
            d = json.load(f)
    except (json.JSONDecodeError, IOError):
        return None

    # Validate required fields (commands key must exist; empty {} is valid like jq behavior)
    if not d.get("name") or "commands" not in d:
        return None

    active = d.get("active", True)
    active = False if active is False else True

    process_cmd = d.get("commands", {}).get("process") or {}
    inputs = list((process_cmd.get("input") or {}).keys())
    outputs = list((process_cmd.get("output") or {}).keys())

    return {
        "name": plugin_name,
        "active": active,
        "inputs": inputs,
        "outputs": outputs,
    }


def _build_deps(plugin_info, all_plugins):
    """Build a dependency map from plugin input/output declarations.

    Plugin A depends on plugin B if any of B's declared output keys is also
    one of A's declared input keys.
    """
    plugin_outputs = {name: set(plugin_info[name]["outputs"]) for name in all_plugins}
    deps = {}
    for name in all_plugins:
        plugin_deps = []
        for input_param in plugin_info[name]["inputs"]:
            for other in all_plugins:
                if other == name:
                    continue
                if input_param in plugin_outputs[other] and other not in plugin_deps:
                    plugin_deps.append(other)
        deps[name] = plugin_deps
    return deps


def _detect_cycle(plugin, deps, visited, in_stack):
    """DFS cycle detection. Returns True if a cycle is detected."""
    visited.add(plugin)
    in_stack.add(plugin)

    for dep in deps.get(plugin, []):
        if dep not in visited:
            if _detect_cycle(dep, deps, visited, in_stack):
                return True
        elif dep in in_stack:
            return True

    in_stack.discard(plugin)
    return False


def _topo_sort(all_plugins, deps):
    """Kahn's algorithm topological sort.

    Returns a sorted list of plugin names, dependencies-first.
    Raises ValueError if a cycle is detected (should not happen after
    _detect_cycle validation).
    """
    in_degree = {name: 0 for name in all_plugins}
    for name in all_plugins:
        for dep in deps.get(name, []):
            in_degree[name] += 1

    queue = sorted(name for name in all_plugins if in_degree[name] == 0)
    result = []
    while queue:
        node = queue.pop(0)
        result.append(node)
        # find plugins that depend on this node
        for name in sorted(all_plugins):
            if node in deps.get(name, []):
                in_degree[name] -= 1
                if in_degree[name] == 0:
                    queue.append(name)
    if len(result) != len(all_plugins):
        raise ValueError("Cycle detected during topological sort")
    return result


def _render_label(name, active):
    """Return ANSI-colored plugin name: green for active, red for inactive."""
    color = _GREEN if active else _RED
    return f"{color}{name}{_RESET}"


def _print_tree(name, prefix, is_last, deps, plugin_info):
    """Recursively print the dependency tree for a plugin."""
    connector = "\u2514\u2500\u2500" if is_last else "\u251c\u2500\u2500"
    label = _render_label(name, plugin_info[name]["active"])
    print(f"{prefix}{connector} {label}")

    child_prefix = prefix + ("    " if is_last else "\u2502   ")

    children = deps.get(name, [])
    for i, child in enumerate(children):
        _print_tree(child, child_prefix, i == len(children) - 1, deps, plugin_info)


def run_tree(plugins_dir):
    """Render ASCII dependency tree of all plugins in plugins_dir.

    Returns 0 on success, 1 on error.
    """
    if not os.path.isdir(plugins_dir):
        print(f"Error: Plugin directory not found: {plugins_dir}", file=sys.stderr)
        return 1

    # Discover all plugins (sorted)
    plugin_names = sorted(
        name for name in os.listdir(plugins_dir)
        if os.path.isdir(os.path.join(plugins_dir, name))
    )

    # Read plugin info
    plugin_info = {}
    for name in plugin_names:
        info = _read_plugin(plugins_dir, name)
        if info is not None:
            plugin_info[name] = info

    all_plugins = sorted(plugin_info.keys())

    if not all_plugins:
        return 0

    # Build dependency map from declared input/output keys
    deps = _build_deps(plugin_info, all_plugins)

    # Detect circular dependencies
    visited = set()
    for name in all_plugins:
        if name not in visited:
            in_stack = set()
            if _detect_cycle(name, deps, visited, in_stack):
                print(
                    f"Error: Circular dependency detected involving plugin '{name}'",
                    file=sys.stderr,
                )
                return 1

    # Find root plugins (not depended on by any other plugin)
    is_child = set()
    for name in all_plugins:
        for child in deps[name]:
            is_child.add(child)

    root_plugins = [name for name in all_plugins if name not in is_child]

    # Render tree
    for i, name in enumerate(root_plugins):
        _print_tree(name, "", i == len(root_plugins) - 1, deps, plugin_info)

    return 0


def run_topo(plugins_dir, active_only=True):
    """Topologically sort plugins in plugins_dir by input/output dependencies.

    Prints each plugin name on its own line, dependencies first.
    Returns 0 on success, 1 on error.
    """
    if not os.path.isdir(plugins_dir):
        print(f"Error: Plugin directory not found: {plugins_dir}", file=sys.stderr)
        return 1

    plugin_names = sorted(
        name for name in os.listdir(plugins_dir)
        if os.path.isdir(os.path.join(plugins_dir, name))
    )

    plugin_info = {}
    for name in plugin_names:
        info = _read_plugin(plugins_dir, name)
        if info is not None:
            if active_only and not info["active"]:
                continue
            plugin_info[name] = info

    all_plugins = sorted(plugin_info.keys())
    if not all_plugins:
        return 0

    deps = _build_deps(plugin_info, all_plugins)

    # Validate no cycles
    visited = set()
    for name in all_plugins:
        if name not in visited:
            if _detect_cycle(name, deps, visited, set()):
                print(
                    f"Error: Circular dependency detected involving plugin '{name}'",
                    file=sys.stderr,
                )
                return 1

    try:
        ordered = _topo_sort(all_plugins, deps)
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    for name in ordered:
        print(name)
    return 0


def run_table():
    """Read TSV from stdin and output column-aligned table to stdout.

    Returns 0 on success, 1 on error.
    """
    try:
        lines = sys.stdin.read().splitlines()
    except IOError as e:
        print(f"Error: Could not read stdin: {e}", file=sys.stderr)
        return 1

    # Parse rows
    rows = []
    for line in lines:
        if line == "":
            continue
        rows.append(line.split("\t"))

    if not rows:
        return 0

    # Calculate max column widths
    num_cols = max(len(row) for row in rows)
    col_widths = [0] * num_cols
    for row in rows:
        for i, field in enumerate(row):
            col_widths[i] = max(col_widths[i], len(field))

    # Print aligned rows (left-align, pad to max width, 2-space separator)
    for row in rows:
        parts = []
        for i in range(num_cols):
            field = row[i] if i < len(row) else ""
            if i < num_cols - 1:
                parts.append(field.ljust(col_widths[i]))
            else:
                parts.append(field)
        print("  ".join(parts))

    return 0


def main():
    """CLI entry point."""
    if len(sys.argv) < 2:
        print("Usage: plugin_info.py tree <plugins_dir>", file=sys.stderr)
        print("       plugin_info.py table", file=sys.stderr)
        print("       plugin_info.py topo <plugins_dir>", file=sys.stderr)
        sys.exit(1)

    mode = sys.argv[1]

    if mode == "tree":
        if len(sys.argv) < 3:
            print("Error: tree mode requires <plugins_dir>", file=sys.stderr)
            sys.exit(1)
        sys.exit(run_tree(sys.argv[2]))
    elif mode == "table":
        sys.exit(run_table())
    elif mode == "topo":
        if len(sys.argv) < 3:
            print("Error: topo mode requires <plugins_dir>", file=sys.stderr)
            sys.exit(1)
        sys.exit(run_topo(sys.argv[2]))
    else:
        print(f"Error: Unknown mode '{mode}'. Use 'tree', 'table', or 'topo'.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
