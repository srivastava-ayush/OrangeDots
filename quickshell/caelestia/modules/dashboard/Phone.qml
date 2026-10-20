pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services

Item {
    id: root

    required property FileDialog filePicker

    implicitWidth: 860
    implicitHeight: 340

    Component.onCompleted: {
        KdeConnect.lastResult = "";
        KdeConnect.refCount++;
    }
    Component.onDestruction: KdeConnect.refCount--

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: layout.implicitHeight
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: layout

            width: parent.width
            spacing: Tokens.spacing.medium

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: deviceHeader.implicitHeight + Tokens.padding.large * 2
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge

                RowLayout {
                    id: deviceHeader

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: KdeConnect.connected ? "smartphone" : "phonelink_off"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: KdeConnect.selectedDevice?.name ?? qsTr("No paired phone")
                            font: Tokens.font.title.large
                            color: Colours.palette.m3onSurface
                        }
                        StyledText {
                            text: !KdeConnect.selectedDevice ? qsTr("Open KDE Connect to pair a phone") : KdeConnect.connected ? KdeConnect.battery >= 0 ? qsTr("Connected · %1% battery").arg(KdeConnect.battery) : qsTr("Connected") : qsTr("Offline · Check Wi-Fi and KDE Connect on your phone")
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                        StyledText {
                            visible: !!KdeConnect.lastResult
                            text: KdeConnect.lastResult
                            font: Tokens.font.body.small
                            color: Colours.palette.m3secondary
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        spacing: Tokens.spacing.extraSmall

                        IconTextButton {
                            icon: "refresh"
                            text: qsTr("Scan")
                            onClicked: {
                                Quickshell.execDetached(["kdeconnect-cli", "--refresh"]);
                                KdeConnect.refresh();
                            }
                        }
                        IconTextButton {
                            icon: "open_in_new"
                            text: qsTr("KDE Connect")
                            onClicked: Quickshell.execDetached(KdeConnect.selectedId ? ["kdeconnect-app", "--device", KdeConnect.selectedId] : ["kdeconnect-app"])
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: KdeConnect.devices.length > 1
                spacing: Tokens.spacing.small

                Repeater {
                    model: KdeConnect.devices

                    delegate: TextButton {
                        required property var modelData

                        text: modelData.name
                        checked: KdeConnect.selectedId === modelData.id
                        onClicked: KdeConnect.selectedId = modelData.id
                    }
                }
            }

            StyledText {
                text: qsTr("Quick actions")
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: Tokens.spacing.small
                rowSpacing: Tokens.spacing.small

                Repeater {
                    model: [
                        { icon: "notifications_active", label: qsTr("Ring phone"), args: ["--ring"], plugin: "kdeconnect_findmyphone" },
                        { icon: "vibration", label: qsTr("Ping"), args: ["--ping"], plugin: "kdeconnect_ping" },
                        { icon: "content_paste", label: qsTr("Send clipboard"), args: ["--send-clipboard"], plugin: "kdeconnect_clipboard" },
                        { icon: "lock", label: qsTr("Lock phone"), args: ["--lock"], plugin: "kdeconnect_lockdevice" },
                        { icon: "lock_open", label: qsTr("Unlock phone"), args: ["--unlock"], plugin: "kdeconnect_lockdevice" },
                        { icon: "folder_open", label: qsTr("Browse device"), browse: true, plugin: "kdeconnect_sftp" }
                    ]

                    delegate: IconTextButton {
                        required property var modelData

                        Layout.fillWidth: true
                        icon: modelData.icon
                        text: modelData.label
                        disabled: !KdeConnect.connected || (KdeConnect.plugins.length > 0 && !KdeConnect.plugins.includes(modelData.plugin))
                        onClicked: {
                            if (modelData.browse)
                                KdeConnect.browse();
                            else
                                KdeConnect.action(modelData.args);
                        }
                    }
                }

                IconTextButton {
                    Layout.fillWidth: true
                    icon: "upload_file"
                    text: qsTr("Send file")
                    disabled: !KdeConnect.connected
                    onClicked: filePicker.open()
                }

                IconTextButton {
                    Layout.fillWidth: true
                    icon: "sms"
                    text: qsTr("Messages")
                    disabled: !KdeConnect.selectedId
                    onClicked: Quickshell.execDetached(["kdeconnect-sms", "--device", KdeConnect.selectedId])
                }
            }


            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledTextField {
                    id: shareInput

                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    verticalPadding: Tokens.padding.small
                    placeholderText: qsTr("Paste a link or type a message")
                }

                IconTextButton {
                    icon: "send"
                    text: qsTr("Send")
                    disabled: !KdeConnect.connected || !shareInput.text
                    onClicked: {
                        KdeConnect.action(["--share-text", shareInput.text]);
                        shareInput.clear();
                    }
                }
            }

        }
    }
}
