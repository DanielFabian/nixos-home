 
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run
import System.IO
import XMonad.Actions.FloatKeys
import XMonad.Util.EZConfig

myWorkspaces = ["1:Main", "2:GTD", "3", "4", "5", "6", "7", "8:Web"]

myKeys =
    -- moving floating window with key
    [(c ++ m ++ k, withFocused $ f (d x))
         | (d, k) <- zip [\a->(a, 0), \a->(0, a), \a->(0-a, 0), \a->(0, 0-a)] ["<Right>", "<Down>", "<Left>", "<Up>"]
         , (f, m) <- zip [keysMoveWindow, \d -> keysResizeWindow d (0, 0)] ["M-", "M-S-"]
         , (c, x) <- zip ["", "C-"] [20, 2]
    ]

main = do
  xmproc <- spawnPipe "xmobar"
  xmonad $ defaultConfig
	{ terminal = "urxvt"
	, modMask = mod4Mask
        , workspaces = myWorkspaces
        , manageHook = manageDocks <+> manageHook defaultConfig
        , layoutHook = avoidStruts $ layoutHook defaultConfig
        , handleEventHook = handleEventHook defaultConfig <+> docksEventHook
        , logHook = dynamicLogWithPP xmobarPP
                    { ppOutput = hPutStrLn xmproc
                    , ppTitle = xmobarColor "green" "" . shorten 50
                    }
   	} `additionalKeysP` myKeys