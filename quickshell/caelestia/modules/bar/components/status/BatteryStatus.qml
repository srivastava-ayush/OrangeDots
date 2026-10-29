import QtQuick
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property color colour
    readonly property bool horizontal: Taskbar.horizontal

    implicitWidth: icon.implicitWidth + (horizontal && percentage.visible ? percentage.implicitWidth + Tokens.spacing.extraSmall : 0)
    implicitHeight: horizontal ? Math.max(icon.implicitHeight, percentage.implicitHeight) : icon.implicitHeight + (percentage.visible ? percentage.implicitHeight : 0)

    MaterialIcon {
        id: icon
        anchors.top: root.horizontal ? undefined : parent.top
        anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
        anchors.left: root.horizontal ? parent.left : undefined
        anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined
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
        visible: UPower.displayDevice.isLaptopBattery
        anchors.top: root.horizontal ? undefined : icon.bottom
        anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
        anchors.left: root.horizontal ? icon.right : undefined
        anchors.leftMargin: root.horizontal ? Tokens.spacing.extraSmall : 0
        anchors.verticalCenter: root.horizontal ? parent.verticalCenter : undefined
        text: Math.round(UPower.displayDevice.percentage * 100)
        color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? colour : Colours.palette.m3error
        font: Tokens.font.mono.extraSmall
    }
}
