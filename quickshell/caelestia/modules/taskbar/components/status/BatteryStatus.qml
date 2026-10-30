import QtQuick
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root
    objectName: "taskbarBatteryStatus"

    required property color colour
    readonly property bool horizontal: Taskbar.horizontal

    implicitWidth: Math.ceil(horizontal ? icon.implicitWidth + (percentage.visible ? percentage.implicitWidth + Tokens.spacing.extraSmall : 0) : Math.max(icon.implicitWidth, percentage.visible ? percentage.implicitWidth : 0))
    implicitHeight: horizontal ? Math.max(icon.implicitHeight, percentage.implicitHeight) : icon.implicitHeight + (percentage.visible ? percentage.implicitHeight : 0)

    MaterialIcon {
        id: icon
        objectName: "taskbarBatteryGlyph"
        // Explicit coordinates avoid conflicting old/new anchors during a live
        // orientation switch (a fresh shell never encounters that transition).
        x: root.horizontal ? 0 : (root.width - width) / 2
        y: root.horizontal ? (root.height - height) / 2 : 0
        animate: true
        text: {
            if (!UPower.displayDevice.isLaptopBattery) {
                if (PowerProfiles.profile === PowerProfile.PowerSaver)
                    return "energy_savings_leaf";
                if (PowerProfiles.profile === PowerProfile.Performance)
                    return "rocket_launch";
                return "balance";
            }
            return Icons.getBatteryIcon(UPower.displayDevice.percentage, [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state));
        }
        color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? colour : Colours.palette.m3error
        fill: 1
    }
    Text {
        id: percentage
        objectName: "taskbarBatteryPercentage"
        visible: UPower.displayDevice.isLaptopBattery
        x: root.horizontal ? icon.width + Tokens.spacing.extraSmall : (root.width - width) / 2
        y: root.horizontal ? (root.height - height) / 2 : icon.height
        text: Math.round(UPower.displayDevice.percentage * 100)
        color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? colour : Colours.palette.m3error
        font: Qt.font({ family: Tokens.font.mono.small.family, pointSize: Tokens.font.label.small.pointSize * (root.horizontal ? 1 : 0.8) })
    }
}
