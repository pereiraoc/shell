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
        property bool enableFaceAuth: true
        property bool enablePinAuth: true
        property bool faceEnabled: true
        property bool pinEnabled: true
        property string defaultMethod: "face"
        property string userPin: ""
        property int maxFaceRetries: 5
        property int maxPinRetries: 10
        property int maxPasswordRetries: 30
    }
}
