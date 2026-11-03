"""AI adapters are tested with mock APIs/CLIs, never accounts or real prompts."""
from pathlib import Path
import shutil
import subprocess
import unittest

REPO = Path(__file__).resolve().parents[1]


class AiBridgeTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("node"), "Node.js required for optional AI adapters")
    def test_provider_protocols_and_safety(self):
        result = subprocess.run(
            ["node", "--test", str(REPO / "quickshell/caelestia/tests/ai-bridge.test.mjs")],
            capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
