import Quickshell.Io

JsonObject {
    property Gaps gaps: Gaps {}

    component Gaps: JsonObject {
        property int inner: 5
        property int outer: 20
    }
}
