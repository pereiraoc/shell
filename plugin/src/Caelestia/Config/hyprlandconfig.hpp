#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

// === US-007: Hyprland-managed settings (gaps), backed by C++ config. ===
// Gaps são globais (aplicados via hyprctl); o shell aplica no boot lendo
// GlobalConfig.hyprland.gaps{Inner,Outer} e a página nexus "Gaps" escreve em
// GlobalConfig.hyprland.gaps{Inner,Outer}.
class HyprlandConfig : public settings::ObjectNode {
    CONFIG_NODE(HyprlandConfig, settings::ObjectNode)

    CONFIG_PROPERTY(int, gapsInner, 5)
    CONFIG_PROPERTY(int, gapsOuter, 20)
};

} // namespace caelestia::config
