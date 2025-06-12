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
        property string longestCaption: tabBox.model ? tabBox.model.longestCaption() : ""
        text: itemCaption(longestCaption, true)
    }

    onVisibleChanged: {
        if (visible) {
            // Window captions may have change completely
            if (tabBox.model) {
                textMetrics.longestCaption = tabBox.model.longestCaption();
            }
            
            console.log("Testing dual dialog setup");
        }
    }
    onModelChanged: {
        if (tabBox.model) {
            textMetrics.longestCaption = tabBox.model.longestCaption();
        }
    }

    // First dialog - left side
    PlasmaCore.Dialog {
        id: dialog1
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.25 - dialogMainItem1.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem1.height * 0.5

        mainItem: Item {
            id: dialogMainItem1
            property int optimalWidth: textMetrics.width + PlasmaCore.Units.iconSizes.medium + 2 * PlasmaCore.Units.smallSpacing + hoverItem1.margins.right + hoverItem1.margins.left
            property int optimalHeight: compactListView1.rowHeight * compactListView1.count
            width: Math.min(Math.max(tabBox.screenGeometry.width * 0.2, optimalWidth), tabBox.screenGeometry.width * 0.35)
            height: Math.min(optimalHeight, tabBox.screenGeometry.height * 0.8)
            focus: true

            PlasmaCore.FrameSvgItem {
                id: hoverItem1
                imagePath: "widgets/viewitem"
                prefix: "hover"
                visible: false
            }

            ListView {
                id: compactListView1
                property int rowHeight: Math.max(PlasmaCore.Units.iconSizes.medium, textMetrics.height) + hoverItem1.margins.top * 2 + hoverItem1.margins.bottom * 2
                anchors.fill: parent
                clip: true
                model: tabBox.model
                delegate: RowLayout {
                    width: compactListView1.width
                    height: compactListView1.rowHeight
                    opacity: minimized ? 0.6 : 1.0
                    spacing: 2 * PlasmaCore.Units.mediumSpacing

                    PlasmaCore.IconItem {
                        source: model.icon
                        usesPlasmaTheme: false
                        Layout.preferredWidth: PlasmaCore.Units.iconSizes.medium
                        Layout.preferredHeight: PlasmaCore.Units.iconSizes.medium
                        Layout.leftMargin: hoverItem1.margins.left * 2
                        Layout.topMargin: hoverItem1.margins.top
                        Layout.bottomMargin: hoverItem1.margins.bottom
                    }
                    PlasmaComponents3.Label {
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignBottom
                        text: itemCaption(caption, minimized)
                        textFormat: Text.PlainText
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                        Layout.topMargin: hoverItem1.margins.top
                        Layout.bottomMargin: hoverItem1.margins.bottom
                    }
                    PlasmaComponents3.Label {
                        text: desktopName
                        elide: Text.ElideMiddle
                        visible: tabBox.allDesktops
                        Layout.rightMargin: hoverItem1.margins.right * 2
                        Layout.topMargin: hoverItem1.margins.top
                        Layout.bottomMargin: hoverItem1.margins.bottom
                    }
                    TapHandler {
                        onSingleTapped: {
                            if (index === compactListView1.currentIndex) {
                                compactListView1.model.activate(index);
                                return;
                            }
                            compactListView1.currentIndex = index;
                        }
                        onDoubleTapped: compactListView1.model.activate(index)
                    }
                }
                highlight: PlasmaCore.FrameSvgItem {
                    imagePath: "widgets/viewitem"
                    prefix: "hover"
                    width: compactListView1.width
                }
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                Connections {
                    target: tabBox
                    function onCurrentIndexChanged() {compactListView1.currentIndex = tabBox.currentIndex;}
                }
            }
            Keys.onPressed: {
                if (event.key == Qt.Key_Up) {
                    compactListView1.decrementCurrentIndex();
                } else if (event.key == Qt.Key_Down) {
                    compactListView1.incrementCurrentIndex();
                }
            }
        }
    }

    // Second dialog - right side
    PlasmaCore.Dialog {
        id: dialog2
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.75 - dialogMainItem2.width * 0.5
        y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - dialogMainItem2.height * 0.5

        mainItem: Item {
            id: dialogMainItem2

            property int optimalWidth: textMetrics.width + PlasmaCore.Units.iconSizes.medium + 2 * PlasmaCore.Units.smallSpacing + hoverItem2.margins.right + hoverItem2.margins.left
            property int optimalHeight: compactListView2.rowHeight * compactListView2.count
            width: Math.min(Math.max(tabBox.screenGeometry.width * 0.2, optimalWidth), tabBox.screenGeometry.width * 0.35)
            height: Math.min(optimalHeight, tabBox.screenGeometry.height * 0.8)
            focus: false

            PlasmaCore.FrameSvgItem {
                id: hoverItem2
                imagePath: "widgets/viewitem"
                prefix: "hover"
                visible: false
            }

            ListView {
                id: compactListView2

                property int rowHeight: Math.max(PlasmaCore.Units.iconSizes.medium, textMetrics.height) + hoverItem2.margins.top * 2 + hoverItem2.margins.bottom * 2

                anchors.fill: parent
                clip: true

                model: tabBox.model
                delegate: RowLayout {

                    width: compactListView2.width
                    height: compactListView2.rowHeight
                    opacity: minimized ? 0.6 : 1.0

                    spacing: 2 * PlasmaCore.Units.mediumSpacing

                    PlasmaCore.IconItem {
                        id: iconItem
                        source: model.icon
                        usesPlasmaTheme: false
                        Layout.preferredWidth: PlasmaCore.Units.iconSizes.medium
                        Layout.preferredHeight: PlasmaCore.Units.iconSizes.medium
                        Layout.leftMargin: hoverItem2.margins.left * 2
                        Layout.topMargin: hoverItem2.margins.top
                        Layout.bottomMargin: hoverItem2.margins.bottom
                    }
                    PlasmaComponents3.Label {
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignBottom
                        text: itemCaption(caption, minimized)
                        textFormat: Text.PlainText
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                        Layout.topMargin: hoverItem2.margins.top
                        Layout.bottomMargin: hoverItem2.margins.bottom
                    }
                    PlasmaComponents3.Label {
                        text: desktopName
                        elide: Text.ElideMiddle
                        visible: tabBox.allDesktops
                        Layout.rightMargin: hoverItem2.margins.right * 2
                        Layout.topMargin: hoverItem2.margins.top
                        Layout.bottomMargin: hoverItem2.margins.bottom
                    }
                    TapHandler {
                        onSingleTapped: {
                            if (index === compactListView2.currentIndex) {
                                compactListView2.model.activate(index);
                                return;
                            }
                            compactListView2.currentIndex = index;
                        }
                        onDoubleTapped: compactListView2.model.activate(index)
                    }
                }
                highlight: PlasmaCore.FrameSvgItem {
                    imagePath: "widgets/viewitem"
                    prefix: "hover"
                    width: compactListView2.width
                }
                highlightMoveDuration: 0
                highlightResizeDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                Connections {
                    target: tabBox
                    function onCurrentIndexChanged() {compactListView2.currentIndex = tabBox.currentIndex;}
                }
            }
            /*
            * Key navigation on outer item for two reasons:
            * @li we have to emit the change signal
            * @li on multiple invocation it does not work on the list view. Focus seems to be lost.
            **/
            Keys.onPressed: {
                if (event.key == Qt.Key_Up) {
                    compactListView2.decrementCurrentIndex();
                } else if (event.key == Qt.Key_Down) {
                    compactListView2.incrementCurrentIndex();
                }
            }
        }
    }
}
