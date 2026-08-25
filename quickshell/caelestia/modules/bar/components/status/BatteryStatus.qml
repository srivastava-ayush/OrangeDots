import QtQuick
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    required property color colour

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight + (percentage.visible ? percentage.implicitHeight : 0)

    MaterialIcon {
        id: icon
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
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
        anchors.top: icon.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(UPower.displayDevice.percentage * 100) + "%"
        color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? colour : Colours.palette.m3error
        font: Tokens.font.mono.extraSmall
    }
}
