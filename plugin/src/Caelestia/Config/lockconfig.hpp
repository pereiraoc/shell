#pragma once

#include <qstring.h>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class LockConfig : public settings::ObjectNode {
    CONFIG_NODE(LockConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, useWallpaper, false)
    // Custom: default false (logo sem recolor no nosso setup)
    CONFIG_PROPERTY(bool, recolourLogo, false)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, enableHowdy, true)
    CONFIG_GLOBAL_PROPERTY(int, maxHowdyTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerHowdyOnWake, true)
    CONFIG_PROPERTY(bool, hideNotifs, false)

    // === US-004: Howdy/PIN auth (custom Caelestia patch) ===
    CONFIG_GLOBAL_PROPERTY(bool, enableFaceAuth, true)
    CONFIG_GLOBAL_PROPERTY(bool, enablePinAuth, true)
    CONFIG_GLOBAL_PROPERTY(QString, defaultMethod, u"face"_s)
    CONFIG_GLOBAL_PROPERTY(QString, userPin, u""_s)
    CONFIG_GLOBAL_PROPERTY(int, maxFaceRetries, 3)
    CONFIG_GLOBAL_PROPERTY(int, maxPinRetries, 10)
    CONFIG_GLOBAL_PROPERTY(int, maxPasswordRetries, 30)
    // === END US-004 ===
};

} // namespace caelestia::config
