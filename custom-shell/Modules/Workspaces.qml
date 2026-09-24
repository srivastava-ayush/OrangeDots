import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {
    id: root
    property color fgColor: "white"
    property color accent: "#0a84ff"

    // ---- geometry: all dots uniform; the indicator slides between them ----
    readonly property real dotW: 6
    readonly property real dotH: 6
    readonly property real gap: 6
    readonly property real pitch: dotW + gap
    readonly property real pillW: 22
    readonly property real pillH: 7
    readonly property real overhang: (pillW - dotW) / 2

    // Non-special workspaces only, sorted ascending so the strip grows
    // rightwards consistently (no -98 / special: magic dots).
    readonly property var dots: {
        const arr = [];
        for (const w of Hyprland.workspaces.values) {
            if (w.id < 1) continue;
            arr.push({ id: w.id, active: w.active, occupied: ((w.lastIpcObject?.windows) ?? 0) > 0 });
        }
        arr.sort((a, b) => a.id - b.id);
        return arr;
    }

    readonly property int activeIndex: {
        const ds = dots;
        for (let i = 0; i < ds.length; i++)
            if (ds[i].active) return i;
        return 0;
    }

    implicitWidth: 2 * overhang + dots.length * dotW + Math.max(0, dots.length - 1) * gap
    implicitHeight: 20

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    // ---- uniform dots row (never changes size → nothing jumps) ----
    Row {
        id: dotRow
        anchors.left: parent.left
        anchors.leftMargin: root.overhang
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Repeater {
            model: root.dots

            Item {
                required property var modelData
                readonly property bool isActive: modelData.active
                readonly property bool isOccupied: modelData.occupied
                property bool hovered: false

                width: root.dotW
                height: root.dotH

                Rectangle {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -7
                    width: 18
                    height: 13
                    radius: 4
                    color: parent.hovered ? "#26ffffff" : "transparent"
                    visible: parent.hovered
                }

                Text {
                    id: num
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -7
                    text: parent.modelData.id
                    color: root.fgColor
                    font.pixelSize: 9
                    visible: parent.hovered
                }

                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    width: root.dotW
                    height: root.dotH
                    radius: width / 2
                    color: "white"
                    opacity: isActive ? 1.0 : isOccupied ? 0.72 : 0.32

                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    // ---- the accent pill that "liquids" between the dots ----
    Rectangle {
        id: pill
        x: root.activeIndex * root.pitch
        y: parent.height / 2 - height / 2
        width: root.pillW
        height: root.pillH
        radius: height / 2
        color: root.accent

        Behavior on x {
            NumberAnimation {
                duration: 340
                easing.type: Easing.InOutCubic
            }
        }

        // gentle pulse on arrival, like liquid settling into the dot
        SequentialAnimation {
            id: pulse
            running: false
            NumberAnimation { target: pill; property: "scale"; to: 1.18; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { target: pill; property: "scale"; to: 1.0; duration: 320; easing.type: Easing.OutElastic }
        }

        Connections {
            function onActiveIndexChanged() { pulse.restart() }
            target: root
        }
    }
}