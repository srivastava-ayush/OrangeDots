pragma ComponentBehavior: Bound

import "lockscreen"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import qs.services

Scope {
    id: root

    required property LockScreen lock
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly property bool isCharging: !UPower.onBattery
    property var dimmedMonitors: []
    property var brightnessTransitions: []
    readonly property bool enabled: {
        if (Blackout.enabled)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return true;
    }

    function animateBrightness(monitor: var, target: real, entry: var): void {
        brightnessTransitions = brightnessTransitions.filter(t => t.monitor !== monitor);
        const from = monitor.brightness;
        if (Math.abs(from - target) < 0.01)
            return;
        brightnessTransitions = [...brightnessTransitions, {
            monitor,
            from,
            target,
            started: Date.now(),
            lastBrightness: from,
            entry
        }];
    }

    function advanceBrightness(): void {
        const now = Date.now();
        brightnessTransitions = brightnessTransitions.filter(t => {
            // Do not fight a brightness adjustment made by the user mid-animation.
            if (!t.monitor.isDdc && Math.abs(t.monitor.brightness - t.lastBrightness) > 0.015) {
                if (t.entry)
                    t.entry.manuallyAdjusted = true;
                return false;
            }

            const progress = Math.min(1, (now - t.started) / 2100);
            const value = Math.round((t.from + (t.target - t.from) * progress) * 100) / 100;
            t.monitor.setBrightness(value);
            t.lastBrightness = t.monitor.brightness;
            if (t.entry)
                t.entry.lastBrightness = t.lastBrightness;
            return progress < 1;
        });
    }

    function dimDisplays(level: real): void {
        if (dimmedMonitors.length)
            return;

        const saved = [];
        for (const monitor of Brightness.monitors) {
            if (isNaN(monitor.brightness) || monitor.brightness <= level)
                continue;
            const entry = { monitor, brightness: monitor.brightness, lastBrightness: monitor.brightness, manuallyAdjusted: false };
            saved.push(entry);
            animateBrightness(monitor, level, entry);
        }
        dimmedMonitors = saved;
    }

    function restoreDisplays(): void {
        for (const entry of dimmedMonitors) {
            // A manual brightness adjustment while dimmed takes precedence.
            if (!entry.manuallyAdjusted && Math.abs(entry.monitor.brightness - entry.lastBrightness) < 0.015)
                animateBrightness(entry.monitor, entry.brightness, null);
            else
                brightnessTransitions = brightnessTransitions.filter(t => t.monitor !== entry.monitor);
        }
        dimmedMonitors = [];
    }

    function handleIdleAction(action: var, stage: var): void {
        if (!action)
            return;

        if (action === "dim")
            dimDisplays(Math.max(0.01, Math.min(1, (stage.level ?? 30) / 100)));
        else if (action === "undim")
            restoreDisplays();
        else if (action === "lock")
            lock.requestLock(true);
        else if (action === "unlock")
            lock.lock.locked = false;
        else if (typeof action === "string")
            Hypr.dispatch(action);
        else if (!SessionManager.exec(action))
            Quickshell.execDetached(action);
    }

    Component.onDestruction: {
        // The timer cannot finish a transition after this scope is destroyed.
        for (const entry of dimmedMonitors) {
            if (!entry.manuallyAdjusted && Math.abs(entry.monitor.brightness - entry.lastBrightness) < 0.015)
                entry.monitor.setBrightness(entry.brightness);
        }
    }

    Timer {
        interval: 30
        repeat: true
        running: root.brightnessTransitions.length > 0
        onTriggered: root.advanceBrightness()
    }

    Connections {
        function onAboutToSleep(): void {
            if (GlobalConfig.general.idle.lockBeforeSleep)
                root.lock.requestLock(false);
        }

        function onLockRequested(): void {
            root.lock.requestLock(false);
        }

        function onUnlockRequested(): void {
            root.lock.lock.unlock();
        }

        target: SessionManager
    }

    Variants {
        model: {
            const timeouts = GlobalConfig.general.idle.timeouts;
            // Ignore legacy display-off entries from existing configs or older plugins.
            const active = timeouts.filter(t => t.idleAction !== "dpms off");
            return active.some(t => t.idleAction === "dim") ? active : [...active, {
                timeout: 120,
                idleAction: "dim",
                returnAction: "undim",
                level: 30
            }];
        }

        IdleMonitor {
            required property var modelData

            enabled: {
                if (!root.enabled || !(modelData.enabled ?? true))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                return true;
            }
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onEnabledChanged: {
                if (!enabled && modelData.idleAction === "dim")
                    root.restoreDisplays();
            }
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction, modelData)
        }
    }
}
