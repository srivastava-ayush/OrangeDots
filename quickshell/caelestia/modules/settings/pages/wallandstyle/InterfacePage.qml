pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("Interface")
    isSubPage: true

    function resetScales(): void {
        GlobalConfig.appearance.rounding.scale = 1;
        GlobalConfig.appearance.spacing.scale = 1;
        GlobalConfig.appearance.padding.scale = 1;
        GlobalConfig.appearance.font.scale = 1;
        GlobalConfig.appearance.anim.durations.scale = 1;
        GlobalConfig.appearance.deformScale = 1;
        GlobalConfig.border.rounding = 25;
        GlobalConfig.border.smoothing = 20;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Shape & spacing")
        }

        StepperRow {
            objectName: "interfaceRoundingScale"
            first: true
            label: qsTr("Corner rounding (%)")
            subtext: qsTr("Scales every rounded corner in the shell")
            value: Math.round(Config.appearance.rounding.scale * 100)
            from: 0
            to: 300
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.rounding.scale = v / 100
        }

        StepperRow {
            objectName: "interfaceSpacingScale"
            label: qsTr("Spacing (%)")
            subtext: qsTr("Scales gaps between shell elements")
            value: Math.round(Config.appearance.spacing.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.spacing.scale = v / 100
        }

        StepperRow {
            objectName: "interfacePaddingScale"
            label: qsTr("Padding (%)")
            subtext: qsTr("Scales inner padding across popouts and panels")
            value: Math.round(Config.appearance.padding.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.padding.scale = v / 100
        }

        StepperRow {
            objectName: "interfaceDeformScale"
            last: true
            label: qsTr("Deformation (%)")
            subtext: qsTr("Squish and stretch strength for interactive elements")
            value: Math.round(Config.appearance.deformScale * 100)
            from: 0
            to: 300
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.deformScale = v / 100
        }

        SectionHeader {
            text: qsTr("Borders")
        }

        StepperRow {
            objectName: "interfaceBorderRounding"
            first: true
            label: qsTr("Border rounding (px)")
            subtext: qsTr("Corner radius used by the Hyprland border")
            value: Config.border.rounding
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.border.rounding = Math.round(v)
        }

        StepperRow {
            objectName: "interfaceBorderSmoothing"
            last: true
            label: qsTr("Border smoothing")
            subtext: qsTr("Higher values soften the transition between windows and gaps")
            value: Config.border.smoothing
            from: 0
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.border.smoothing = Math.round(v)
        }

        SectionHeader {
            text: qsTr("Transparency")
        }

        ToggleRow {
            objectName: "interfaceTransparency"
            first: true
            text: qsTr("Enable transparency")
            subtext: qsTr("Use translucent shell surfaces")
            checked: Config.appearance.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        SliderRow {
            objectName: "interfaceTransparencyBase"
            icon: "opacity"
            label: qsTr("Base opacity")
            valueLabel: `${Math.round(value * 100)}%`
            value: Config.appearance.transparency.base
            enabled: Config.appearance.transparency.enabled
            onMoved: v => GlobalConfig.appearance.transparency.base = v
        }

        SliderRow {
            objectName: "interfaceTransparencyLayers"
            last: true
            icon: "layers"
            label: qsTr("Layer opacity")
            valueLabel: `${Math.round(value * 100)}%`
            value: Config.appearance.transparency.layers
            enabled: Config.appearance.transparency.enabled
            onMoved: v => GlobalConfig.appearance.transparency.layers = v
        }

        SectionHeader {
            text: qsTr("Text")
        }

        StepperRow {
            objectName: "interfaceFontScale"
            first: true
            label: qsTr("Font size (%)")
            subtext: qsTr("Scales all text in the shell")
            value: Math.round(Config.appearance.font.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.font.scale = v / 100
        }

        TextFieldRow {
            objectName: "interfaceClockFont"
            label: qsTr("Clock font")
            subtext: qsTr("Font family used by the taskbar and desktop clocks")
            placeholderText: "Rubik"
            maximumLength: 64
            value: GlobalConfig.appearance.font.clock
            validate: value => value.trim().length > 0
            onEditingFinished: value => GlobalConfig.appearance.font.clock = value.trim()
        }

        TextFieldRow {
            objectName: "interfaceWorkspaceFont"
            last: true
            label: qsTr("Workspace font")
            subtext: qsTr("Font family used for workspace indicators")
            placeholderText: "Rubik"
            maximumLength: 64
            value: GlobalConfig.appearance.font.workspaces
            validate: value => value.trim().length > 0
            onEditingFinished: value => GlobalConfig.appearance.font.workspaces = value.trim()
        }

        SectionHeader {
            text: qsTr("Animation")
        }

        StepperRow {
            objectName: "interfaceAnimationScale"
            first: true
            last: true
            label: qsTr("Animation duration (%)")
            subtext: qsTr("0 disables animations; higher values make them slower")
            value: Math.round(Config.appearance.anim.durations.scale * 100)
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.anim.durations.scale = v / 100
        }

        SectionHeader {
            text: qsTr("Reset")
        }

        RowButton {
            objectName: "interfaceReset"
            first: true
            last: true
            icon: "restart_alt"
            text: qsTr("Reset interface scales")
            subtext: qsTr("Restore rounding, spacing, padding, text, animation and border defaults")
            onClicked: root.resetScales()
        }
    }
}
