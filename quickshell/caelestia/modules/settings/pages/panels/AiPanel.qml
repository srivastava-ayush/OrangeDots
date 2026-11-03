pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.settings.common
import qs.services

PageBase {
    id: root
    title: qsTr("AI panel")
    isSubPage: true
    readonly property var effortValues: AiConfig.effortOptions(AiConfig.provider)
    readonly property list<MenuItem> efforts: [
        MenuItem { text: qsTr("Provider default") },
        MenuItem { text: root.effortValues[1] || "" },
        MenuItem { text: root.effortValues[2] || "" },
        MenuItem { text: root.effortValues[3] || "" },
        MenuItem { text: root.effortValues[4] || "" },
        MenuItem { text: root.effortValues[5] || "" },
        MenuItem { text: root.effortValues[6] || "" }
    ]
    readonly property list<MenuItem> providers: [
        MenuItem { text: "OpenCode" },
        MenuItem { text: "Codex" },
        MenuItem { text: "Claude Code" },
        MenuItem { text: "Ollama (local)" }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2
        SectionHeader { first: true; text: qsTr("Panel") }
        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Super+I or drag inward from the right edge")
            checked: AiConfig.enabled
            onToggled: AiConfig.enabled = checked
        }
        StepperRow {
            label: qsTr("Panel width")
            value: AiConfig.panelWidth
            from: 360; to: 720; stepSize: 20
            onMoved: value => AiConfig.panelWidth = value
        }
        ToggleRow {
            objectName: "aiFullHeightSetting"
            text: qsTr("Full-height sidebar")
            subtext: qsTr("Attach to both top and bottom shell edges · turn off to use a custom height")
            checked: AiConfig.fullHeight
            onToggled: AiConfig.fullHeight = checked
        }
        StepperRow {
            objectName: "aiPanelHeightSetting"
            visible: !AiConfig.fullHeight
            last: true
            label: qsTr("Panel height")
            value: AiConfig.panelHeight
            from: 480; to: 1600; stepSize: 20
            onMoved: value => AiConfig.panelHeight = value
        }
        SectionHeader { text: qsTr("Provider") }
        SelectRow {
            objectName: "aiProviderSetting"
            first: true
            label: qsTr("Chat backend")
            subtext: qsTr("Each provider keeps its own conversation; switches wait for an active reply to finish")
            menuItems: root.providers
            active: root.providers[AiConfig.providers.indexOf(AiConfig.provider)]
            onSelected: item => AiConfig.provider = AiConfig.providers[root.providers.indexOf(item)]
        }
        TextFieldRow {
            label: qsTr("Default working directory")
            subtext: qsTr("Absolute path used for new chats · start a New chat to apply changes; existing sessions keep their directory")
            value: AiConfig.directory
            placeholderText: "/home/you"
            onEditingFinished: value => { if (value.startsWith("/")) AiConfig.directory = value; }
        }
        TextFieldRow {
            visible: AiConfig.provider === "opencode"
            label: qsTr("OpenCode model")
            subtext: qsTr("Optional provider/model#variant · blank uses your OpenCode default · applies to new chats")
            value: AiConfig.opencodeModel
            onEditingFinished: value => AiConfig.opencodeModel = value.trim()
        }
        TextFieldRow {
            visible: AiConfig.provider === "codex"
            label: qsTr("Codex model")
            subtext: qsTr("Blank uses your Codex default · requires the signed-in codex CLI")
            value: AiConfig.codexModel
            onEditingFinished: value => AiConfig.codexModel = value.trim()
        }
        TextFieldRow {
            visible: AiConfig.provider === "claude"
            label: qsTr("Claude Code model")
            subtext: qsTr("Model alias or ID · blank uses your Claude default · requires the signed-in claude CLI")
            value: AiConfig.claudeModel
            onEditingFinished: value => AiConfig.claudeModel = value.trim()
        }
        TextFieldRow {
            visible: AiConfig.provider === "ollama"
            label: qsTr("Ollama model")
            subtext: qsTr("An already-installed model name; models are never downloaded automatically")
            value: AiConfig.ollamaModel
            placeholderText: qsTr("Model name from ollama list")
            onEditingFinished: value => AiConfig.ollamaModel = value.trim()
        }
        TextFieldRow {
            visible: AiConfig.provider === "ollama"
            label: qsTr("Local Ollama URL")
            subtext: qsTr("Loopback HTTP only · model unloads after each response to free memory")
            value: AiConfig.ollamaUrl
            onEditingFinished: value => AiConfig.ollamaUrl = value.trim()
        }
        SelectRow {
            objectName: "aiEffortSetting"
            label: AiConfig.provider === "ollama" ? qsTr("Thinking / effort") : qsTr("Reasoning effort")
            subtext: qsTr("Optional · model support varies; unsupported values may be rejected by the provider. Applies to your next message.")
            menuItems: root.efforts.slice(0, root.effortValues.length)
            active: root.efforts[Math.max(0, root.effortValues.indexOf(AiConfig.effortFor(AiConfig.provider)))]
            onSelected: item => AiConfig[AiConfig.provider + "Effort"] = root.effortValues[root.efforts.indexOf(item)]
        }
        TextFieldRow {
            visible: AiConfig.provider === "opencode"
            label: qsTr("Custom effort variant")
            subtext: qsTr("OpenCode variant name, e.g. low or high. Blank uses the model's default / #variant. Overrides the preset above.")
            value: AiConfig.opencodeEffort
            onEditingFinished: value => AiConfig.opencodeEffort = value.trim()
        }
        InfoRow {
            visible: AiConfig.provider === "opencode" && AiConfig.autoApproveTools
            label: qsTr("Auto-approval warning")
            value: qsTr("Commands and file changes run without asking")
            subtext: qsTr("Only sidebar sessions are affected. Provider-enforced restrictions still apply.")
        }
        ToggleRow {
            objectName: "aiAutoApproveSetting"
            visible: AiConfig.provider === "opencode"
            text: qsTr("Auto-approve tools")
            subtext: qsTr("Skip repeated permission prompts in this sidebar · includes commands and file edits")
            checked: AiConfig.autoApproveTools
            onToggled: AiConfig.autoApproveTools = checked
        }
        InfoRow {
            last: true
            label: qsTr("Safety & sign-in")
            value: AiConfig.provider === "claude" ? qsTr("Chat only · tools disabled") : AiConfig.provider === "codex" ? qsTr("Read-only sandbox · explicit approvals") : AiConfig.provider === "ollama" ? qsTr("Local chat · no tools") : AiConfig.autoApproveTools ? qsTr("Tools auto-approved") : qsTr("Tools require approval")
            subtext: qsTr("Uses each CLI's own login. No API keys are saved by the shell.")
        }
    }
}
