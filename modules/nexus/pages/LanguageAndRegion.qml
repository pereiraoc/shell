import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // Locais do tempo (V3-09)
    property var weatherLocations: []
    property bool weatherAuto: true
    property var placeResults: []
    property bool searching
    property string searchError

    // Temperature units (there must be one for each value of the TemperatureUnit enum)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: Tr.tr("Auto")
            value: TemperatureUnit.Auto
        },
        MenuItem {
            text: Tr.tr("°C")
            value: TemperatureUnit.Celsius
        },
        MenuItem {
            text: Tr.tr("°F")
            value: TemperatureUnit.Fahrenheit
        },
        MenuItem {
            text: Tr.tr("K")
            value: TemperatureUnit.Kelvin
        }
    ]

    // Data size units (there must be one for each value of the DataUnit enum)
    readonly property list<MenuItem> dataItems: [
        MenuItem {
            text: Tr.tr("Binary (KiB, MiB)")
            value: DataUnit.Binary
        },
        MenuItem {
            text: Tr.tr("Decimal (KB, MB)")
            value: DataUnit.Decimal
        }
    ]

    // Clock formats (there must be one for each value of the ClockFormat enum)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: Tr.tr("Auto")
            value: ClockFormat.Auto
        },
        MenuItem {
            text: Tr.tr("12-hour")
            value: ClockFormat.TwelveHour
        },
        MenuItem {
            text: Tr.tr("24-hour")
            value: ClockFormat.TwentyFourHour
        }
    ]

    readonly property var region: regionBridge.info

    function saveWeather(list: var, auto: bool): void {
        root.weatherLocations = list;
        root.weatherAuto = auto;
        weatherFile.setText(JSON.stringify({ locations: list, auto: auto }, null, 4) + "\n");
    }

    function parseWeather(text: string): void {
        try {
            const d = JSON.parse(text);
            root.weatherLocations = Array.isArray(d.locations) ? d.locations : [];
            root.weatherAuto = d.auto !== false;
        } catch (e) {
            root.weatherLocations = [];
            root.weatherAuto = true;
        }
    }

    function searchPlace(query: string): void {
        const q = query.trim();
        root.placeResults = [];
        root.searchError = "";
        if (!q)
            return;
        root.searching = true;
        const lang = Qt.locale().name.split("_")[0] || "en";
        Requests.get(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(q)}&count=6&language=${lang}&format=json`, text => {
            root.searching = false;
            try {
                const results = JSON.parse(text).results ?? [];
                root.placeResults = results.map(x => ({
                    name: x.name,
                    label: x.admin1 ? `${x.name}, ${x.admin1}` : x.name,
                    detail: `${x.country ?? ""} · ${Number(x.latitude).toFixed(3)}, ${Number(x.longitude).toFixed(3)}`,
                    coords: `${x.latitude},${x.longitude}`
                }));
                if (root.placeResults.length === 0)
                    root.searchError = Tr.tr("No place found");
            } catch (e) {
                root.searchError = Tr.tr("Search failed");
            }
        }, error => {
            root.searching = false;
            root.searchError = Tr.tr("Search failed: %1").arg(error);
        });
    }

    function addPlace(p: var): void {
        root.saveWeather([...root.weatherLocations, { name: p.name, coords: p.coords, enabled: true }], root.weatherAuto);
        root.placeResults = [];
        placeSearch.clear();
    }

    title: qsTr("Language & region")
    description: qsTr("Time zone, language, weather and units")
    tabs: [
        { id: "language", label: Tr.tr("Language") },
        { id: "region", label: Tr.tr("Region") },
        { id: "time", label: Tr.tr("Time & date") }
    ]

    // Fuso, NTP, locale e keymap pelo caelestia-region (timedatectl/localectl;
    // mudar fuso/NTP pede senha pelo polkit do proprio systemd).
    // Locais do tempo (PageBase so aceita Item como filho direto; o ultimo
    // Item e o conteudo, por isso antes do layout)
    Item {
        FileView {
            id: weatherFile

            path: `${Paths.config}/weather.json`
            watchChanges: true
            printErrors: false
            onFileChanged: reload()
            onLoaded: root.parseWeather(text())
            onLoadFailed: {
                root.weatherLocations = [];
                root.weatherAuto = true;
            }
        }
    }

    ToolBridge {
        id: regionBridge

        tool: "region"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        TabPane {
            active: root.tab === "language"

            // Language
            SectionHeader {
                first: true
                text: Tr.tr("Language")
            }

            SelectRow {
                first: true
                last: !root.region.locale
                implicitHeight: localeLayout.implicitHeight + localeLayout.anchors.margins * 2

                menuItems: [autoLang, ...langItems.instances]

                MenuItem {
                    id: autoLang

                    text: Tr.tr("Auto")
                }

                Variants {
                    id: langItems

                    model: Tr.supportedLanguages

                    MenuItem {
                        required property string modelData

                        text: {
                            const locale = Qt.locale(modelData);
                            return locale.name === "C" ? modelData : locale.nativeLanguageName || locale.name;
                        }
                    }
                }
            }

            InfoRow {
                visible: !!root.region.locale
                last: true
                icon: "keyboard"
                label: qsTr("System locale %1 · console keyboard %2").arg(root.region.locale ?? "").arg(root.region.keymap_console ?? "")
                subtext: qsTr("Changing these needs a terminal (localectl) and a new session. Keyboard layout for apps is in Devices.")
            }
        }

        TabPane {
            active: root.tab === "region"

            // Weather
            SectionHeader {
                first: true
                text: Tr.tr("Weather")
            }

            // Locais (V3-09): lista em ~/.config/caelestia/weather.json; o
            // servico Weather observa o arquivo e o dashboard troca com setas
            ListEditor {
                function labelFor(item: var): string {
                    return item.name || item.coords;
                }

                function toggledFor(item: var): bool {
                    return item.enabled !== false;
                }

                z: 1
                first: true
                visible: root.weatherLocations.length > 0
                values: root.weatherLocations
                onItemMoved: (from, to) => {
                    const l = [...root.weatherLocations];
                    const [m] = l.splice(from, 1);
                    l.splice(to, 0, m);
                    root.saveWeather(l, root.weatherAuto);
                }
                onItemRemoved: index => {
                    const l = [...root.weatherLocations];
                    l.splice(index, 1);
                    root.saveWeather(l, root.weatherAuto);
                }
                onItemToggled: (index, checked) => root.saveWeather(root.weatherLocations.map((x, i) => i === index ? Object.assign({}, x, { enabled: checked }) : x), root.weatherAuto)
            }

            TextFieldRow {
                id: placeSearch

                first: root.weatherLocations.length === 0
                label: Tr.tr("Add a place")
                subtext: root.searching ? Tr.tr("Searching…") : (root.searchError || Tr.tr("Type a city, press Enter, then pick a match"))
                placeholderText: Tr.tr("City")
                maximumLength: 80
                onEditingFinished: v => root.searchPlace(v)
            }

            Repeater {
                model: root.placeResults

                RowButton {
                    required property var modelData

                    icon: "add_location"
                    text: modelData.label
                    subtext: modelData.detail
                    trailingIcon: "add"
                    onClicked: root.addPlace(modelData)
                }
            }

            ToggleRow {
                last: true
                text: Tr.tr("Automatic location")
                subtext: Tr.tr("Where the network says you are; always the last entry")
                checked: root.weatherAuto
                onToggled: root.saveWeather(root.weatherLocations, checked)
            }

            // Units
            SectionHeader {
                text: Tr.tr("Units")
            }

            SelectRow {
                first: true
                label: Tr.tr("Temperature")
                subtext: Tr.tr("Units for weather temperatures")
                menuItems: root.tempItems
                active: root.tempItems.find(i => i.value === GlobalConfig.services.weatherUnits)
                onSelected: item => GlobalConfig.services.weatherUnits = item.value
            }

            SelectRow {
                label: Tr.tr("System temperatures")
                subtext: Tr.tr("Units for CPU and GPU temperatures")
                menuItems: root.tempItems
                active: root.tempItems.find(i => i.value === GlobalConfig.services.sensorUnits)
                onSelected: item => GlobalConfig.services.sensorUnits = item.value
            }

            SelectRow {
                last: true
                label: Tr.tr("Data sizes")
                subtext: Tr.tr("Units for data sizes and network speeds")
                menuItems: root.dataItems
                active: root.dataItems.find(i => i.value === GlobalConfig.services.dataUnits)
                onSelected: item => GlobalConfig.services.dataUnits = item.value
            }
        }

        TabPane {
            active: root.tab === "time"

            // Time & date
            SectionHeader {
                first: true
                text: Tr.tr("Time & date")
            }

            ExpandSelectRow {
                first: true
                icon: "schedule"
                label: qsTr("Time zone")
                subtext: qsTr("Asks for your password")
                filterable: true
                options: (root.region.timezones ?? []).map(z => ({ value: z, label: z.replace(/_/g, " ") }))
                current: root.region.timezone ?? ""
                busy: regionBridge.busyAction.startsWith("timezone-")
                onPicked: v => regionBridge.run({ id: `timezone-${v}` })
            }

            ToggleRow {
                text: qsTr("Set time automatically")
                subtext: root.region.ntp ? (root.region.synced ? qsTr("Synchronized with network time") : qsTr("Waiting for network time…")) : qsTr("The clock is not corrected automatically")
                checked: !!root.region.ntp
                disabled: regionBridge.busyAction !== "" || root.region.ntp === undefined
                onToggled: regionBridge.run({ id: checked ? "ntp-on" : "ntp-off" })
            }

            SelectRow {
                last: true
                label: Tr.tr("Clock format")
                subtext: Tr.tr("How times are shown across the shell")
                menuItems: root.clockItems
                active: root.clockItems.find(i => i.value === GlobalConfig.services.clockFormat)
                onSelected: item => GlobalConfig.services.clockFormat = item.value
            }

            ActionErrorRow {
                bridge: regionBridge
            }
        }
    }
}
