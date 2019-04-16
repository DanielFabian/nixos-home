 
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run
import System.IO
import XMonad.Actions.FloatKeys
import XMonad.Util.EZConfig
import XMonad.Layout.MultiColumns

modKey = mod4Mask

myKeys =
    ("M-p", spawn "rofi -show run"):
    ("M-e", spawn "brave"):
    ("M-c", spawn "code"):
    -- moving floating window with key
    [(c ++ m ++ k, withFocused $ f (d x))
         | (d, k) <- zip [\a->(a, 0), \a->(0, a), \a->(0-a, 0), \a->(0, 0-a)] ["<Right>", "<Down>", "<Left>", "<Up>"]
         , (f, m) <- zip [keysMoveWindow, \d -> keysResizeWindow d (0, 0)] ["M-", "M-S-"]
         , (c, x) <- zip ["", "C-"] [20, 2]         
    ]

myLayouts = multiCol [2] 3 0.01 (-0.5) ||| layoutHook def

main = do
  xmproc <- spawnPipe "xmobar"
  xmonad $ def {
     terminal = "urxvt"
     , modMask = mod4Mask
     , manageHook = manageDocks <+> manageHook def
     , layoutHook = avoidStruts $ myLayouts
     , handleEventHook = handleEventHook def <+> docksEventHook
     , logHook = dynamicLogWithPP xmobarPP {
         ppOutput = hPutStrLn xmproc
         , ppTitle = xmobarColor "green" "" . shorten 50
         }
  } `additionalKeysP` myKeys