import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

ColumnLayout {
    id: root
    property color fgColor: "white"
    property color accent: "#0a84ff"
    spacing: 8

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: {
        const a = adapter
        if (!a) return []
        const arr = (a.devices?.values ?? []).slice()
        // connected first, then paired, then the rest (newly discovered)
        arr.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return 0
        })
        return arr
    }

    // ---- header: title + switch ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Bluetooth"
            color: root.fgColor
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Switch {
            checked: adapter ? adapter.enabled : false
            onToggled: {
                if (adapter) adapter.enabled = state
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#26ffffff"
    }

    // ---- discover row ----
    RowLayout {
        visible: adapter !== null && adapter.enabled
        Layout.fillWidth: true
        Layout.preferredHeight: 26
        spacing: 8

        Text {
            text: "Discover devices"
            color: root.fgColor
            font.pixelSize: 12
            opacity: 0.75
            Layout.fillWidth: true
        }
        Text {
            visible: adapter !== null && adapter.discovering
            text: "Scanning…"
            color: root.accent
            font.pixelSize: 11
        }
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 13
            color: adapter && adapter.discovering ? root.accent : "#1affffff"
            Text {
                anchors.centerIn: parent
                text: adapter && adapter.discovering ? "…" : "\uf293"
                color: root.fgColor
                font.pixelSize: 13
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (adapter) adapter.discovering = !adapter.discovering
                }
            }
        }
    }

    // ---- device list ----
    Item {
        visible: adapter !== null && adapter.enabled
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(listCol.height, 200)
        clip: true

        Column {
            id: listCol
            width: parent.width

            Repeater {
                model: root.devices

                Item {
                    required property var modelData
                    readonly property var dev: modelData
                    property bool hovered: false

                    width: parent.width
                    height: 30

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: hovered ? "#1affffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: root.iconFor(dev.icon, dev.name)
                            color: root.fgColor
                            font.pixelSize: 13
                        }

                        Text {
                            text: dev.name !== "" ? dev.name : dev.address
                            color: root.fgColor
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            opacity: dev.connected || dev.paired ? 1 : 0.7
                            Layout.fillWidth: true
                        }

                        Text {
                            text: {
                                if (dev.connected) return "Connected"
                                if (dev.pairing) return "Pairing…"
                                if (dev.paired) return "Not Connected"
                                return ""
                            }
                            color: dev.connected ? root.accent : root.fgColor
                            font.pixelSize: 11
                            font.weight: dev.connected ? Font.DemiBold : Font.Normal
                            opacity: dev.connected ? 1 : 0.6
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hovered = true
                        onExited: hovered = false
                        onClicked: root.toggleDevice(dev)
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    Text {
        visible: adapter !== null && !adapter.enabled
        Layout.fillWidth: true
        text: "Turn on Bluetooth to view devices"
        color: root.fgColor
        font.pixelSize: 11
        opacity: 0.6
    }

    Text {
        visible: adapter === null
        Layout.fillWidth: true
        text: "No Bluetooth adapter found"
        color: root.fgColor
        font.pixelSize: 11
        opacity: 0.6
    }

    function iconFor(icon, name) {
        const map = {
            "audio-headphones": "\uf025",
            "audio-card": "\uf025",
            "audio-speakers": "\uf028",
            "computer": "\uf109",
            "phone": "\uf10b",
            "input-gaming": "\uf11b",
            "input-keyboard": "\uf11c",
            "input-mouse": "\uf245",
            "video-display": "\uf26c",
            "camera-photo": "\uf030",
            "network-wireless": "\uf1eb",
        }
        return map[icon] ?? "\uf293"
    }

    function toggleDevice(dev) {
        if (dev.connected) dev.disconnect()
        else if (dev.paired) dev.connect()
        else dev.pair()
    }
}