import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var lock

    Center {
        anchors.centerIn: parent
        lock: root.lock
    }
}
