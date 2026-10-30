"""Fresh-checkout/config installation tests; never alter the real user's home.

Run: python3 -m unittest discover -s tests -v
"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
TEMP = "/tmp/opencode" if Path("/tmp/opencode").is_dir() else None


class InstallationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.export = tempfile.TemporaryDirectory(prefix="orangedots-export-", dir=TEMP)
        # A different clone location, with spaces, no .git directory, and no
        # ignored native build products. Include current uncommitted source.
        cls.checkout = Path(cls.export.name) / "portable checkout" / "Orange Dots"
        cls.checkout.mkdir(parents=True)
        for name in ("hypr", "caelestia", "quickshell", "scripts"):
            shutil.copytree(REPO / name, cls.checkout / name, ignore=shutil.ignore_patterns("build", ".git", ".direnv", ".cache", "__pycache__"))
        shutil.copy2(REPO / "install.sh", cls.checkout / "install.sh")

    @classmethod
    def tearDownClass(cls):
        cls.export.cleanup()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="orangedots-install-", dir=TEMP)
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.config = self.base / "new home" / "xdg config"
        self.backup = self.base / "saved config"
        self.env = {**os.environ, "HOME": str(self.base / "new home"), "XDG_STATE_HOME": str(self.base / "state")}

    def install(self, *options, success=True):
        result = subprocess.run([
            "bash", str(self.checkout / "install.sh"),
            "--config-home", str(self.config), "--backup-dir", str(self.backup), *options,
        ], cwd=self.base, env=self.env, capture_output=True, text=True, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_fresh_shell_install_from_another_location(self):
        self.install()
        shell = self.config / "quickshell/caelestia"
        self.assertTrue(shell.is_symlink())
        self.assertEqual(shell.resolve(), self.checkout / "quickshell/caelestia")
        self.assertTrue((shell / "modules/desktop/DesktopWindow.qml").is_file())
        for name in ("shell.json", "shell-tokens.json", "cli.json"):
            self.assertEqual((self.config / "caelestia" / name).read_bytes(), (self.checkout / "caelestia" / name).read_bytes())
        self.assertFalse((self.config / "hypr").exists())
        self.assertFalse(self.backup.exists())

    def test_dry_run_creates_nothing(self):
        self.install("--full", "--dry-run")
        self.assertFalse(self.config.exists())
        self.assertFalse(self.backup.exists())
        self.assertFalse((self.base / "state").exists())

    def test_existing_preferences_and_private_calendar_stay_untouched(self):
        preferences = self.config / "caelestia"
        preferences.mkdir(parents=True)
        settings = preferences / "shell.json"
        settings.write_text('{"personal": "keep existing preferences"}\n')
        private = preferences / "calendar-url"
        private.write_text("https://example.invalid/private-test-feed\n")
        private.chmod(0o600)
        before = [(file, file.read_bytes(), file.stat().st_mtime_ns, file.stat().st_mode) for file in (settings, private)]
        self.install()
        for file, contents, modified, mode in before:
            self.assertEqual((file.read_bytes(), file.stat().st_mtime_ns, file.stat().st_mode), (contents, modified, mode))
        self.assertTrue((preferences / "cli.json").is_file())

    def test_full_install_backs_up_conflicts_and_is_idempotent(self):
        old_shell = self.config / "quickshell/caelestia"
        old_hypr = self.config / "hypr"
        old_shell.mkdir(parents=True)
        old_hypr.mkdir(parents=True)
        (old_shell / "mine.txt").write_text("old shell")
        (old_hypr / "mine.lua").write_text("old Hyprland")
        self.install("--full")
        self.assertEqual((self.backup / "quickshell/caelestia/mine.txt").read_text(), "old shell")
        self.assertEqual((self.backup / "hypr/mine.lua").read_text(), "old Hyprland")
        self.assertEqual(old_hypr.resolve(), self.checkout / "hypr")
        self.assertTrue((old_hypr / "scripts/toggle-spotify.sh").is_file())
        before = sorted(str(file.relative_to(self.backup)) for file in self.backup.rglob("*"))
        self.install("--full")
        self.assertEqual(before, sorted(str(file.relative_to(self.backup)) for file in self.backup.rglob("*")))

    def test_legacy_whole_quickshell_symlink_is_supported(self):
        self.config.mkdir(parents=True)
        (self.config / "quickshell").symlink_to(self.checkout / "quickshell", target_is_directory=True)
        self.install()
        self.assertEqual((self.config / "quickshell/caelestia").resolve(), self.checkout / "quickshell/caelestia")
        self.assertFalse(self.backup.exists())

    def test_broken_shell_link_is_backed_up(self):
        target = self.config / "quickshell/caelestia"
        target.parent.mkdir(parents=True)
        target.symlink_to("/nonexistent/orangedots-test-checkout")
        self.install()
        saved = self.backup / "quickshell/caelestia"
        self.assertTrue(saved.is_symlink())
        self.assertEqual(os.readlink(saved), "/nonexistent/orangedots-test-checkout")
        self.assertTrue((target / "shell.qml").is_file())

    def test_migrating_legacy_parent_link_preserves_old_checkout_and_other_configs(self):
        old_root = self.base / "older checkout" / "quickshell"
        (old_root / "caelestia").mkdir(parents=True)
        (old_root / "other-shell").mkdir()
        old_source = old_root / "caelestia/shell.qml"
        old_source.write_text("original source must not move")
        (old_root / "other-shell/shell.qml").write_text("another config")
        self.config.mkdir(parents=True)
        (self.config / "quickshell").symlink_to(old_root, target_is_directory=True)
        self.install()
        self.assertEqual(old_source.read_text(), "original source must not move")
        self.assertFalse((self.config / "quickshell").is_symlink())
        self.assertEqual((self.config / "quickshell/caelestia").resolve(), self.checkout / "quickshell/caelestia")
        other = self.config / "quickshell/other-shell"
        self.assertTrue(other.is_symlink())
        self.assertEqual(other.resolve(), old_root / "other-shell")
        self.assertEqual((other / "shell.qml").read_text(), "another config")
        self.assertTrue((self.backup / "quickshell").is_symlink())
        self.install()
        self.assertEqual(old_source.read_text(), "original source must not move")

    def test_invalid_parent_is_rejected_before_any_changes(self):
        self.config.mkdir(parents=True)
        blocked = self.config / "quickshell"
        blocked.write_text("not a directory")
        self.install("--full", success=False)
        self.assertEqual(blocked.read_text(), "not a directory")
        self.assertFalse((self.config / "hypr").exists())
        self.assertFalse((self.config / "caelestia").exists())
        self.assertFalse(self.backup.exists())

    def test_layout_checker_on_exported_checkout(self):
        subprocess.run(["python3", str(self.checkout / "scripts/check-layout.py")], check=True, cwd=self.base, env=self.env, timeout=30)

    @unittest.skipUnless(shutil.which("cmake") and shutil.which("c++"), "CMake and a C++ compiler are needed for a packaging check")
    def test_cmake_staged_install_contains_complete_renamed_shell(self):
        source = self.checkout / "quickshell/caelestia"
        build, stage = self.base / "build", self.base / "stage"
        configured = subprocess.run([
            "cmake", "-S", str(source), "-B", str(build),
            "-DENABLE_MODULES=shell", "-DVERSION=1.0.0", "-DGIT_REVISION=replication-test", "-DCMAKE_INSTALL_PREFIX=/usr",
        ], env=self.env, capture_output=True, text=True, timeout=60)
        self.assertEqual(configured.returncode, 0, configured.stdout + configured.stderr)
        installed = subprocess.run(["cmake", "--install", str(build)], env={**self.env, "DESTDIR": str(stage)}, capture_output=True, text=True, timeout=60)
        self.assertEqual(installed.returncode, 0, installed.stdout + installed.stderr)
        entries = list(stage.rglob("quickshell/caelestia/shell.qml"))
        self.assertEqual(len(entries), 1)
        staged = entries[0].parent
        subprocess.run(["python3", str(self.checkout / "scripts/check-layout.py"), "--shell-root", str(staged)], check=True, timeout=30)
        for directory in ("modules", "components", "services", "utils"):
            for file in (source / directory).rglob("*.qml"):
                self.assertEqual(file.read_bytes(), (staged / file.relative_to(source)).read_bytes())
        self.assertEqual((source / "LICENSE").read_bytes(), (staged / "LICENSE").read_bytes())
        self.assertIn("settings.watchFiles: false", (staged / "shell.qml").read_text())
        self.assertTrue(os.access(staged / "assets/wrap_term_launch.sh", os.X_OK))
        if os.environ.get("WAYLAND_DISPLAY") and shutil.which("qs"):
            # Run against the actual installed files, not the source checkout.
            subprocess.run(["python3", str(REPO / "quickshell/caelestia/tests/integration.py"), "--shell-root", str(staged), "--mode", "layout"], check=True, timeout=50)


if __name__ == "__main__":
    unittest.main()
