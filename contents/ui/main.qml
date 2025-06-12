/*
 A modern and informative window switcher layout for KWin.

 SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
 SPDX-FileCopyrightText: 2023 Mélanie Chauvel (ariasuni) <perso@hack-libre.org>

 SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kwin 2.0 as KWin

KWin.Switcher {
    id: tabBox
    currentIndex: compactListView.currentIndex

    /**
    * Returns the caption with adjustments for minimized items.
    * @param caption the original caption
    * @param mimized whether the item is minimized
    * @return Caption adjusted for minimized state
    **/
    function itemCaption(caption, minimized) {
        if (minimized) {
            return "(" + caption + ")";
        }
        return caption;
    }

    TextMetrics {
        id: textMetrics
        property string longestCaption: tabBox.model.longestCaption()
        text: itemCaption(longestCaption, true)
    }

    onVisibleChanged: {
        if (visible) {
            // Window captions may have change completely
            textMetrics.longestCaption = tabBox.model.longestCaption();
        }
    }
    onModelChanged: {
        textMetrics.longestCaption = tabBox.model.longestCaption();
    }

    PlasmaCore.Dialog {
        id: dialog
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - dialogMainItem.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem.height * 0.5

        mainItem: Item {
            id: dialogMainItem

            property int optimalWidth: textMetrics.width + PlasmaCore.Units.iconSizes.medium + 2 * PlasmaCore.Units.smallSpacing + hoverItem.margins.right + hoverItem.margins.left
            property int optimalHeight: compactListView.rowHeight * compactListView.count
            width: Math.min(Math.max(tabBox.screenGeometry.width * 0.2, optimalWidth), tabBox.screenGeometry.width * 0.8)
            height: Math.min(optimalHeight, tabBox.screenGeometry.height * 0.8)
            focus: true

            // just to get the margin sizes
            PlasmaCore.FrameSvgItem {
                id: hoverItem
                imagePath: "widgets/viewitem"
                prefix: "hover"
                visible: false
            }

            ListView {
                id: compactListView

                property int rowHeight: Math.max(PlasmaCore.Units.iconSizes.medium, textMetrics.height) + hoverItem.margins.top * 2 + hoverItem.margins.bottom * 2

                anchors.fill: parent
                clip: true

                model: tabBox.model
                delegate: RowLayout {

                    width: compactListView.width
                    height: compactListView.rowHeight
                    opacity: minimized ? 0.6 : 1.0

                    spacing: 2 * PlasmaCore.Units.mediumSpacing

                    PlasmaCore.IconItem {
                        id: iconItem
                        source: model.icon
                        usesPlasmaTheme: false
                        Layout.preferredWidth: PlasmaCore.Units.iconSizes.medium
                        Layout.preferredHeight: PlasmaCore.Units.iconSizes.medium
                        Layout.leftMargin: hoverItem.margins.left * 2
                        Layout.topMargin: hoverItem.margins.top
                        Layout.bottomMargin: hoverItem.margins.bottom
                    }
                    PlasmaComponents3.Label {
                        id: captionItem
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignBottom
                        text: itemCaption(caption, minimized)
                        textFormat: Text.PlainText  // backported from Plasma 6: https://invent.kde.org/plasma/kdeplasma-addons/-/commit/05f7dc7d02ec47edea543912eb4e75126e229069
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                        Layout.topMargin: hoverItem.margins.top
                        Layout.bottomMargin: hoverItem.margins.bottom
                    }
                    PlasmaComponents3.Label {
                        id: desktopNameItem
                        text: desktopName
                        elide: Text.ElideMiddle
                        visible: tabBox.allDesktops
                        Layout.rightMargin: hoverItem.margins.right * 2
                        Layout.topMargin: hoverItem.margins.top
                        Layout.bottomMargin: hoverItem.margins.bottom
                    }
                    TapHandler {
                        onSingleTapped: {
                            if (index === compactListView.currentIndex) {
                                compactListView.model.activate(index);
                                return;
                            }
                            compactListView.currentIndex = index;
                        }
                        onDoubleTapped: compactListView.model.activate(index)
                    }
                }
                highlight: PlasmaCore.FrameSvgItem {
                    imagePath: "widgets/viewitem"
                    prefix: "hover"
                    width: compactListView.width
                }
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                Connections {
                    target: tabBox
                    function onCurrentIndexChanged() {compactListView.currentIndex = tabBox.currentIndex;}
                }
            }
            /*
            * Key navigation on outer item for two reasons:
            * @li we have to emit the change signal
            * @li on multiple invocation it does not work on the list view. Focus seems to be lost.
            **/
            Keys.onPressed: {
                if (event.key == Qt.Key_Up) {
                    compactListView.decrementCurrentIndex();
                } else if (event.key == Qt.Key_Down) {
                    compactListView.incrementCurrentIndex();
                }
            }
        }
    }
}
