import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var lock

    Center {
        Layout.alignment: Qt.AlignHCenter
        lock: root.lock
    }
}
