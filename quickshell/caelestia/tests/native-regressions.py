"""Run disposable native regression fixtures against a selected Release build."""
import argparse
from pathlib import Path
import shlex
import subprocess
import tempfile

SHELL = Path(__file__).resolve().parents[1]
CASES = {"copyfile": ("Caelestia", "caelestia-core")}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", type=Path, required=True)
    parser.add_argument("--case", choices=CASES, action="append")
    args = parser.parse_args()
    flags = shlex.split(subprocess.check_output(
        ["pkg-config", "--cflags", "--libs", "Qt6Core", "Qt6Qml", "Qt6Quick", "Qt6Sql"], text=True,
    ))
    with tempfile.TemporaryDirectory(prefix="native-regressions-", dir="/tmp/opencode" if Path("/tmp/opencode").is_dir() else None) as temporary:
        for case in args.case or CASES:
            directory, library = CASES[case]
            libdir = args.build_dir.resolve() / "plugin/src" / directory
            executable = Path(temporary) / case
            subprocess.run([
                "c++", "-fPIC", "-std=c++20", "-I" + str(SHELL / "plugin/src/Caelestia"),
                str(SHELL / "tests/native" / f"{case}.cpp"), "-o", str(executable),
                "-L" + str(libdir), "-Wl,-rpath," + str(libdir), "-l" + library, *flags,
            ], check=True)
            subprocess.run([str(executable)], check=True, timeout=30)
            print(f"PASS: native {case}", flush=True)


if __name__ == "__main__":
    main()
