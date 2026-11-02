pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services

Item {
    id: root
    objectName: "dashboardPhone"

    required property FileDialog filePicker
    property var phone: KdeConnect
    readonly property var actions: [
        { id: "ring", icon: "notifications_active", label: qsTr("Ring phone"), args: ["--ring"], plugin: "kdeconnect_findmyphone" },
        { id: "ping", icon: "vibration", label: qsTr("Ping"), args: ["--ping"], plugin: "kdeconnect_ping" },
        { id: "clipboard", icon: "content_paste", label: qsTr("Clipboard"), args: ["--send-clipboard"], plugin: "kdeconnect_clipboard" },
        { id: "file", icon: "upload_file", label: qsTr("Send file") },
        { id: "lock", icon: "lock", label: qsTr("Lock phone"), args: ["--lock"], plugin: "kdeconnect_lockdevice" },
        { id: "unlock", icon: "lock_open", label: qsTr("Unlock phone"), args: ["--unlock"], plugin: "kdeconnect_lockdevice" },
        { id: "browse", icon: "folder_open", label: qsTr("Browse files"), plugin: "kdeconnect_sftp" },
        { id: "messages", icon: "sms", label: qsTr("Messages") }
    ]

    implicitWidth: 920
    implicitHeight: 360

    Component.onCompleted: {
        KdeConnect.lastResult = "";
        KdeConnect.refCount++;
    }
    Component.onDestruction: KdeConnect.refCount--

    function actionEnabled(action: var): bool {
        if (action.id === "messages")
            return !!phone.selectedId;
        return phone.connected && (!action.plugin || phone.plugins.length === 0 || phone.plugins.includes(action.plugin));
    }

    function activateAction(action: var): void {
        if (!actionEnabled(action))
            return;
        if (action.id === "file")
            filePicker.open();
        else if (action.id === "messages")
            Quickshell.execDetached(["kdeconnect-sms", "--device", phone.selectedId]);
        else if (action.id === "browse")
            phone.browse();
        else
            phone.action(action.args);
    }

    function shareText(): void {
        if (!phone.connected || !shareInput.text.trim())
            return;
        phone.action(["--share-text", shareInput.text]);
        shareInput.clear();
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, body.implicitHeight)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        RowLayout {
            id: body
            width: parent.width
            height: Math.max(root.height, implicitHeight)
            spacing: Tokens.spacing.medium

            StyledRect {
                objectName: "phoneDeviceCard"
                Layout.preferredWidth: 252
                Layout.minimumWidth: 252
                Layout.fillHeight: true
                implicitHeight: deviceLayout.implicitHeight + Tokens.padding.large * 2
                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: deviceLayout
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledRect {
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: root.phone.connected ? Colours.palette.m3primary : Colours.palette.m3outline
                        }

                        StyledText {
                            objectName: "phoneConnectionStatus"
                            Layout.fillWidth: true
                            text: !root.phone.selectedDevice ? qsTr("Not paired") : root.phone.connected ? qsTr("Connected") : qsTr("Offline")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        IconButton {
                            icon: "refresh"
                            type: IconButton.Text
                            onClicked: {
                                Quickshell.execDetached(["kdeconnect-cli", "--refresh"]);
                                root.phone.refresh();
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitHeight: 112

                        StyledRect {
                            anchors.centerIn: parent
                            width: 68
                            height: 108
                            radius: 18
                            color: Colours.tPalette.m3surfaceContainerHigh
                            border.width: 2
                            border.color: Qt.alpha(Colours.palette.m3primary, root.phone.connected ? 0.5 : 0.18)

                            StyledRect {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: 7
                                width: 22
                                height: 4
                                radius: 2
                                color: Colours.palette.m3outlineVariant
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Tokens.spacing.extraSmall

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.phone.connected ? "phonelink" : "phonelink_off"
                                    fontStyle: Tokens.font.icon.large
                                    color: root.phone.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.phone.connected && root.phone.battery >= 0 ? `${root.phone.battery}%` : "—"
                                    font: Tokens.font.label.medium
                                    color: Colours.palette.m3onSurfaceVariant
                                }
                            }
                        }
                    }

                    StyledText {
                        objectName: "phoneDeviceName"
                        Layout.fillWidth: true
                        text: root.phone.selectedDevice?.name || qsTr("Your phone")
                        font: Tokens.font.title.medium
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: !root.phone.selectedDevice ? qsTr("Pair a device to get started") : root.phone.connected ? qsTr("Ready to share") : qsTr("Connect both devices to Wi-Fi")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    SplitButton {
                        objectName: "phoneDeviceSelector"
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.phone.devices.length > 1
                        type: SplitButton.Tonal
                        active: menuItems.find(item => item.deviceId === root.phone.selectedId) ?? menuItems[0] ?? null
                        menuItems: deviceItems.instances
                        menu.onItemSelected: item => root.phone.selectedId = item.deviceId
                        minLeftWidth: 140
                        label.Layout.maximumWidth: 110
                        label.elide: Text.ElideRight

                        Variants {
                            id: deviceItems
                            model: root.phone.devices

                            MenuItem {
                                required property var modelData
                                readonly property string deviceId: modelData.id
                                text: modelData.name
                                icon: "smartphone"
                            }
                        }
                    }

                    IconTextButton {
                        Layout.alignment: Qt.AlignHCenter
                        icon: root.phone.selectedDevice ? "settings" : "add_link"
                        text: root.phone.selectedDevice ? qsTr("Manage device") : qsTr("Pair a phone")
                        type: IconTextButton.Text
                        onClicked: Quickshell.execDetached(root.phone.selectedId ? ["kdeconnect-app", "--device", root.phone.selectedId] : ["kdeconnect-app"])
                    }
                }
            }

            StyledRect {
                objectName: "phoneActionsCard"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.fillHeight: true
                implicitHeight: controls.implicitHeight + Tokens.padding.large * 2
                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: controls
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: qsTr("Quick actions")
                        font: Tokens.font.title.small
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: Tokens.spacing.small
                        rowSpacing: Tokens.spacing.small

                        Repeater {
                            model: root.actions

                            ActionTile {
                                required property var modelData
                                objectName: `phoneAction_${modelData.id}`
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                icon: modelData.icon
                                text: modelData.label
                                disabled: !root.actionEnabled(modelData)
                                onClicked: root.activateAction(modelData)
                            }
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledTextField {
                            id: shareInput
                            objectName: "phoneShareInput"
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredHeight: 48
                            verticalPadding: Tokens.padding.small
                            placeholderText: qsTr("Send a link or message")
                            onAccepted: root.shareText()
                        }

                        IconButton {
                            objectName: "phoneShareSend"
                            icon: "send"
                            type: IconButton.Filled
                            disabled: !root.phone.connected || !shareInput.text.trim()
                            onClicked: root.shareText()
                        }
                    }

                    StyledText {
                        objectName: "phoneActionResult"
                        Layout.fillWidth: true
                        visible: !!root.phone.lastResult
                        text: root.phone.lastResult
                        font: Tokens.font.label.small
                        color: root.phone.actionError ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }

    component ActionTile: ButtonBase {
        id: tile
        required property string icon
        required property string text
        implicitWidth: 120
        implicitHeight: 76
        type: ButtonBase.Tonal
        defaultRadius: Tokens.rounding.large
        inactiveColour: Colours.tPalette.m3surfaceContainerHigh
        inactiveOnColour: Colours.palette.m3onSurface
        activeColour: Colours.palette.m3secondaryContainer
        activeOnColour: Colours.palette.m3onSecondaryContainer

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Tokens.padding.small * 2
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: tile.icon
                fontStyle: Tokens.font.icon.medium
                color: tile.disabled ? tile.disabledOnColour : Colours.palette.m3primary
            }

            StyledText {
                Layout.fillWidth: true
                text: tile.text
                font: Tokens.font.label.medium
                color: tile.onColour
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }
}
