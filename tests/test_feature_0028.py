#!/usr/bin/env python3
"""
Unit tests for FEATURE_0028: plugin_info.py component
Tests tree and table functionality without a shell environment.
Run from repository root: python3 -m unittest tests/test_feature_0028.py
"""

import importlib
import io
import json
import os
import sys
import tempfile
import unittest

# Ensure we can import plugin_info from the components directory
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMPONENTS_DIR = os.path.join(REPO_ROOT, "doc.doc.md", "components")
sys.path.insert(0, COMPONENTS_DIR)


def _import_plugin_info():
    """Import plugin_info module, raising SkipTest if not yet present."""
    try:
        import plugin_info
        importlib.reload(plugin_info)
        return plugin_info
    except ImportError:
        raise unittest.SkipTest("plugin_info.py not yet created (red phase)")


def _make_descriptor(tmpdir, name, active=True, inputs=None, outputs=None):
    """Create a plugin directory with descriptor.json inside tmpdir."""
    plugin_dir = os.path.join(tmpdir, name)
    os.makedirs(plugin_dir, exist_ok=True)
    process = {"description": "test", "command": "main.sh"}
    if inputs:
        process["input"] = {p: {"type": "string", "description": p, "required": True}
                            for p in inputs}
    if outputs:
        process["output"] = {p: {"type": "string", "description": p}
                             for p in outputs}
    descriptor = {
        "name": name,
        "version": "1.0.0",
        "description": f"Test plugin {name}",
        "active": active,
        "commands": {"process": process},
    }
    with open(os.path.join(plugin_dir, "descriptor.json"), "w") as f:
        json.dump(descriptor, f)
    return plugin_dir


# ---------------------------------------------------------------------------
# Tree tests
# ---------------------------------------------------------------------------

class TestTreeBasic(unittest.TestCase):
    """Test 1: basic tree rendering for a simple plugin set."""

    def setUp(self):
        self.pi = _import_plugin_info()

    def test_tree_renders_plugin_names(self):
        """Tree output contains all plugin names."""
        with tempfile.TemporaryDirectory() as tmpdir:
            _make_descriptor(tmpdir, "alpha", active=True)
            _make_descriptor(tmpdir, "beta", active=False)

            captured = io.StringIO()
            old_stdout = sys.stdout
            sys.stdout = captured
            try:
                result = self.pi.run_tree(tmpdir)
            finally:
                sys.stdout = old_stdout

            output = captured.getvalue()
            self.assertEqual(result, 0)
            self.assertIn("alpha", output)
            self.assertIn("beta", output)

    def test_tree_contains_connectors(self):
        """Tree output contains ├── or └── connectors."""
        with tempfile.TemporaryDirectory() as tmpdir:
            _make_descriptor(tmpdir, "myplugin", active=True)

            captured = io.StringIO()
            old_stdout = sys.stdout
            sys.stdout = captured
            try:
                self.pi.run_tree(tmpdir)
            finally:
                sys.stdout = old_stdout

            output = captured.getvalue()
            self.assertTrue(
                "├──" in output or "└──" in output,
                f"Expected tree connector in output, got: {output!r}"
            )

    def test_tree_dependency_child_appears_after_parent(self):
        """Dependency plugin appears as child (after) its consumer in tree output."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # consumer depends on provider (consumer inputs "sharedParam" which provider outputs)
            _make_descriptor(tmpdir, "consumer", active=True, inputs=["sharedParam"])
            _make_descriptor(tmpdir, "provider", active=True, outputs=["sharedParam"])

            captured = io.StringIO()
            old_stdout = sys.stdout
            sys.stdout = captured
            try:
                self.pi.run_tree(tmpdir)
            finally:
                sys.stdout = old_stdout

            output = captured.getvalue()
            lines = output.splitlines()
            consumer_line = next((i for i, l in enumerate(lines) if "consumer" in l), None)
            provider_line = next((i for i, l in enumerate(lines) if "provider" in l), None)
            self.assertIsNotNone(consumer_line, "consumer not found in tree output")
            self.assertIsNotNone(provider_line, "provider not found in tree output")
            self.assertGreater(provider_line, consumer_line,
                               "provider should appear after consumer (as a dependency child)")


class TestTreeCycleDetection(unittest.TestCase):
    """Test 2: cycle detection."""

    def setUp(self):
        self.pi = _import_plugin_info()

    def test_circular_dependency_exits_nonzero(self):
        """Circular dependency causes non-zero exit code."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # alpha outputs "foo", beta inputs "foo" -> beta depends on alpha
            # beta outputs "bar", alpha inputs "bar" -> alpha depends on beta
            # Cycle: alpha <-> beta
            _make_descriptor(tmpdir, "alpha", active=True, inputs=["bar"], outputs=["foo"])
            _make_descriptor(tmpdir, "beta", active=True, inputs=["foo"], outputs=["bar"])

            old_stderr = sys.stderr
            sys.stderr = io.StringIO()
            old_stdout = sys.stdout
            sys.stdout = io.StringIO()
            try:
                result = self.pi.run_tree(tmpdir)
            finally:
                sys.stderr = old_stderr
                sys.stdout = old_stdout

            self.assertEqual(result, 1, "Expected exit code 1 for circular dependency")

    def test_circular_dependency_prints_error_to_stderr(self):
        """Circular dependency prints error message to stderr."""
        with tempfile.TemporaryDirectory() as tmpdir:
            _make_descriptor(tmpdir, "circ_a", active=True, inputs=["bar"], outputs=["foo"])
            _make_descriptor(tmpdir, "circ_b", active=True, inputs=["foo"], outputs=["bar"])

            captured_stderr = io.StringIO()
            old_stderr = sys.stderr
            sys.stderr = captured_stderr
            old_stdout = sys.stdout
            sys.stdout = io.StringIO()
            try:
                self.pi.run_tree(tmpdir)
            finally:
                sys.stderr = old_stderr
                sys.stdout = old_stdout

            error_output = captured_stderr.getvalue()
            self.assertTrue(
                "ircular" in error_output or "cycle" in error_output.lower(),
                f"Expected cycle/circular in stderr, got: {error_output!r}"
            )


