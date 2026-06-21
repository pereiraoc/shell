#pragma once

#include "configobject.hpp"

namespace caelestia::config {

// === US-007: Hyprland-managed settings (gaps), backed by C++ config. ===
// Gaps são globais (aplicados via hyprctl); o shell aplica no boot lendo
// Config.hyprland.gaps{Inner,Outer} e a página nexus "Gaps" escreve em
// GlobalConfig.hyprland.gaps{Inner,Outer}.
class HyprlandConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(int, gapsInner, 5)
    CONFIG_PROPERTY(int, gapsOuter, 20)

public:
    explicit HyprlandConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
