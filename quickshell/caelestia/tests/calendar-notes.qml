import QtQuick
import Quickshell
import qs.services

// A window-free reload fixture: validate the scratchpad independently of native
// dashboard widgets, hardware polling, compositor input, and calendar secrets.
ShellRoot {
    settings.watchFiles: false

    Component.onCompleted: CalendarNotes

    PersistentProperties {
        id: phase
        reloadableId: "calendar-notes-reload-test"
        property bool reloaded
    }

    Timer {
        interval: 700
        running: true
        repeat: true

        onTriggered: {
            const draft = "Calendar notes survive a shell reload";
            if (!phase.reloaded) {
                CalendarNotes.text = draft;
                phase.reloaded = true;
                Quickshell.reload(false);
            } else {
                if (CalendarNotes.text === draft)
                    console.log("TASKBAR TEST PASS");
                else
                    console.error("TASKBAR TEST FAIL: The scratchpad was lost during shell reload");
                Qt.quit();
            }
        }
    }
}
