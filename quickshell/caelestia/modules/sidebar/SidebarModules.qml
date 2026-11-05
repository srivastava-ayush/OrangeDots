pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.modules.sidebar.modules.ai as Ai
import qs.modules.sidebar.modules.calendar as Calendar
import qs.modules.sidebar.modules.clipboard as Clipboard
import qs.modules.sidebar.modules.focus as Focus
import qs.modules.sidebar.modules.notes as Notes

// Module contract: screenState, selected, closeRequested. Backend/session state
// belongs to the module, never to the sliding container.
QtObject {
    id: root
    required property ScreenState screenState
    required property string selectedModule
    required property bool active
    signal closeRequested

    readonly property Component ai: Component {
        Ai.AiModule {
            screenState: root.screenState
            selected: root.active && root.selectedModule === "ai"
            onCloseRequested: root.closeRequested()
        }
    }
    readonly property Component calendar: Component {
        Calendar.CalendarModule {
            screenState: root.screenState
            selected: root.active && root.selectedModule === "calendar"
            onCloseRequested: root.closeRequested()
        }
    }

    function componentFor(id: string): Component {
        return ({ ai: ai, calendar: calendar, clipboard: clipboard, focus: focus, notes: notes })[id] ?? null;
    }

    readonly property Component clipboard: Component {
        Clipboard.ClipboardModule {
            screenState: root.screenState
            selected: root.active && root.selectedModule === "clipboard"
            onCloseRequested: root.closeRequested()
        }
    }
    readonly property Component focus: Component {
        Focus.FocusModule {
            screenState: root.screenState
            selected: root.active && root.selectedModule === "focus"
            onCloseRequested: root.closeRequested()
        }
    }
    readonly property Component notes: Component {
        Notes.NotesModule {
            screenState: root.screenState
            selected: root.active && root.selectedModule === "notes"
            onCloseRequested: root.closeRequested()
        }
    }
}
