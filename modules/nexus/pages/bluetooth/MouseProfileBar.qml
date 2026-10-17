pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Perfis do mouse numa linha so (Mouse > <mouse> > Buttons): pilula com os
// perfis (toque = usar) e acoes no fim -- renomear, novo, apagar. Renomear e
// novo trocam a pilula por um campo no lugar; apagar troca a linha pela
// confirmacao (nada some no primeiro clique). Mesmo visual dos seletores do
// Nexus (ChipSelectRow).
ConnectedRect {
    id: root

    property var profiles: []
    property string current
    property bool busy

    // "" (normal) | "new" | "rename" | "delete"
    property string mode

    signal use(name: string)
    signal create(name: string)
    signal rename(oldName: string, newName: string)
    signal remove(name: string)

    function valid(n: string): bool {
        return /^[A-Za-z0-9]{1,16}$/.test(n) && (n === root.current && root.mode === "rename" || !root.profiles.includes(n));
    }

    function commit(): void {
        const n = field.text.trim();
        if (!root.valid(n))
            return;
        if (root.mode === "new")
            root.create(n);
        else if (n !== root.current)
            root.rename(root.current, n);
        root.mode = "";
    }

    function startEdit(m: string): void {
        root.mode = m;
        field.text = m === "rename" ? root.current : "";
        field.forceActiveFocus();
        field.selectAll();
    }

    Layout.fillWidth: true
    first: true
    last: true
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2
    // Uma linha centrada: nao precisa da folga dos cantos (capPad)
    Layout.preferredHeight: implicitHeight

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.small

        MaterialIcon {
            visible: root.mode !== "delete"
            text: "stacks"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            visible: root.mode !== "delete"
            text: qsTr("Profile")
            font: Tokens.font.body.small
        }

        // ---------------------------------------------------- normal: perfis
        StyledRect {
            Layout.fillWidth: true
            visible: root.mode === ""
            implicitHeight: chips.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surfaceContainerHigh

            CircularIndicator {
                anchors.centerIn: parent
                implicitSize: chips.implicitHeight
                visible: root.busy
                running: visible
            }

            RowLayout {
                id: chips

                visible: !root.busy
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.small

                Repeater {
                    model: root.profiles.length

                    StyledRect {
                        id: chip

                        required property int index
                        readonly property string name: root.profiles[index] ?? ""
                        readonly property bool isCurrent: chip.name === root.current

                        // Todos do mesmo tamanho (dividem a pilula por igual)
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitWidth: chipText.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: chipText.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: chip.isCurrent ? Colours.palette.m3primary : "transparent"

                        StateLayer {
                            radius: Tokens.rounding.full
                            color: chip.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            disabled: chip.isCurrent
                            onClicked: root.use(chip.name)
                        }

                        StyledText {
                            id: chipText

                            anchors.centerIn: parent
                            text: chip.name
                            color: chip.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.large
                        }
                    }
                }
            }
        }

        // ------------------------------------------- novo / renomear: campo
        StyledTextField {
            id: field

            Layout.fillWidth: true
            visible: root.mode === "new" || root.mode === "rename"
            placeholderText: root.mode === "new" ? qsTr("New profile name (copy of %1)").arg(root.current) : qsTr("Profile name")
            maximumLength: 16
            validate: n => root.valid(n.trim())
            emptyIsValid: false
            verticalPadding: Tokens.padding.small
            onAccepted: root.commit()
            Keys.onEscapePressed: root.mode = ""
        }

        IconButton {
            visible: root.mode === "new" || root.mode === "rename"
            icon: "check"
            type: IconButton.Text
            disabled: !root.valid(field.text.trim())
            onClicked: root.commit()
        }

        IconButton {
            visible: root.mode === "new" || root.mode === "rename"
            icon: "close"
            type: IconButton.Text
            onClicked: root.mode = ""
        }

        // ----------------------------------------------- apagar: confirmacao
        MaterialIcon {
            visible: root.mode === "delete"
            text: "delete"
            color: Colours.palette.m3error
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.mode === "delete"
            text: qsTr("Delete profile “%1”? Its buttons and DPI stages are lost.").arg(root.current)
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        TextButton {
            visible: root.mode === "delete"
            text: qsTr("Cancel")
            type: TextButton.Text
            onClicked: root.mode = ""
        }

        TextButton {
            visible: root.mode === "delete"
            text: qsTr("Delete")
            type: TextButton.Tonal
            onClicked: {
                root.remove(root.current);
                root.mode = "";
            }
        }

        // ------------------------------------------------- acoes (normal)
        IconButton {
            visible: root.mode === ""
            icon: "edit"
            type: IconButton.Text
            // Productivity e o perfil base (os outros herdam dele): nao renomeia/apaga
            disabled: root.busy || root.current === "Productivity"
            onClicked: root.startEdit("rename")
        }

        IconButton {
            visible: root.mode === ""
            icon: "add"
            type: IconButton.Text
            disabled: root.busy || root.profiles.length >= 10
            onClicked: root.startEdit("new")
        }

        IconButton {
            visible: root.mode === ""
            icon: "delete"
            type: IconButton.Text
            disabled: root.busy || root.profiles.length <= 1 || root.current === "Productivity"
            onClicked: root.mode = "delete"
        }
    }
}
