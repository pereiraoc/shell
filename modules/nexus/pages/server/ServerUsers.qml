pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Users: o login central do NAS (Authelia; users.yml e a fonte da verdade,
// `nas-users` no NAS). Uma carta por usuario: papel (User/Administrator),
// bloqueio, um interruptor por servico, nova senha temporaria, zerar 2FA e
// apagar. Embaixo, como e o primeiro login e o formulario de novo usuario.
//
// Nao passa pela ToolBridge: as respostas trazem senha/codigo e o executor
// gravaria isso no last.json do cache. Aqui e `caelestia-nas users --json` e
// `caelestia-nas run user-*` direto, numa fila (um ssh por vez); enquanto a
// fila anda a lista ja mostra o resultado esperado (S.applyPending) e, quando
// ela esvazia, relemos a lista do NAS. Recusas do NAS (ex.: ficar sem nenhum
// admin ativo) voltam ok=false com a mensagem, mostrada na carta do usuario.
// Risco medio (apagar, bloquear, nova senha, zerar 2FA): dois cliques.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property string bin: `${Quickshell.env("HOME")}/.local/bin/caelestia-nas`

    property var users: []
    property var services: []
    property bool loaded
    property string listError

    // Fila de ids (o primeiro esta rodando) e os ja aplicados desde a ultima leitura
    property var queue: []
    property var applied: []
    property bool reloadAgain
    // { user, message }: user "" = acao sem usuario (codigo de confirmacao)
    property var lastError: ({})
    // Segredo mostrado uma vez: { where: <usuario> | "add" | "code", title, value, detail }
    property var secret: ({})
    property string armed

    // Formulario de novo usuario
    property string newName
    property string newDisplay
    property string newEmail
    property bool newAdmin
    property var newServices: []
    property bool triedAdd
    property string addError

    readonly property var view: S.applyPending(S.sortUsers(root.users), [...root.applied, ...root.queue])
    readonly property bool working: root.queue.length > 0
    readonly property string formProblem: S.validateNewUser({ name: root.newName, display: root.newDisplay, email: root.newEmail }, root.users)

    function reload(): void {
        if (listProc.running) {
            root.reloadAgain = true;
            return;
        }
        listProc.snapshot = root.applied.length;
        listProc.running = true;
    }

    function labelOf(svc: string): string {
        return root.services.find(s => s.id === svc)?.label ?? svc;
    }

    function verbLabel(verb: string): string {
        switch (verb) {
        case "delete":
            return Tr.tr("Delete");
        case "block":
            return Tr.tr("Block");
        case "passwd":
            return Tr.tr("New temporary password");
        case "totp-reset":
            return Tr.tr("Reset 2FA");
        default:
            return verb;
        }
    }

    // Texto do botao: "Click again: …" quando armado
    function buttonText(verb: string, user: string): string {
        const id = S.userActionId(verb, user);
        const label = root.verbLabel(verb);
        if (root.armed === id)
            return Tr.tr("Click again: %1").arg(label);
        if (root.queue[0] === id)
            return Tr.tr("%1 — running…").arg(label);
        return label;
    }

    function press(verb: string, user: string, svc: string): void {
        const id = S.userActionId(verb, user, svc);
        if (S.userActionRisk(verb) === "medium" && root.armed !== id) {
            root.armed = id;
            disarm.restart();
            return;
        }
        root.armed = "";
        root.enqueue(id);
    }

    function enqueue(id: string): void {
        if (root.queue.includes(id))
            return;
        const a = S.parseUserAction(id);
        if (root.lastError.user === (a?.user ?? ""))
            root.lastError = ({});
        root.queue = [...root.queue, id];
        if (!actProc.running)
            root.startNext();
    }

    function startNext(): void {
        if (root.queue.length === 0) {
            root.reload();
            return;
        }
        actProc.current = root.queue[0];
        actProc.command = [root.bin, "run", actProc.current];
        actProc.running = true;
    }

    function finishAction(text: string): void {
        const id = actProc.current;
        const a = S.parseUserAction(id) ?? ({ verb: "", user: "" });
        let doc = null;
        try {
            doc = JSON.parse(text);
        } catch (e) {
            doc = { ok: false, message: Tr.tr("unreadable answer from caelestia-nas") };
        }
        if (doc.ok) {
            root.applied = [...root.applied, id];
            if (doc.password)
                root.secret = {
                    where: a.user,
                    title: Tr.tr("Temporary password for @%1 (shown only now)").arg(a.user),
                    value: doc.password,
                    detail: Tr.tr("Pass it on in person or by a private message. It works once: the first sign-in asks for a new one.")
                };
            else if (a.verb === "code")
                root.secret = {
                    where: "code",
                    title: Tr.tr("Confirmation code"),
                    value: doc.code || Tr.tr("No code yet"),
                    detail: doc.code ? Tr.tr("Type it where the sign-in page asks for the code it \"emailed\".") : Tr.tr("Start the 2FA registration on the sign-in page first, then ask again.")
                };
        } else {
            root.lastError = { user: a.user, message: doc.message || Tr.tr("The NAS refused (no message)") };
        }
        root.queue = root.queue.slice(1);
        Qt.callLater(root.startNext);
    }

    function addUser(): void {
        root.triedAdd = true;
        if (root.formProblem !== "" || addProc.running)
            return;
        root.addError = "";
        addProc.name = root.newName;
        addProc.command = [root.bin, ...S.addUserArgs({
                name: root.newName,
                display: root.newDisplay,
                email: root.newEmail,
                admin: root.newAdmin,
                services: root.newServices
            })];
        addProc.running = true;
    }

    function problemText(key: string): string {
        switch (key) {
        case "name":
            return Tr.tr("Username: 2 to 32 characters, lowercase letters, digits, . _ -, starting with a letter");
        case "exists":
            return Tr.tr("There is already a user with that name");
        case "display":
            return Tr.tr("Display name is empty");
        case "email":
            return Tr.tr("Email does not look like name@domain");
        default:
            return "";
        }
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    Component.onCompleted: reload()
    onVisibleChanged: if (visible && root.loaded && !root.working) reload()

    Process {
        id: listProc

        property int snapshot

        command: [root.bin, "users", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d.ok) {
                        root.users = d.users ?? [];
                        root.services = d.services ?? [];
                        root.listError = "";
                        root.loaded = true;
                    } else {
                        root.listError = d.message || Tr.tr("caelestia-nas users failed");
                    }
                } catch (e) {
                    root.listError = Tr.tr("unreadable answer from caelestia-nas");
                }
                // O que ja foi aplicado antes desta leitura agora esta na lista
                root.applied = root.applied.slice(listProc.snapshot);
                if (root.reloadAgain) {
                    root.reloadAgain = false;
                    Qt.callLater(root.reload);
                }
            }
        }
    }

    Process {
        id: actProc

        property string current

        stdout: StdioCollector {
            onStreamFinished: root.finishAction(text)
        }
    }

    Process {
        id: addProc

        property string name

        stdout: StdioCollector {
            onStreamFinished: {
                let d = null;
                try {
                    d = JSON.parse(text);
                } catch (e) {
                    d = { ok: false, message: Tr.tr("unreadable answer from caelestia-nas") };
                }
                if (d.ok) {
                    root.secret = {
                        where: "add",
                        title: Tr.tr("@%1 created. Temporary password (shown only now)").arg(addProc.name),
                        value: d.password ?? "",
                        detail: Tr.tr("Pass it on in person or by a private message, with the first-login steps above.")
                    };
                    root.newName = "";
                    root.newDisplay = "";
                    root.newEmail = "";
                    root.newAdmin = false;
                    root.newServices = [];
                    root.triedAdd = false;
                    root.reload();
                } else {
                    root.addError = d.message || Tr.tr("The NAS refused (no message)");
                }
            }
        }
    }

    Timer {
        id: disarm

        interval: 4000
        onTriggered: root.armed = ""
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        text: Tr.tr("One sign-in for every service on the NAS (Authelia). Each switch gives a person access to one service; Administrator also makes them admin inside Photos and Cloud. Blocking keeps the account but refuses every sign-in.")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    InfoRow {
        visible: root.listError !== ""
        first: true
        last: true
        icon: "error"
        iconColour: Colours.palette.m3error
        label: Tr.tr("Could not read the users")
        subtext: root.listError
    }

    InfoRow {
        visible: !root.loaded && root.listError === ""
        first: true
        last: true
        icon: "hourglass_empty"
        iconColour: Colours.palette.m3primary
        label: Tr.tr("Reading the users from the NAS…")
    }

    SectionHeader {
        first: true
        visible: root.loaded
        text: Tr.trN("%n USER", "%n USERS", root.view.length)
    }

    Repeater {
        model: root.loaded ? root.view.length : 0

        ColumnLayout {
            id: card

            required property int index
            property var u: root.view[index] ?? ({})
            readonly property var liveItem: root.view[index]
            readonly property string name: card.u.name ?? ""
            readonly property bool busy: S.userBusy(root.queue, card.name)
            readonly property bool deleting: card.u.deleting === true
            readonly property bool dim: card.u.blocked === true || card.deleting
            readonly property bool roleBusy: root.queue.includes(S.userActionId("admin", card.name)) || root.queue.includes(S.userActionId("member", card.name))

            onLiveItemChanged: if (liveItem !== undefined) u = liveItem

            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.medium
            spacing: Tokens.spacing.extraSmall / 2

            // Quem e: nome, @usuario, email, estado; bloquear/desbloquear a direita
            ConnectedRect {
                Layout.fillWidth: true
                first: true
                implicitHeight: head.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: head

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: card.busy ? "hourglass_top" : card.deleting ? "delete" : card.u.blocked ? "block" : card.u.admin ? "shield_person" : "person"
                        color: card.u.blocked ? Colours.palette.m3error : card.u.admin ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                        fill: 1
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        opacity: card.dim ? 0.55 : 1

                        StyledText {
                            Layout.fillWidth: true
                            text: [card.u.displayname || card.name, card.u.admin ? Tr.tr("Administrator") : "", card.u.blocked ? Tr.tr("Blocked") : "", card.deleting ? Tr.tr("Deleting…") : ""].filter(x => x).join(" · ")
                            font: Tokens.font.title.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: [`@${card.name}`, card.u.email ?? ""].filter(x => x).join(" · ")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    TextButton {
                        visible: card.u.blocked === true && !card.deleting
                        text: Tr.tr("Unblock")
                        type: TextButton.Filled
                        onClicked: root.press("unblock", card.name, "")
                    }

                    TextButton {
                        visible: card.u.blocked !== true && !card.deleting
                        text: root.buttonText("block", card.name)
                        type: root.armed === S.userActionId("block", card.name) ? TextButton.Filled : TextButton.Text
                        onClicked: root.press("block", card.name, "")
                    }
                }
            }

            // Bloqueado: o papel fica travado (desbloquear primeiro); opacity
            // no ConnectedRect clareava o fundo, entao vai pelo disabled dele
            ChipSelectRow {
                label: Tr.tr("Role")
                subtext: card.u.admin ? Tr.tr("Admin inside Photos and Cloud") : Tr.tr("Uses the services switched on below")
                options: [
                    { value: "user", label: Tr.tr("User") },
                    { value: "admin", label: Tr.tr("Administrator") }
                ]
                current: card.u.admin ? "admin" : "user"
                busy: card.roleBusy
                disabled: card.dim
                onPicked: v => {
                    if (v !== (card.u.admin ? "admin" : "user"))
                        root.press(v === "admin" ? "admin" : "member", card.name, "");
                }
            }

            // Um interruptor por servico, em grade (2-3 colunas conforme a largura)
            ConnectedRect {
                Layout.fillWidth: true
                implicitHeight: grid.implicitHeight + Tokens.padding.medium * 2

                GridLayout {
                    id: grid

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    columns: Math.max(1, Math.floor(width / 250))
                    columnSpacing: Tokens.spacing.large
                    rowSpacing: Tokens.spacing.small
                    opacity: card.dim ? 0.55 : 1

                    Repeater {
                        model: root.services.length

                        RowLayout {
                            id: cell

                            required property int index
                            readonly property var svc: root.services[index] ?? ({})
                            readonly property bool has: (card.u.services ?? []).includes(cell.svc.id)

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            spacing: Tokens.spacing.small

                            StyledText {
                                Layout.fillWidth: true
                                text: cell.svc.label ?? cell.svc.id ?? ""
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledSwitch {
                                id: sw

                                cLayer: 2
                                checked: cell.has
                                disabled: card.deleting
                                onToggled: {
                                    root.press(cell.has ? "revoke" : "grant", card.name, cell.svc.id ?? "");
                                    // O clique quebra a ligacao; a lista otimista ja traz o novo estado
                                    sw.checked = Qt.binding(() => cell.has);
                                }
                            }
                        }
                    }
                }
            }

            // Senha, 2FA, apagar (dois cliques cada)
            ConnectedRect {
                Layout.fillWidth: true
                last: !(root.secret.where === card.name) && root.lastError.user !== card.name
                implicitHeight: acts.implicitHeight + Tokens.padding.small * 2

                Flow {
                    id: acts

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.small
                    opacity: card.deleting ? 0.55 : 1

                    Repeater {
                        model: ["passwd", "totp-reset", "delete"]

                        TextButton {
                            id: actBtn

                            required property string modelData
                            readonly property bool isArmed: root.armed === S.userActionId(actBtn.modelData, card.name)

                            text: root.buttonText(actBtn.modelData, card.name)
                            type: actBtn.isArmed ? TextButton.Filled : TextButton.Text
                            inactiveOnColour: actBtn.modelData === "delete" && !actBtn.isArmed ? Colours.palette.m3error : actBtn.isArmed ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                            disabled: card.deleting
                            onClicked: root.press(actBtn.modelData, card.name, "")
                        }
                    }
                }
            }

            InfoRow {
                visible: root.lastError.user === card.name
                last: !(root.secret.where === card.name)
                icon: "error"
                iconColour: Colours.palette.m3error
                label: Tr.tr("That didn't work")
                subtext: root.lastError.message ?? ""
            }

            SecretBanner {
                first: false
                title: root.secret.title ?? ""
                value: root.secret.where === card.name ? (root.secret.value ?? "") : ""
                detail: root.secret.detail ?? ""
                onDismissed: root.secret = ({})
            }
        }
    }

    // ------------------------------------------------------------ primeiro login
    SectionHeader {
        text: Tr.tr("FIRST LOGIN")
    }

    ConnectedRect {
        Layout.fillWidth: true
        first: true
        implicitHeight: help.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: help

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: [
                    { icon: "open_in_new", text: Tr.tr("1. Open any service on the NAS (Overview › Open); it sends you to the sign-in page.") },
                    { icon: "password", text: Tr.tr("2. Sign in with the username and the temporary password, then choose a new password.") },
                    { icon: "phonelink_lock", text: Tr.tr("3. Register 2FA with an authenticator app (Aegis, Google Authenticator…). The page asks for a confirmation code it \"emailed\": there is no email, use the button below.") }
                ]

                RowLayout {
                    id: step

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        Layout.alignment: Qt.AlignTop
                        text: step.modelData.icon
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: step.modelData.text
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    RowButton {
        last: root.secret.where !== "code" && root.lastError.user !== ""
        icon: root.queue.includes("user-code") ? "hourglass_top" : "pin"
        text: root.queue.includes("user-code") ? Tr.tr("Reading the code…") : Tr.tr("Show confirmation code")
        subtext: Tr.tr("The last one-time code the sign-in page \"emailed\" (it lands in a file on the NAS)")
        onClicked: root.enqueue("user-code")
    }

    InfoRow {
        visible: root.lastError.user === ""
        last: root.secret.where !== "code"
        icon: "error"
        iconColour: Colours.palette.m3error
        label: Tr.tr("That didn't work")
        subtext: root.lastError.message ?? ""
    }

    SecretBanner {
        first: false
        title: root.secret.title ?? ""
        value: root.secret.where === "code" ? (root.secret.value ?? "") : ""
        detail: root.secret.detail ?? ""
        onDismissed: root.secret = ({})
    }

    // ------------------------------------------------------------ novo usuario
    SectionHeader {
        text: Tr.tr("ADD USER")
    }

    TextFieldRow {
        first: true
        label: Tr.tr("Username")
        subtext: Tr.tr("Used to sign in; lowercase, cannot change later")
        placeholderText: "bia"
        value: root.newName
        onValueEdited: v => root.newName = v.trim()
    }

    TextFieldRow {
        label: Tr.tr("Display name")
        placeholderText: "Bia Souza"
        value: root.newDisplay
        onValueEdited: v => root.newDisplay = v
    }

    TextFieldRow {
        label: Tr.tr("Email")
        subtext: Tr.tr("Shown in the services; nothing is sent to it")
        placeholderText: "bia@example.com"
        value: root.newEmail
        onValueEdited: v => root.newEmail = v.trim()
    }

    ToggleRow {
        text: Tr.tr("Administrator")
        subtext: Tr.tr("Admin inside Photos and Cloud")
        checked: root.newAdmin
        onToggled: root.newAdmin = checked
    }

    // Servicos do novo usuario: chips que ligam/desligam
    ConnectedRect {
        Layout.fillWidth: true
        implicitHeight: svcCol.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: svcCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Services")
                font: Tokens.font.body.small
            }

            Flow {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: root.services.length

                    TextButton {
                        id: chip

                        required property int index
                        readonly property var svc: root.services[index] ?? ({})

                        isToggle: true
                        checked: root.newServices.includes(chip.svc.id)
                        type: TextButton.Tonal
                        text: chip.svc.label ?? chip.svc.id ?? ""
                        onClicked: root.newServices = S.toggleIn(root.newServices, chip.svc.id)
                    }
                }
            }
        }
    }

    InfoRow {
        visible: (root.triedAdd && root.formProblem !== "") || root.addError !== ""
        icon: "error"
        iconColour: Colours.palette.m3error
        label: root.addError !== "" ? Tr.tr("The NAS refused") : Tr.tr("Check the form")
        subtext: root.addError !== "" ? root.addError : root.problemText(root.formProblem)
    }

    RowButton {
        last: !(root.secret.where === "add")
        icon: addProc.running ? "hourglass_top" : "person_add"
        text: addProc.running ? Tr.tr("Creating…") : Tr.tr("Create user")
        subtext: Tr.tr("Generates a temporary password, shown here once")
        disabled: addProc.running || !root.loaded
        onClicked: root.addUser()
    }

    SecretBanner {
        first: false
        title: root.secret.title ?? ""
        value: root.secret.where === "add" ? (root.secret.value ?? "") : ""
        detail: root.secret.detail ?? ""
        onDismissed: root.secret = ({})
    }

    RowButton {
        Layout.topMargin: Tokens.spacing.largeIncreased
        first: true
        last: true
        icon: listProc.running ? "hourglass_top" : "refresh"
        text: Tr.tr("Reload users")
        disabled: listProc.running || root.working
        onClicked: root.reload()
    }
}
