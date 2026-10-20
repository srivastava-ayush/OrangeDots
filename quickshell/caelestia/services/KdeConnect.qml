pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var devices: []
    property var reachableIds: []
    property var plugins: []
    property string selectedId: ""
    property int battery: -1
    property int refCount
    property string lastResult: ""
    property string actionError: ""

    readonly property var selectedDevice: devices.find(device => device.id === selectedId) ?? null
    readonly property bool connected: reachableIds.includes(selectedId)

    function refresh(): void {
        if (!devicesProc.running)
            devicesProc.running = true;
        if (!reachableProc.running)
            reachableProc.running = true;
        if (selectedId && connected && !batteryProc.running)
            batteryProc.running = true;
        if (selectedId && connected && !pluginsProc.running)
            pluginsProc.running = true;
    }

    function action(args: var): void {
        if (!selectedId || actionProc.running)
            return;

        lastResult = qsTr("Sending %1...").arg(args[0].replace(/^--/, ""));
        actionError = "";
        actionProc.command = ["kdeconnect-cli", "--device", selectedId, ...args];
        actionProc.running = true;
    }

    function browse(): void {
        if (!selectedId || browseProc.running)
            return;

        lastResult = qsTr("Opening phone files...");
        browseProc.command = ["gdbus", "call", "--session", "--dest", "org.kde.kdeconnect", "--object-path", `/modules/kdeconnect/devices/${selectedId}/sftp`, "--method", "org.kde.kdeconnect.device.sftp.getDirectories"];
        browseProc.running = true;
    }

    onSelectedIdChanged: {
        battery = -1;
        plugins = [];
        if (connected && !batteryProc.running)
            batteryProc.running = true;
        if (connected && !pluginsProc.running)
            pluginsProc.running = true;
    }

    Timer {
        interval: 5000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        function status(): string {
            return JSON.stringify({ devices: root.devices, selectedId: root.selectedId, reachableIds: root.reachableIds, plugins: root.plugins, battery: root.battery, refCount: root.refCount, lastResult: root.lastResult, browseRunning: browseProc.running });
        }

        function refresh(): void {
            root.refresh();
        }

        function ping(): void {
            root.action(["--ping"]);
        }

        function browse(): void {
            root.browse();
        }

        target: "kdeconnect"
    }

    Process {
        id: browseProc

        onExited: code => { // qmllint disable signal-handler-parameters
            if (code !== 0)
                root.lastResult = qsTr("Could not browse phone files");
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const directory = text.match(/'([^']+)'\s*:\s*<'[^']*'>/);
                if (directory) {
                    Quickshell.execDetached(["thunar", directory[1]]);
                    root.lastResult = qsTr("Opened phone files in Thunar");
                } else {
                    root.lastResult = qsTr("No phone folders are shared");
                }
            }
        }
    }

    Process {
        id: actionProc

        onExited: code => { // qmllint disable signal-handler-parameters
            root.lastResult = code === 0 ? qsTr("Action sent to %1").arg(root.selectedDevice?.name ?? qsTr("phone")) : root.actionError || qsTr("KDE Connect command failed (%1)").arg(code);
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.actionError = text.trim();
                if (root.actionError)
                    root.lastResult = root.actionError;
            }
        }
    }

    Process {
        id: devicesProc

        command: ["kdeconnect-cli", "--list-devices", "--id-name-only"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.devices = text.trim().split("\n").map(line => {
                    const match = line.match(/^([a-zA-Z0-9_-]{16,})\s+(.+)$/);
                    return match ? { id: match[1], name: match[2] } : null;
                }).filter(Boolean);
                if (!root.devices.some(device => device.id === root.selectedId))
                    root.selectedId = root.devices[0]?.id ?? "";
            }
        }
    }

    Process {
        id: reachableProc

        command: ["kdeconnect-cli", "--list-available", "--id-only"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.reachableIds = text.trim().split("\n").filter(line => /^[a-zA-Z0-9_-]{16,}$/.test(line));
                if (!root.connected)
                    root.battery = -1;
                else {
                    if (!batteryProc.running)
                        batteryProc.running = true;
                    if (!pluginsProc.running)
                        pluginsProc.running = true;
                }
            }
        }
    }

    Process {
        id: pluginsProc

        command: ["gdbus", "call", "--session", "--dest", "org.kde.kdeconnect", "--object-path", `/modules/kdeconnect/devices/${root.selectedId}`, "--method", "org.kde.kdeconnect.device.loadedPlugins"]
        stdout: StdioCollector {
            onStreamFinished: root.plugins = text.match(/kdeconnect_[a-z0-9_]+/g) ?? []
        }
    }

    Process {
        id: batteryProc

        command: ["gdbus", "call", "--session", "--dest", "org.kde.kdeconnect", "--object-path", `/modules/kdeconnect/devices/${root.selectedId}/battery`, "--method", "org.freedesktop.DBus.Properties.Get", "org.kde.kdeconnect.device.battery", "charge"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/<(\d{1,3})>/);
                root.battery = match ? Number(match[1]) : -1;
            }
        }
    }
}