class TestTreeColors(unittest.TestCase):
    """Test 3: active vs inactive plugin color rendering."""

    def setUp(self):
        self.pi = _import_plugin_info()

    def test_active_plugin_uses_green_ansi(self):
        """Active plugin uses green ANSI escape code."""
        with tempfile.TemporaryDirectory() as tmpdir:
            _make_descriptor(tmpdir, "active_plugin", active=True)

            captured = io.StringIO()
            old_stdout = sys.stdout
            sys.stdout = captured
            try:
                self.pi.run_tree(tmpdir)
            finally:
                sys.stdout = old_stdout

            output = captured.getvalue()
            self.assertIn("\033[32m", output,
                          "Active plugin should have green ANSI code \\033[32m")
            self.assertIn("\033[0m", output,
                          "Output should have ANSI reset code \\033[0m")

    def test_inactive_plugin_uses_red_ansi(self):
        """Inactive plugin uses red ANSI escape code."""
        with tempfile.TemporaryDirectory() as tmpdir:
            _make_descriptor(tmpdir, "inactive_plugin", active=False)

            captured = io.StringIO()
            old_stdout = sys.stdout
            sys.stdout = captured
            try:
                self.pi.run_tree(tmpdir)
            finally:
                sys.stdout = old_stdout

            output = captured.getvalue()
            self.assertIn("\033[31m", output,
                          "Inactive plugin should have red ANSI code \\033[31m")


class TestTreeInvalidDir(unittest.TestCase):
    """Test 4: handles missing/invalid directory gracefully."""

    def setUp(self):
        self.pi = _import_plugin_info()

    def test_missing_dir_exits_nonzero(self):
        """Non-existent plugins dir returns non-zero exit code."""
        old_stderr = sys.stderr
        sys.stderr = io.StringIO()
        try:
            result = self.pi.run_tree("/nonexistent/path/that/does/not/exist")
        finally:
            sys.stderr = old_stderr

        self.assertEqual(result, 1, "Expected exit 1 for missing directory")

    def test_missing_dir_prints_to_stderr(self):
        """Non-existent plugins dir prints error to stderr."""
        captured_err = io.StringIO()
        old_stderr = sys.stderr
        sys.stderr = captured_err
        try:
            self.pi.run_tree("/nonexistent/path/xyz_does_not_exist")
        finally:
            sys.stderr = old_stderr

        self.assertTrue(len(captured_err.getvalue()) > 0,
                        "Expected non-empty stderr for missing directory")

    def test_empty_dir_exits_zero(self):
        """Empty plugins dir (no plugins) returns 0."""
        with tempfile.TemporaryDirectory() as tmpdir:
            old_stdout = sys.stdout
            sys.stdout = io.StringIO()
            try:
                result = self.pi.run_tree(tmpdir)
            finally:
                sys.stdout = old_stdout

            self.assertEqual(result, 0, "Empty plugins dir should exit 0")


# ---------------------------------------------------------------------------
# Table tests
# ---------------------------------------------------------------------------

