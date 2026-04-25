import Quickshell.Io

JsonObject {
    property bool recolourLogo: false
    property bool enableFprint: true
    property int maxFprintTries: 3
    property Sizes sizes: Sizes {}
    property Auth auth: Auth {}

    component Sizes: JsonObject {
        property real heightMult: 0.7
        property real ratio: 16 / 9
        property int centerWidth: 600
    }

    component Auth: JsonObject {
        // === DESATIVADO em US-002 (re-ativar em US-004 após port para nova API) ===
        // Motivo: features Howdy/PIN dependem de stack pré-merge upstream.
        // Defaults mantêm tela de lock funcional via password tradicional.
        property bool enableFaceAuth: false
        property bool enablePinAuth: false
        property bool faceEnabled: false
        property bool pinEnabled: false
        property string defaultMethod: "password"
        property string userPin: ""
        property int maxFaceRetries: 5
        property int maxPinRetries: 10
        property int maxPasswordRetries: 30
    }
}
