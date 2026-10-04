pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Linha que mostra o valor atual e, ao clicar, abre a lista de opcoes ali
// mesmo (sem popup). Para listas medias/longas: resolucoes, fusos, presets.
// Com `filterable`, um campo filtra a lista (e so `maxShown` aparecem).
ConnectedRect {
    id: root

    property string icon
    property string label
    property string subtext
    // [{ value: string, label: string, detail?: string }]
    property var options: []
    property string current
    property bool busy
    property bool disabled
    property bool filterable
    property int maxShown: 12
    property bool expanded

    readonly property var currentOption: root.options.find(o => o.value === root.current) ?? null
    readonly property var shown: {
        const q = filterField.text.toLowerCase().trim();
        const list = q ? root.options.filter(o => `${o.label} ${o.detail ?? ""}`.toLowerCase().includes(q)) : root.options;
        return root.filterable ? list.slice(0, root.maxShown) : list;
    }

    signal picked(value: string)

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight
    clip: true

    Behavior on implicitHeight {
        Anim {}
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item {
            Layout.fillWidth: true
            implicitHeight: header.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                disabled: root.disabled || root.busy
                onClicked: root.expanded = !root.expanded
            }

            RowLayout {
                id: header

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium
                opacity: root.disabled ? 0.5 : 1

                MaterialIcon {
                    visible: root.icon !== ""
                    text: root.icon
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
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

                CircularIndicator {
                    visible: root.busy
                    running: visible
                    implicitSize: valueLabel.implicitHeight * 1.4
                }

                StyledText {
                    id: valueLabel

                    visible: !root.busy
                    text: root.currentOption?.label ?? root.current
                    color: Colours.palette.m3primary
                    font: Tokens.font.label.medium
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
        }

        StyledTextField {
            id: filterField

            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.largeIncreased
            Layout.rightMargin: Tokens.padding.largeIncreased
            Layout.bottomMargin: Tokens.padding.small
            visible: root.expanded && root.filterable
            placeholderText: qsTr("Type to filter")
        }

        Repeater {
            model: root.expanded ? root.shown : []

            Item {
                id: opt

                required property var modelData

                readonly property bool isCurrent: modelData.value === root.current

                Layout.fillWidth: true
                implicitHeight: optRow.implicitHeight + Tokens.padding.small * 2

                StateLayer {
                    disabled: opt.isCurrent
                    onClicked: {
                        root.expanded = false;
                        filterField.text = "";
                        root.picked(opt.modelData.value);
                    }
                }

                RowLayout {
                    id: optRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased * 2
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.fillWidth: true
                        text: opt.modelData.label
                        color: opt.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        visible: text !== ""
                        text: opt.modelData.detail ?? ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }

                    MaterialIcon {
                        visible: opt.isCurrent
                        text: "check"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            visible: root.expanded
            implicitHeight: Tokens.padding.small
        }
    }
}