class TestTableBasic(unittest.TestCase):
    """Test 5: basic table formatting (TSV input → aligned output)."""

    def setUp(self):
        self.pi = _import_plugin_info()

    def test_table_aligns_columns(self):
        """Table output has consistent column alignment."""
        tsv_input = "PLUGIN\tCOMMAND\tDIRECTION\nfile\tprocess\tinput\nstat\tprocess\toutput\n"
        captured = io.StringIO()
        old_stdout = sys.stdout
        sys.stdout = captured
        old_stdin = sys.stdin
        sys.stdin = io.StringIO(tsv_input)
        try:
            result = self.pi.run_table()
        finally:
            sys.stdout = old_stdout
            sys.stdin = old_stdin

        output = captured.getvalue()
        self.assertEqual(result, 0)
        lines = [l for l in output.splitlines() if l.strip()]
        self.assertGreaterEqual(len(lines), 2, "Expected at least 2 lines in table output")

        # All data values should be present
        self.assertIn("PLUGIN", output)
        self.assertIn("COMMAND", output)
        self.assertIn("DIRECTION", output)
        self.assertIn("file", output)
        self.assertIn("stat", output)

    def test_table_correct_column_alignment(self):
        """Table columns are padded consistently (test 7: correct column alignment)."""
        # PLUGIN col max width = 6 (PLUGIN), COMMAND col = 7 (COMMAND/process)
        tsv_input = "PLUGIN\tCOMMAND\nfile\tprocess\nmarkitdown\tinstall\n"
        captured = io.StringIO()
        old_stdout = sys.stdout
        sys.stdout = captured
        old_stdin = sys.stdin
        sys.stdin = io.StringIO(tsv_input)
        try:
            self.pi.run_table()
        finally:
            sys.stdout = old_stdout
            sys.stdin = old_stdin

        lines = captured.getvalue().splitlines()
        # Each line should start at the same column position for the second field
        # i.e., the first column width is consistent across rows
        first_col_positions = []
        for line in lines:
            if line.strip():
                # Find position of second column start (after first field + spaces)
                pos = len(line) - len(line.lstrip())
                # Actually check where the second field starts
                # The first field is padded to max width, then spaces
                # We check that second fields all start at same position
                stripped = line.lstrip()
                # Count leading spaces to find second col
                parts = line.split()
                if len(parts) >= 2:
                    # Find start of second word
                    first_end = line.index(parts[0]) + len(parts[0])
                    second_start = line.index(parts[1], first_end)
                    first_col_positions.append(second_start)

        if len(first_col_positions) >= 2:
            # All second columns should start at the same position
            self.assertEqual(
                len(set(first_col_positions)), 1,
                f"Second column should start at same position in all rows, got positions: {first_col_positions}"
            )

    def test_table_empty_input_exits_zero(self):
        """Empty input produces no output and exits 0."""
        old_stdout = sys.stdout
        sys.stdout = io.StringIO()
        old_stdin = sys.stdin
        sys.stdin = io.StringIO("")
        try:
            result = self.pi.run_table()
        finally:
            sys.stdout = old_stdout
            sys.stdin = old_stdin

        self.assertEqual(result, 0)


class TestTableMalformedInput(unittest.TestCase):
    """Test 6: handles malformed JSON gracefully (table mode)."""

    def setUp(self):
        self.pi = _import_plugin_info()

    def test_table_handles_inconsistent_columns_gracefully(self):
        """Table mode handles rows with inconsistent column counts gracefully."""
        # Inconsistent column counts - should not crash
        tsv_input = "COL1\tCOL2\tCOL3\nval1\tval2\n"
        captured = io.StringIO()
        old_stdout = sys.stdout
        sys.stdout = captured
        old_stdin = sys.stdin
        sys.stdin = io.StringIO(tsv_input)
        try:
            result = self.pi.run_table()
        finally:
            sys.stdout = old_stdout
            sys.stdin = old_stdin

        # Should not crash and should exit 0
        self.assertEqual(result, 0)
        output = captured.getvalue()
        self.assertIn("COL1", output)
        self.assertIn("val1", output)


# ---------------------------------------------------------------------------
# CLI entry-point tests
# ---------------------------------------------------------------------------

class TestCliEntryPoint(unittest.TestCase):
    """Test CLI main() entry point behavior."""

    def setUp(self):
        self.pi = _import_plugin_info()

    def test_tree_mode_invalid_dir_via_main(self):
        """plugin_info.py tree with invalid dir exits 1 via main()."""
        old_argv = sys.argv
        old_stderr = sys.stderr
        sys.stderr = io.StringIO()
        try:
            sys.argv = ["plugin_info.py", "tree", "/nonexistent_path_xyz_abc"]
            with self.assertRaises(SystemExit) as ctx:
                self.pi.main()
            self.assertEqual(ctx.exception.code, 1)
        finally:
            sys.argv = old_argv
            sys.stderr = old_stderr

    def test_no_args_exits_nonzero(self):
        """plugin_info.py with no args exits non-zero."""
        old_argv = sys.argv
        old_stderr = sys.stderr
        sys.stderr = io.StringIO()
        try:
            sys.argv = ["plugin_info.py"]
            with self.assertRaises(SystemExit) as ctx:
                self.pi.main()
            self.assertNotEqual(ctx.exception.code, 0)
        finally:
            sys.argv = old_argv
            sys.stderr = old_stderr


if __name__ == "__main__":
    unittest.main()
