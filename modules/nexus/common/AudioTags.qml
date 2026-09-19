pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.services

// Etiquetas compactas dizendo COMO o audio daquele dispositivo esta sendo
// transportado. Ficam a direita do nome em cada linha da lista, entao alinham
// em coluna ao longo dela.
//
// Servem tanto para saidas quanto para entradas: o que muda e quais tags fazem
// sentido, nao o componente.
RowLayout {
    id: root

    required property PwNode node

    // Derivadas do proprio no, sem consultar nada externo:
    //   codec Bluetooth  -> api.bluez5.codec  (ldac / aac / sbc / msbc)
    //   canais           -> PwNodeAudio.channels
    //   cadeia de efeitos-> descricao do sink default quando ele e um filtro
    readonly property var tags: {
        const out = [];
        const p = root.node?.properties ?? ({});
        const codec = p["api.bluez5.codec"] ?? "";
        const ch = root.node?.audio?.channels?.length ?? 0;

        // Como esta indo pelo ar. mSBC so existe em HFP, entao ja diz tudo.
        if (codec)
            out.push(codec.toUpperCase());

        // Quantos canais chegam no dispositivo.
        if (ch === 1)
            out.push(qsTr("MONO"));
        else if (ch === 2)
            out.push(qsTr("STEREO"));
        else if (ch > 2)
            out.push(`${ch}CH`);

        // Processamento. So vale para o dispositivo que esta efetivamente
        // recebendo o audio, e o nome da cadeia ja diz o que ela contem.
        if (Audio.defaultIsFilter && root.node === Audio.outputDevice) {
            const desc = Audio.sink?.description ?? "";
            if (desc.includes("HRTF"))
                out.push(qsTr("SURROUND"));
            if (desc.includes("EQ"))
                out.push(qsTr("EQ"));
        }

        // Supressao de ruido. O no do echo-cancel fica escondido do seletor,
        // entao a tag vai no microfone REAL que esta por baixo dele.
        if (AudioProfile.status?.suppression_active && root.node === Audio.sourceDevice)
            out.push(qsTr("NR"));

        return out;
    }

    spacing: Tokens.spacing.extraSmall / 2

    Repeater {
        model: root.tags

        delegate: StyledRect {
            id: tag

            required property string modelData

            implicitWidth: tagLabel.implicitWidth + Tokens.padding.small
            implicitHeight: tagLabel.implicitHeight + Tokens.padding.extraSmall / 2
            radius: Tokens.rounding.extraSmall
            color: "transparent"
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            StyledText {
                id: tagLabel

                anchors.centerIn: parent
                text: tag.modelData
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }
    }
}
