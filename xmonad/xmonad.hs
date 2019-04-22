 
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run
import System.IO
import XMonad.Actions.FloatKeys
import XMonad.Util.EZConfig
import XMonad.Layout.MultiColumns
import XMonad.Layout.GridVariants as GV
import XMonad.Layout.WindowNavigation as WN

modKey = mod4Mask

myKeys =
    ("M-p", spawn "rofi -show run"):
    ("M-e", spawn "brave"):
    ("M-c", spawn "code"):
    ("M-j", sendMessage $ WN.Go WN.D):
    ("M-k", sendMessage $ WN.Go WN.U):
    ("M-h", sendMessage $ WN.Go WN.L):
    ("M-l", sendMessage $ WN.Go WN.R):
    ("M-S-j", sendMessage $ WN.Swap WN.D):
    ("M-S-k", sendMessage $ WN.Swap WN.U):
    ("M-S-h", sendMessage $ WN.Swap WN.L):
    ("M-S-l", sendMessage $ WN.Swap WN.R):
    -- moving floating window with key
    [(c ++ m ++ k, withFocused $ f (d x))
         | (d, k) <- zip [\a->(a, 0), \a->(0, a), \a->(0-a, 0), \a->(0, 0-a)] ["<Right>", "<Down>", "<Left>", "<Up>"]
         , (f, m) <- zip [keysMoveWindow, \d -> keysResizeWindow d (0, 0)] ["M-", "M-S-"]
         , (c, x) <- zip ["", "C-"] [20, 2]         
    ]

myLayouts = 
    GV.SplitGrid GV.L 2 1 (1/2) (4/3) (5/100)
    ||| multiCol [2] 3 0.01 (-0.5) 
    ||| layoutHook def

main = do
  xmproc <- spawnPipe "xmobar"
  xmonad $ def {
     terminal = "urxvt"
     , modMask = mod4Mask
     , manageHook = manageDocks <+> manageHook def
     , layoutHook = avoidStruts $ WN.windowNavigation $ myLayouts
     , handleEventHook = handleEventHook def <+> docksEventHook
     , logHook = dynamicLogWithPP xmobarPP {
         ppOutput = hPutStrLn xmproc
         , ppTitle = xmobarColor "green" "" . shorten 50
         }
  } `additionalKeysP` myKeys