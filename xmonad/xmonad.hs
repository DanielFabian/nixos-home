import XMonad
import XMonad.Config.KDE

main = xmonad kde4Config // defaultConfig
    { terminal    = "urxvt"
    , modMask     = mod4Mask
    , borderWidth = 3
    }
