pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        ExclusiveZones {
            screen: scope.modelData
            bar: content.bar
        }

        DesktopWindow {
            id: content

            screen: scope.modelData
        }
    }
}
