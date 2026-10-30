import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.services
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("Power & sleep")

    // Edit only the standard stages; retain any extra user-defined idle monitors.
    function stage(index: int): var {
        return GlobalConfig.general.idle.timeouts[index] ?? {};
    }

    function updateStage(index: int, changes: var): void {
        const timeouts = [...GlobalConfig.general.idle.timeouts];
        timeouts[index] = Object.assign({}, timeouts[index] ?? {}, changes);
        GlobalConfig.general.idle.timeouts = timeouts;
    }

    readonly property var defaultDimStage: ({ timeout: 120, idleAction: "dim", returnAction: "undim", level: 30 })
    readonly property var dimStage: GlobalConfig.general.idle.timeouts.find(t => t.idleAction === "dim") ?? defaultDimStage

    function updateDimStage(changes: var): void {
        const timeouts = [...GlobalConfig.general.idle.timeouts];
        const index = timeouts.findIndex(t => t.idleAction === "dim");
        const stage = Object.assign({}, index < 0 ? defaultDimStage : timeouts[index], changes);
        if (index < 0)
            timeouts.push(stage);
        else
            timeouts[index] = stage;
        GlobalConfig.general.idle.timeouts = timeouts;
    }

    readonly property list<MenuItem> sleepActions: [
        MenuItem { text: qsTr("Suspend, then hibernate") },
        MenuItem { text: qsTr("Suspend only") },
        MenuItem { text: qsTr("Hibernate immediately") }
    ]
    readonly property list<string> sleepCommands: ["suspendThenHibernate", "suspend", "hibernate"]
    readonly property string selectedSleepCommand: root.stage(1).idleAction?.[0] ?? "suspendThenHibernate"

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Idle timers")
        }

        ToggleRow {
            first: true
            text: qsTr("Dim display when idle")
            subtext: qsTr("Restore brightness when you return")
            checked: root.dimStage.enabled ?? true
            onToggled: root.updateDimStage({ enabled: checked })
        }

        StepperRow {
            label: qsTr("Dim after")
            subtext: qsTr("Minutes of inactivity (before locking)")
            value: (root.dimStage.timeout ?? 120) / 60
            from: 1
            to: 120
            stepSize: 1
            onMoved: v => root.updateDimStage({ timeout: Math.round(v * 60) })
        }

        StepperRow {
            label: qsTr("Dim brightness")
            subtext: qsTr("Maximum brightness while dimmed (%)")
            value: root.dimStage.level ?? 30
            from: 1
            to: 100
            stepSize: 5
            onMoved: v => root.updateDimStage({ level: Math.round(v) })
        }

        ToggleRow {
            text: qsTr("Lock when idle")
            subtext: qsTr("Lock the session after the selected time")
            checked: root.stage(0).enabled ?? true
            onToggled: root.updateStage(0, { enabled: checked })
        }

        StepperRow {
            label: qsTr("Lock after")
            subtext: qsTr("Minutes of inactivity")
            value: (root.stage(0).timeout ?? 180) / 60
            from: 1
            to: 120
            stepSize: 1
            onMoved: v => root.updateStage(0, { timeout: Math.round(v * 60) })
        }

        ToggleRow {
            text: qsTr("Sleep when idle")
            subtext: qsTr("Use the sleep action selected below")
            checked: root.stage(1).enabled ?? true
            onToggled: root.updateStage(1, { enabled: checked })
        }

        StepperRow {
            label: qsTr("Sleep after")
            subtext: qsTr("Minutes of inactivity")
            value: (root.stage(1).timeout ?? 600) / 60
            from: 1
            to: 240
            stepSize: 1
            onMoved: v => root.updateStage(1, { timeout: Math.round(v * 60) })
        }

        SelectRow {
            last: true
            label: qsTr("Sleep action")
            subtext: qsTr("Sent to systemd after the idle timer")
            menuItems: root.sleepActions
            active: root.sleepActions[Math.max(0, root.sleepCommands.indexOf(root.selectedSleepCommand))]
            onSelected: item => root.updateStage(1, { idleAction: [root.sleepCommands[root.sleepActions.indexOf(item)]] })
        }

        SectionHeader {
            text: qsTr("Conditions")
        }

        ToggleRow {
            first: true
            text: qsTr("Lock before sleeping")
            subtext: qsTr("Also lock when sleep is requested outside the idle timer")
            checked: GlobalConfig.general.idle.lockBeforeSleep
            onToggled: GlobalConfig.general.idle.lockBeforeSleep = checked
        }

        ToggleRow {
            text: qsTr("Keep awake while audio plays")
            subtext: qsTr("Pauses idle timers during playback")
            checked: GlobalConfig.general.idle.inhibitWhenAudio
            onToggled: GlobalConfig.general.idle.inhibitWhenAudio = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Keep awake while charging")
            subtext: qsTr("Pauses idle timers on external power")
            checked: GlobalConfig.general.idle.inhibitWhenCharging
            onToggled: GlobalConfig.general.idle.inhibitWhenCharging = checked
        }

        SectionHeader {
            text: qsTr("Battery")
        }

        StepperRow {
            first: true
            last: true
            label: qsTr("Critical battery hibernate")
            subtext: qsTr("Hibernate at this battery percentage")
            value: GlobalConfig.general.battery.criticalLevel
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.general.battery.criticalLevel = Math.round(v)
        }

        SectionHeader {
            // Snapshot of this machine's systemd configuration; these rows do not change it.
            text: qsTr("Systemd (read-only)")
        }

        InfoRow {
            first: true
            label: qsTr("Suspend-then-hibernate delay")
            subtext: qsTr("Configured in /etc/systemd/sleep.conf.d/hibernate.conf")
            value: qsTr("1 hour")
        }

        InfoRow {
            label: qsTr("Closing the lid")
            subtext: qsTr("Handled by logind, not the idle timer")
            value: qsTr("Suspend, then hibernate")
        }

        InfoRow {
            last: true
            label: qsTr("Power button")
            subtext: qsTr("Handled by logind; systemd settings are read-only here")
            value: qsTr("Hibernate")
        }
    }
}
