import subprocess


def notify(*args: str) -> str:
    return subprocess.check_output(["notify-send", "-a", "orangeos", *args], text=True).strip()


def close_notification(id: str) -> None:
    subprocess.run(
        [
            "gdbus",
            "call",
            "--session",
            "--dest=org.freedesktop.Notifications",
            "--object-path=/org/freedesktop/Notifications",
            "--method=org.freedesktop.Notifications.CloseNotification",
            id,
        ],
        stdout=subprocess.DEVNULL,
    )
