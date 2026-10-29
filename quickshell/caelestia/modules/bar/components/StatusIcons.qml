pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.components.status

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    required property var bar
    readonly property alias items: iconColumn

    readonly property int spacing: Tokens.spacing.medium / 2
    readonly property bool horizontal: Taskbar.horizontal

    // Index of the first/last entry that isn't collapsed, for edge margin gating
    readonly property int firstPresent: {
        const values = model.values;
        for (let i = 0; i < values.length; i++)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }
    readonly property int lastPresent: {
        const values = model.values;
        for (let i = values.length - 1; i >= 0; i--)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }

    // Entries that can shrink to nothing, spacing included
    function collapsed(entry: var): bool {
        if (entry.id === "lockStatus")
            return !Hypr.capsLock && !Hypr.numLock;
        return false;
    }

    function notificationIcon(): Item {
        return iconColumn.children.find(child => child.name === "notifications")?.item ?? null;
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: horizontal ? iconColumn.implicitWidth + Tokens.padding.medium * 2 : Tokens.sizes.bar.innerWidth
    implicitHeight: horizontal ? Tokens.sizes.bar.innerWidth : iconColumn.implicitHeight + Tokens.padding.medium * 2

    GridLayout {
        id: iconColumn

        anchors.centerIn: parent
        width: root.horizontal ? implicitWidth : parent.width
        columns: root.horizontal ? model.values.length : 1
        rows: root.horizontal ? 1 : model.values.length

        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: ScriptModel {
                id: model

                values: {
                    const configured = root.Config.bar.statusIcons.values;
                    const entries = configured.filter(e => e.enabled && (e.id !== "notifications" || root.Config.notifs.shadeEnabled));
                    // Keep the bell inside the shared status pill, including for
                    // existing configurations that predate the notification icon.
                    if (root.Config.notifs.shadeEnabled && !configured.some(e => e.id === "notifications"))
                        entries.unshift({ id: "notifications", enabled: true });
                    return entries;
                }
            }

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "notifications"
                    delegate: EntryWrapper {
                        NotificationIcon {
                            objectName: "taskbarNotifications"
                            bar: root.bar
                            colour: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "lockStatus"
                    delegate: EntryWrapper {
                        LockStatus {
                            colour: root.colour
                            parentSpacing: root.spacing
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audio"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2

                        MaterialIcon {
                            animate: true
                            text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "microphone"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2
                        name: "audio" // Mic opens audio popout

                        MaterialIcon {
                            animate: true
                            text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: EntryWrapper {
                        StyledText {
                            animate: true
                            text: Hypr.kbLayout
                            color: root.colour
                            font: Tokens.font.mono.medium
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "network"
                    delegate: EntryWrapper {
                        MaterialIcon {
                            animate: true
                            text: Nmcli.activeEthernet ? "cable" : Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                            color: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: EntryWrapper {
                        BluetoothStatus {
                            colour: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "battery"
                    delegate: EntryWrapper {
                        BatteryStatus {
                            colour: root.colour
                        }
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        property int margin: root.spacing / 2
        readonly property bool present: !root.collapsed(modelData)
        property real topGap: present && index !== root.firstPresent ? margin : 0
        property real bottomGap: present && index !== root.lastPresent ? margin : 0
        default property Item item
        property string name: modelData.id.toLowerCase()

        Layout.topMargin: root.horizontal ? 0 : Math.round(topGap)
        Layout.bottomMargin: root.horizontal ? 0 : Math.round(bottomGap)
        Layout.leftMargin: root.horizontal ? Math.round(topGap) : 0
        Layout.rightMargin: root.horizontal ? Math.round(bottomGap) : 0
        Layout.alignment: Qt.AlignCenter

        implicitWidth: root.horizontal && !present ? 0 : (item?.implicitWidth ?? 0)
        implicitHeight: item?.implicitHeight ?? 0

        children: item

        Behavior on topGap {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Behavior on bottomGap {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
