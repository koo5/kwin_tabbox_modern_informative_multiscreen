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
    currentIndex: firstListView ? firstListView.currentIndex : 0
    
    property ListView firstListView: null
    
    property var screenConfigs: []
    
    onScreenConfigsChanged: {
        console.log("screenConfigs changed, length:", screenConfigs.length);
        console.log("About to create Repeater with model:", screenConfigs.length);
    }
    
    

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
            
            // Load multi-monitor configuration from file
            console.log("=== Loading screen config ===");
            try {
                var xhr = new XMLHttpRequest();
                xhr.open("GET", "file:///tmp/kwin-screens.txt", false);
                xhr.send();
                console.log("XHR status:", xhr.status);
                console.log("XHR response:", xhr.responseText);
                
                if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText.trim()) {
                    var screenConfigs = [];
                    var screens = xhr.responseText.trim().split(';');
                    console.log("Found", screens.length, "screens in config");
                    for (var i = 0; i < screens.length; i++) {
                        var parts = screens[i].split(',');
                        console.log("Screen", i, "parts:", parts);
                        if (parts.length === 4) {
                            var screen = {
                                width: parseInt(parts[0]),
                                height: parseInt(parts[1]), 
                                x: parseInt(parts[2]),
                                y: parseInt(parts[3])
                            };
                            screenConfigs.push(screen);
                            console.log("Added screen:", screen.width, "x", screen.height, "at", screen.x, ",", screen.y);
                        }
                    }
                    tabBox.screenConfigs = screenConfigs;
                    console.log("Final screenConfigs length:", tabBox.screenConfigs.length);
                } else {
                    console.log("No valid file content, using fallback");
                    tabBox.screenConfigs = [];
                }
            } catch (e) {
                console.log("File reading failed:", e);
                // Fallback to single monitor if file reading fails
                tabBox.screenConfigs = [];
            }
            
            // Force size update after a short delay
            sizeUpdateTimer.start();
        }
    }
    
    Timer {
        id: sizeUpdateTimer
        interval: 50
        onTriggered: {
            console.log("Timer triggered - forcing size update");
            if (firstListView) {
                console.log("FirstListView count:", firstListView.count, "rowHeight:", firstListView.rowHeight);
            }
        }
    }
    onModelChanged: {
        if (tabBox.model) {
            textMetrics.longestCaption = tabBox.model.longestCaption();
        }
    }

    // Test: simple dialog first
    Component.onCompleted: {
        console.log("TabBox component completed");
        console.log("Creating test dialogs...");
    }
    
    // First monitor dialog - use config if available, fallback to 0,0
    PlasmaCore.Dialog {
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible && dialogMainItem1.width >= 100 && dialogMainItem1.height >= 50
        flags: Qt.X11BypassWindowManagerHint
        
        property var screen: tabBox.screenConfigs.length > 0 ? tabBox.screenConfigs[0] : null
        property int screenWidth: screen ? screen.width : 1920
        property int screenHeight: screen ? screen.height : 1080
        property int screenX: screen ? screen.x : 0
        property int screenY: screen ? screen.y : 0
        
        x: Math.max(screenX, Math.min(screenX + screenWidth - width, screenX + screenWidth * 0.5 - dialogMainItem1.width * 0.5))
        y: Math.max(screenY, Math.min(screenY + screenHeight - height, screenY + screenHeight * 0.5 - dialogMainItem1.height * 0.5))
        
        Component.onCompleted: {
            console.log("Dialog 1 - visible:", visible, "pos:", x, y, "size:", width, height);
            console.log("Dialog 1 - mainItem size:", dialogMainItem1.width, dialogMainItem1.height);
            console.log("Dialog 1 - screen props:", screenWidth, screenHeight, screenX, screenY);
        }

        mainItem: Item {
            id: dialogMainItem1
            property int optimalWidth: textMetrics.width + PlasmaCore.Units.iconSizes.medium + 2 * PlasmaCore.Units.smallSpacing + hoverItem1.margins.right + hoverItem1.margins.left
            property int optimalHeight: compactListView1.rowHeight * Math.max(compactListView1.count, 1)
            
            function updateSize() {
                // Access screen properties from the Dialog's scope
                var screen = tabBox.screenConfigs.length > 0 ? tabBox.screenConfigs[0] : null;
                var sw = screen ? screen.width : 1920;
                var sh = screen ? screen.height : 1080;
                console.log("UpdateSize - screenWidth:", sw, "screenHeight:", sh);
                console.log("UpdateSize - optimalWidth:", optimalWidth, "optimalHeight:", optimalHeight);
                console.log("UpdateSize - textMetrics.width:", textMetrics.width, "listView count:", compactListView1.count, "rowHeight:", compactListView1.rowHeight);
                
                var minW = Math.max(sw * 0.2, Math.max(optimalWidth, 200));
                var maxW = sw * 0.8;
                var minH = Math.max(optimalHeight, 100);
                var maxH = sh * 0.8;
                width = Math.min(minW, maxW);
                height = Math.min(minH, maxH);
                console.log("Dialog 1 size updated:", width, "x", height, "from minW:", minW, "maxW:", maxW, "minH:", minH, "maxH:", maxH);
            }
            
            width: 200
            height: 100
            focus: true
            
            Connections {
                target: textMetrics
                function onWidthChanged() { 
                    dialogMainItem1.updateSize();
                }
            }
            
            Connections {
                target: compactListView1
                function onCountChanged() { 
                    dialogMainItem1.updateSize();
                }
            }
            
            Connections {
                target: tabBox
                function onScreenConfigsChanged() { 
                    dialogMainItem1.updateSize();
                }
            }
            
            Component.onCompleted: {
                updateSize();
            }
            
            onWidthChanged: {
                console.log("Dialog 1 mainItem width changed to:", width, "optimalWidth:", optimalWidth, "textMetrics.width:", textMetrics.width);
            }
            onHeightChanged: {
                console.log("Dialog 1 mainItem height changed to:", height, "optimalHeight:", optimalHeight, "rowHeight:", compactListView1.rowHeight, "count:", compactListView1.count);
            }

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
                
                Component.onCompleted: {
                    tabBox.firstListView = compactListView1;
                    console.log("ListView1 completed - count:", count, "model:", model);
                }
                
                onCountChanged: {
                    console.log("ListView1 count changed to:", count, "optimal height now:", compactListView1.rowHeight * count);
                }
                
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
                
                onCurrentIndexChanged: {
                    tabBox.currentIndex = currentIndex;
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
    
    // Second monitor dialog - only show if we have 2+ screens configured
    PlasmaCore.Dialog {
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible && tabBox.screenConfigs.length > 1 && dialogMainItem2.width >= 100 && dialogMainItem2.height >= 50
        flags: Qt.X11BypassWindowManagerHint
        
        property var screen: tabBox.screenConfigs.length > 1 ? tabBox.screenConfigs[1] : null
        property int screenWidth: screen ? screen.width : 1920
        property int screenHeight: screen ? screen.height : 1080
        property int screenX: screen ? screen.x : 1920
        property int screenY: screen ? screen.y : 0
        
        x: Math.max(screenX, Math.min(screenX + screenWidth - width, screenX + screenWidth * 0.5 - dialogMainItem2.width * 0.5))
        y: Math.max(screenY, Math.min(screenY + screenHeight - height, screenY + screenHeight * 0.5 - dialogMainItem2.height * 0.5))
        
        Component.onCompleted: {
            console.log("Dialog 2 - visible:", visible, "pos:", x, y, "size:", width, height);
            console.log("Dialog 2 - mainItem size:", dialogMainItem2.width, dialogMainItem2.height);
            console.log("Dialog 2 - screen props:", screenWidth, screenHeight, screenX, screenY);
        }

        mainItem: Item {
            id: dialogMainItem2
            property int optimalWidth: textMetrics.width + PlasmaCore.Units.iconSizes.medium + 2 * PlasmaCore.Units.smallSpacing + hoverItem2.margins.right + hoverItem2.margins.left
            property int optimalHeight: compactListView2.rowHeight * Math.max(compactListView2.count, 1)
            
            function updateSize() {
                // Access screen properties from the Dialog's scope
                var screen = tabBox.screenConfigs.length > 1 ? tabBox.screenConfigs[1] : null;
                var sw = screen ? screen.width : 1920;
                var sh = screen ? screen.height : 1080;
                
                var minW = Math.max(sw * 0.2, Math.max(optimalWidth, 200));
                var maxW = sw * 0.8;
                var minH = Math.max(optimalHeight, 100);
                var maxH = sh * 0.8;
                width = Math.min(minW, maxW);
                height = Math.min(minH, maxH);
                console.log("Dialog 2 size updated:", width, "x", height);
            }
            
            width: 200
            height: 100
            focus: false
            
            Connections {
                target: textMetrics
                function onWidthChanged() { 
                    dialogMainItem2.updateSize();
                }
            }
            
            Connections {
                target: compactListView2
                function onCountChanged() { 
                    dialogMainItem2.updateSize();
                }
            }
            
            Connections {
                target: tabBox
                function onScreenConfigsChanged() { 
                    dialogMainItem2.updateSize();
                }
            }
            
            Component.onCompleted: {
                updateSize();
            }

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
        }
    }
}
