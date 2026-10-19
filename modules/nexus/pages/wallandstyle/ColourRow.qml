pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Uma cor do editor de tema: amostra + nome + campo hex; clicar na amostra
// abre os controles de matiz, saturacao e luz (HSL) ali mesmo. `value` e o
// hex sem '#'; cada mudanca sai em `edited(hex)`.
ConnectedRect {
    id: root

    property string label
    property string subtext
    property string value: "000000"
    property bool expanded

    readonly property color colour: `#${root.value}`

    signal edited(hex: string)

    function fromHsl(h: real, s: real, l: real): void {
        const c = Qt.hsla(h, s, l, 1);
        root.edited(c.toString().slice(1, 7));
    }

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Tokens.padding.medium * 2
    clip: true

    Behavior on implicitHeight {
        Anim {}
    }

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            // Amostra: clique abre/fecha os controles
            Rectangle {
                implicitWidth: Tokens.font.icon.medium.pointSize * 2.2
                implicitHeight: implicitWidth
                radius: Tokens.rounding.small
                color: root.colour
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3onSurface, 0.25)

                StateLayer {
                    radius: parent.radius
                    onClicked: root.expanded = !root.expanded
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.label
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.subtext
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            StyledTextField {
                id: hexField

                Layout.preferredWidth: Tokens.sizes.nexus.smallTextFieldWidth ?? Math.round(Tokens.sizes.nexus.textFieldWidth * 0.7)
                verticalPadding: Tokens.padding.small
                text: root.value
                validate: v => /^[0-9a-fA-F]{6}$/.test(v)
                emptyIsValid: false
                onEditingFinished: {
                    if (/^[0-9a-fA-F]{6}$/.test(text) && text.toLowerCase() !== root.value)
                        root.edited(text.toLowerCase());
                }
            }

            MaterialIcon {
                text: "expand_more"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }
            }
        }

        // Matiz / saturacao / luz
        Repeater {
            // Modelo fixo: recriar o delegate a cada cor destruiria o slider no meio do arrasto
            model: root.expanded ? ["h", "s", "l"] : []

            RowLayout {
                id: ctl

                required property string modelData

                readonly property string label: modelData === "h" ? qsTr("Hue") : modelData === "s" ? qsTr("Saturation") : qsTr("Lightness")
                readonly property real value: modelData === "h" ? (root.colour.hslHue < 0 ? 0 : root.colour.hslHue) : modelData === "s" ? root.colour.hslSaturation : root.colour.hslLightness

                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.preferredWidth: Tokens.font.body.small.pointSize * 7
                    text: ctl.label
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                StyledSlider {
                    Layout.fillWidth: true
                    implicitHeight: Tokens.padding.medium * 2
                    radius: Tokens.rounding.small
                    value: ctl.value
                    onInteraction: v => {
                        const c = root.colour;
                        const h = c.hslHue < 0 ? 0 : c.hslHue;
                        root.fromHsl(ctl.modelData === "h" ? v : h, ctl.modelData === "s" ? v : c.hslSaturation, ctl.modelData === "l" ? v : c.hslLightness);
                    }
                }

                StyledText {
                    Layout.preferredWidth: Tokens.font.body.small.pointSize * 3
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(ctl.value * (ctl.modelData === "h" ? 360 : 100))}${ctl.modelData === "h" ? "°" : "%"}`
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
        }
    }
}
