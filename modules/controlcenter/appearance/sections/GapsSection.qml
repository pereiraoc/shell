pragma ComponentBehavior: Bound

import ".."
import "../../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    id: root

    required property var rootPane

    title: qsTr("Window Gaps")
    showBackground: true

    function applyGaps(inner: int, outer: int): void {
        Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", inner.toString()]);
        Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", outer.toString()]);
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Inner gaps")
            value: rootPane.gapsInner
            from: 0
            to: 30
            decimals: 0
            suffix: "px"
            validator: IntValidator { bottom: 0; top: 30 }
            
            onValueModified: (newValue) => {
                rootPane.gapsInner = newValue;
                root.applyGaps(newValue, rootPane.gapsOuter);
                rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Outer gaps")
            value: rootPane.gapsOuter
            from: 0
            to: 50
            decimals: 0
            suffix: "px"
            validator: IntValidator { bottom: 0; top: 50 }
            
            onValueModified: (newValue) => {
                rootPane.gapsOuter = newValue;
                root.applyGaps(rootPane.gapsInner, newValue);
                rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal
        
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                text: qsTr("Quick presets")
                Layout.fillWidth: true
            }

            IconButton {
                icon: "crop_free"
                type: IconButton.Outlined
                label.text: qsTr("None")
                onClicked: {
                    rootPane.gapsInner = 0;
                    rootPane.gapsOuter = 0;
                    root.applyGaps(0, 0);
                    rootPane.saveConfig();
                }
            }

            IconButton {
                icon: "grid_view"
                type: IconButton.Outlined
                label.text: qsTr("Small")
                onClicked: {
                    rootPane.gapsInner = 3;
                    rootPane.gapsOuter = 5;
                    root.applyGaps(3, 5);
                    rootPane.saveConfig();
                }
            }

            IconButton {
                icon: "dashboard"
                type: IconButton.Outlined
                label.text: qsTr("Large")
                onClicked: {
                    rootPane.gapsInner = 10;
                    rootPane.gapsOuter = 20;
                    root.applyGaps(10, 20);
                    rootPane.saveConfig();
                }
            }
        }
    }
}
