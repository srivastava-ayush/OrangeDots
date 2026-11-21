import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property ScreenState screenState

    readonly property bool isFavourite: !!root.modelData && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData.id)
    readonly property bool favouriteByRegex: {
        if (!root.modelData)
            return false;
        const regexChecker = /^\^.*\$$/;
        return GlobalConfig.launcher.favouriteApps.some(f => regexChecker.test(f) && new RegExp(f).test(root.modelData.id));
    }

    function toggleFavourite(): void {
        if (!root.modelData || root.favouriteByRegex)
            return;

        const apps = GlobalConfig.launcher.favouriteApps;
        GlobalConfig.launcher.favouriteApps = root.isFavourite ? apps.filter(a => a !== root.modelData.id) : [...apps, root.modelData.id];
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            Apps.launch(root.modelData);
            root.screenState.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        IconImage {
            id: icon

            asynchronous: true
            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteArea.width - Tokens.spacing.medium
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
            }

            StyledText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteArea.width - Tokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }

        Item {
            id: favouriteArea

            readonly property int iconSize: 22

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right

            implicitWidth: iconSize + Tokens.padding.small * 2
            implicitHeight: iconSize + Tokens.padding.small * 2
            width: implicitWidth
            height: implicitHeight

            StateLayer {
                id: favouriteButton

                anchors.fill: parent
                radius: Tokens.rounding.full
                disabled: root.favouriteByRegex
                opacity: root.isFavourite || containsMouse ? 1 : 0.6
                onClicked: root.toggleFavourite()

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Image {
                    anchors.centerIn: parent
                    width: favouriteArea.iconSize
                    height: width
                    source: Qt.resolvedUrl("../../../assets/orange.svg")
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectFit
                    smooth: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        saturation: root.isFavourite ? 0 : -1

                        Behavior on saturation {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }
                }
            }
        }
    }
}
