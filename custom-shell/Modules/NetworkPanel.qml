import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

ColumnLayout {
    id: root
    property color fgColor: "white"
    property color accent: "#0a84ff"
    spacing: 8

    readonly property var wifiDevice: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi) return d
        return null
    }
    readonly property var networks: {
        const dev = wifiDevice
        if (!dev) return []
        const arr = (dev.networks?.values ?? []).slice()
        arr.sort((a, b) => (b.signalStrength ?? 0) - (a.signalStrength ?? 0))
        return arr
    }
    readonly property var connectedNet: {
        for (const n of networks)
            if (n.connected) return n
        return null
    }

    // ---- header: title + switch ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Wi-Fi"
            color: root.fgColor
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Switch {
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = state
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#26ffffff"
    }

    // ---- network list ----
    Item {
        visible: Networking.wifiEnabled
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(listCol.height, 200)
        clip: true

        Column {
            id: listCol
            width: parent.width

            Repeater {
                model: root.networks

                Item {
                    required property var modelData
                    readonly property var net: modelData
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

                        // signal bars
                        Row {
                            spacing: 2
                            Repeater {
                                model: 4
                                Rectangle {
                                    readonly property int level: index
                                    width: 2.5
                                    height: 4 + level * 2.5
                                    radius: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    y: 15 - height
                                    color: root.fgColor
                                    opacity: level < Math.round((net.signalStrength ?? 0) * 4) ? 1 : 0.25
                                }
                            }
                        }

                        Text {
                            text: net.name
                            color: root.fgColor
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: net.security !== WifiSecurityType.Open ? "\uf023" : ""
                            color: root.fgColor
                            font.pixelSize: 10
                            opacity: 0.6
                        }

                        Text {
                            text: {
                                if (net.connected) return "Connected"
                                if (net.state === ConnectionState.Connecting) return "Connecting…"
                                return ""
                            }
                            color: net.connected
                                ? root.accent
                                : net.state === ConnectionState.Connecting ? root.fgColor : root.fgColor
                            font.pixelSize: 11
                            font.weight: net.connected ? Font.DemiBold : Font.Normal
                            opacity: net.connected ? 1 : 0.6
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hovered = true
                        onExited: hovered = false
                        onClicked: root.connectTo(net)
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    // ---- password prompt for unknown secured networks ----
    RowLayout {
        visible: root.pendingNet !== null
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 7
            color: "#1affffff"
            border.color: root.pendingNet ? root.accent : "transparent"
            border.width: root.pendingNet ? 1 : 0

            TextInput {
                id: pskField
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: Text.AlignVCenter
                color: root.fgColor
                echoMode: TextInput.Password
                font.pixelSize: 12
                selectByMouse: true
                onAccepted: root.joinNetwork()

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.height
                    Text {
                        anchors.centerIn: parent
                        text: "Show"
                        color: root.accent
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: pskField.echoMode = pskField.echoMode === TextInput.Password
                            ? TextInput.Normal : TextInput.Password
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 30
            radius: 7
            color: root.accent
            Text {
                anchors.centerIn: parent
                text: "Join"
                color: "white"
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.joinNetwork()
            }
        }
    }

    property var pendingNet: null

    onPendingNetChanged: {
        if (root.pendingNet !== null)
            pskField.forceActiveFocus()
    }

    function connectTo(net) {
        if (net.connected) return
        if (net.known || net.security === WifiSecurityType.Open) {
            net.connect()
        } else {
            root.pendingNet = net
        }
    }

    function joinNetwork() {
        const net = root.pendingNet
        if (!net || pskField.text === "") return
        net.connectWithPsk(pskField.text)
        root.pendingNet = null
        pskField.text = ""
    }
}