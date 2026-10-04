pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Seletor de tema no estilo do Odysseus: uma grade de cartoes, cada um
// pintado com as cores do proprio tema (fundo + quatro amostras), o atual
// marcado. Logica no caelestia-theme (repositorio de setup), que troca pelo
// CLI `caelestia scheme set` -- ele tambem aplica as cores no terminal, GTK,
// Qt, Hyprland e Discord.
PageBase {
    id: root

    readonly property var info: bridge.info
    readonly property var cur: root.info.current ?? ({})
    readonly property var schemes: root.info.schemes ?? []
    readonly property var cli: root.info.cli ?? ({})
    readonly property bool isDynamic: root.cur.name === "dynamic"
    readonly property var curScheme: root.schemes.find(s => s.name === root.cur.name && s.flavour === root.cur.flavour) ?? null
    readonly property var modes: root.isDynamic ? ["dark", "light"] : (root.curScheme?.modes ?? [])

    function pretty(text: string): string {
        if (!text || text === "default")
            return "";
        return text.charAt(0).toUpperCase() + text.slice(1);
    }

    function hex(c: var, fallback: color): color {
        return c ? `#${c}` : fallback;
    }

    title: qsTr("Theme")
    description: qsTr("Colours for the shell, terminal and apps")
    isSubPage: true

    ToolBridge {
        id: bridge

        tool: "theme"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            first: true
            last: true
            visible: bridge.error !== "" || root.cli.ok === false
            icon: "error"
            iconColour: Colours.palette.m3error
            label: qsTr("Themes can't be changed right now")
            subtext: bridge.error || qsTr("The caelestia command broke with the Python 3.14 update. Fix: paru -S caelestia-cli python-materialyoucolor")
        }

        ActionErrorRow {
            bridge: bridge
        }

        SectionHeader {
            first: bridge.error === "" && root.cli.ok !== false
            text: qsTr("Appearance")
        }

        ChipSelectRow {
            first: true
            last: !root.isDynamic
            label: qsTr("Mode")
            subtext: root.modes.length === 1 ? qsTr("%1 only comes in %2").arg(root.pretty(root.cur.name)).arg(root.modes[0]) : ""
            options: root.modes.map(m => ({ value: m, label: m === "dark" ? qsTr("Dark") : qsTr("Light"), icon: m === "dark" ? "dark_mode" : "light_mode" }))
            current: root.cur.mode ?? ""
            busy: bridge.busyAction.startsWith("mode-")
            disabled: root.cli.ok !== true
            onPicked: v => bridge.run({ id: `mode-${v}` })
        }

        ChipSelectRow {
            last: true
            visible: root.isDynamic
            label: qsTr("Colour style")
            subtext: qsTr("How colours are picked from the wallpaper")
            options: [
                { value: "tonalspot", label: qsTr("Calm") },
                { value: "vibrant", label: qsTr("Vibrant") },
                { value: "expressive", label: qsTr("Bold") },
                { value: "fidelity", label: qsTr("Faithful") },
                { value: "monochrome", label: qsTr("Mono") }
            ]
            current: root.cur.variant ?? ""
            busy: bridge.busyAction.startsWith("variant-")
            onPicked: v => bridge.run({ id: `variant-${v}` })
        }

        SectionHeader {
            text: qsTr("Themes")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(2, Math.floor(width / 190))
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            // Cores do wallpaper (esquema dinamico)
            ThemeTile {
                name: qsTr("From wallpaper")
                flavour: root.cli.dynamic ? qsTr("Matches your wallpaper") : qsTr("Needs caelestia-cli update")
                bg: Colours.palette.m3surfaceContainer
                fg: Colours.palette.m3onSurface
                swatches: [Colours.palette.m3primary, Colours.palette.m3secondary, Colours.palette.m3tertiary, Colours.palette.m3outline]
                icon: "wallpaper"
                selected: root.isDynamic
                busy: bridge.busyAction === "dynamic"
                enabledTile: root.cli.dynamic === true
                onPicked: bridge.run({ id: "dynamic" })
            }

            Repeater {
                model: root.schemes

                ThemeTile {
                    id: tile

                    required property var modelData

                    readonly property string shownMode: tile.modelData.modes.includes(root.cur.mode) ? root.cur.mode : tile.modelData.modes[0]
                    readonly property var sw: tile.modelData.swatch[tile.shownMode] ?? ({})

                    name: root.pretty(tile.modelData.name)
                    flavour: [root.pretty(tile.modelData.flavour), tile.modelData.modes.length > 1 ? qsTr("dark & light") : tile.modelData.modes[0]].filter(x => x).join(" · ")
                    bg: root.hex(tile.sw.background, "#222222")
                    fg: root.hex(tile.sw.onSurface, "#eeeeee")
                    swatches: [root.hex(tile.sw.primary, "#888888"), root.hex(tile.sw.secondary, "#888888"), root.hex(tile.sw.tertiary, "#888888"), root.hex(tile.sw.surfaceContainer, "#444444")]
                    selected: root.cur.name === tile.modelData.name && root.cur.flavour === tile.modelData.flavour
                    busy: bridge.busyAction === `scheme-${tile.modelData.name}-${tile.modelData.flavour}`
                    enabledTile: root.cli.ok === true
                    onPicked: bridge.run({ id: `scheme-${tile.modelData.name}-${tile.modelData.flavour}` })
                }
            }
        }
    }

    // Cartao de tema: pintado com as cores do proprio tema.
    component ThemeTile: StyledRect {
        id: t

        property string name
        property string flavour
        property color bg
        property color fg
        property var swatches: []
        property string icon
        property bool selected
        property bool busy
        property bool enabledTile: true

        signal picked

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: tileCol.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.large
        color: t.bg
        border.width: t.selected ? 3 : 1
        border.color: t.selected ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.4)
        opacity: t.enabledTile ? 1 : 0.5

        StateLayer {
            radius: t.radius
            color: t.fg
            disabled: !t.enabledTile || t.selected || bridge.busyAction !== ""
            onClicked: t.picked()
        }

        ColumnLayout {
            id: tileCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: t.swatches

                    Rectangle {
                        required property color modelData

                        implicitWidth: Tokens.font.icon.medium.pointSize * 1.6
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: modelData
                        border.width: 1
                        border.color: Qt.alpha(t.fg, 0.25)
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                CircularIndicator {
                    visible: t.busy
                    running: visible
                    implicitSize: Tokens.font.icon.medium.pointSize * 1.6
                }

                MaterialIcon {
                    visible: !t.busy && (t.selected || t.icon !== "")
                    text: t.selected ? "check_circle" : t.icon
                    color: t.selected ? Colours.palette.m3primary : t.fg
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: t.name
                color: t.fg
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: t.flavour
                color: Qt.alpha(t.fg, 0.7)
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }
}
