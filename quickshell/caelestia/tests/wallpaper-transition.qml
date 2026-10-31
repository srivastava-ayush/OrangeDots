pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.modules.background as Background

// Exercise only disposable images on an invisible, input-free background window.
ShellRoot {
    id: root
    settings.watchFiles: false
    property int step: 0
    property int ticks: 0

    function check(condition: bool, message: string): void {
        if (!condition)
            throw new Error(message);
    }

    PanelWindow {
        id: window
        color: "transparent"
        implicitWidth: 320
        implicitHeight: 180
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        contentItem.Config.screen: screen.name
        contentItem.Tokens.screen: screen.name

        Background.Wallpaper {
            id: wallpaper
            anchors.fill: parent
            opacity: 0
            source: Quickshell.env("WALLPAPER_TEST_FIRST")
        }
    }

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            try {
                root.check(root.ticks++ < 240, `Wallpaper transition timed out at step ${root.step}`);
                const images = wallpaper.children.filter(child => child.objectName === "wallpaperImage");
                switch (root.step) {
                case 0:
                    GlobalConfig.appearance.anim.durations.scale = 1;
                    if (wallpaper.current?.status !== Image.Ready || wallpaper.current.opacity < 1 || wallpaper.transitionDuration <= 0)
                        return;
                    wallpaper.source = Quickshell.env("WALLPAPER_TEST_SECOND");
                    root.step++;
                    break;
                case 1:
                    if (wallpaper.current?.status !== Image.Ready)
                        return;
                    root.check(images.length >= 2, "Old wallpaper must remain while the replacement fades in");
                    root.check(wallpaper.current.opacity < 1 && wallpaper.current.scale > 1, "Wallpaper switch must animate both crossfade and gentle zoom");
                    root.step++;
                    break;
                case 2:
                    if (wallpaper.current.opacity < 1 || images.length !== 1)
                        return;
                    root.check(wallpaper.current.scale === 1, "Wallpaper zoom must finish at the exact screen size");
                    wallpaper.source = Quickshell.env("WALLPAPER_TEST_FIRST");
                    wallpaper.source = Quickshell.env("WALLPAPER_TEST_THIRD");
                    root.step++;
                    break;
                case 3:
                    if (wallpaper.current?.status !== Image.Ready || wallpaper.current.opacity < 1 || images.length !== 1)
                        return;
                    root.check(wallpaper.current.path === Quickshell.env("WALLPAPER_TEST_THIRD"), "Rapid wallpaper changes must settle on the latest selection and release old images");
                    GlobalConfig.appearance.anim.durations.scale = 0;
                    root.step++;
                    break;
                case 4:
                    if (wallpaper.transitionDuration > 0)
                        return;
                    wallpaper.source = Quickshell.env("WALLPAPER_TEST_SECOND");
                    root.step++;
                    break;
                case 5:
                    if (wallpaper.current?.status !== Image.Ready || images.length !== 1)
                        return;
                    root.check(wallpaper.current.opacity === 1 && wallpaper.current.scale === 1, "Disabled animations must display the new image immediately at its final size");
                    console.log("TASKBAR TEST PASS");
                    Qt.quit();
                    break;
                }
            } catch (error) {
                console.error("TASKBAR TEST FAIL:", error.message);
                Qt.quit();
            }
        }
    }
}
