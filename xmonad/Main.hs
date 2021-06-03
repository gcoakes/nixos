{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}

import qualified Codec.Binary.UTF8.String     as UTF8
import           Control.Monad
import qualified DBus                         as D
import qualified DBus.Client                  as D
import           Data.List
import qualified Data.Map                     as M
import           Data.Maybe
import           Graphics.X11.ExtraTypes.XF86
import           System.Exit                  (exitSuccess)
import           XMonad
import           XMonad.Hooks.DynamicLog      (PP (..), dynamicLogWithPP,
                                               shorten, wrap)
import           XMonad.Hooks.EwmhDesktops    (ewmh, fullscreenEventHook)
import           XMonad.Hooks.FadeInactive    (fadeInactiveLogHook)
import           XMonad.Hooks.ManageDocks
import           XMonad.Hooks.ManageHelpers
import           XMonad.Layout.BinaryColumn
import           XMonad.Layout.Decoration     (Theme (..))
import           XMonad.Layout.Named          (named)
import           XMonad.Layout.NoBorders      (noBorders)
import           XMonad.Layout.Reflect        (reflectHoriz)
import           XMonad.Layout.Spacing        (Border (..), spacingRaw)
import qualified XMonad.StackSet              as W
import qualified XMonad.Util.CustomKeys       as C
import           XMonad.Util.Font             (Align (AlignLeft, AlignRightOffset))
import           XMonad.Util.NamedActions     (addDescrKeys', addName, subtitle,
                                               xMessage, (^++^))
import           XMonad.Util.Scratchpad       (scratchpadManageHook,
                                               scratchpadSpawnActionCustom)

main :: IO ()
main = mkDbusClient >>= main'


main' dbus =
  launch
    . ewmh
    . docks
    . addDescrKeys' ((mod4Mask, xK_F1), xMessage) myKeys
    $ def
      { terminal = myTerminal
      , modMask = mod4Mask
      , workspaces = ["\xf6c9", "\xf6ca", "\xf6cb", "\xf6cc", "\xf6cd", "\xf6ce"]
      , startupHook = do
        setFullscreenSupported
        spawn "tray-start"
        spawn "xsetroot -cursor_name left_ptr"
        spawn "wallpaper-start"
      , logHook = fadeInactiveLogHook 0.9 <+> polybarLogHook dbus
      , layoutHook = myLayouts
      , manageHook =
          composeAll
            [ manageHook def,
              manageDocks,
              isFullscreen --> doFullFloat,
              scratchpadManageHook $ W.RationalRect 0.25 0.25 0.5 0.5
            ]
      , handleEventHook =
          composeAll
            [ handleEventHook def,
              fullscreenEventHook
            ]
      }
  where
    myKeys conf@XConfig {XMonad.modMask = modm} =
      keySet "Launchers"
        [ key "Terminal" (modm .|. shiftMask, xK_Return) $ spawn (XMonad.terminal conf)
        , key "Apps (Rofi)" (modm, xK_p) $ spawn "rofi -show drun"
        ] ^++^
      keySet "Layouts"
        [ key "Next" (modm, xK_space) $ sendMessage NextLayout
        , key "Reset" (modm .|. shiftMask, xK_space) $ setLayout (XMonad.layoutHook conf)
        ] ^++^
      keySet "Screens" [ key (action m <> show sc) (m .|. modm, k) (screenWorkspace sc >>= flip whenJust (windows . f))
        | (k, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m)  <- [(W.view, 0), (W.shift, shiftMask)]] ^++^
      keySet "Windows"
        [ key "Close focused"   (modm .|. shiftMask, xK_c) kill
        , key "Focus next"      (modm              , xK_j        ) $ windows W.focusDown
        , key "Focus previous"  (modm              , xK_k        ) $ windows W.focusUp
        , key "Focus master"    (modm              , xK_m        ) $ windows W.focusMaster
        , key "Swap master"     (modm              , xK_Return   ) $ windows W.swapMaster
        , key "Swap next"       (modm .|. shiftMask, xK_j        ) $ windows W.swapDown
        , key "Swap previous"   (modm .|. shiftMask, xK_k        ) $ windows W.swapUp
        , key "Shrink master"   (modm              , xK_h        ) $ sendMessage Shrink
        , key "Expand master"   (modm              , xK_l        ) $ sendMessage Expand
        , key "Switch to tile"  (modm              , xK_t        ) $ withFocused (windows . W.sink)
        ] ^++^
      keySet "Workspaces" switchWsById ^++^
      keySet "System"
        [ key "Toggle status bar gap" (modm              , xK_b ) $ sendMessage ToggleStruts
        , key "Logout (quit XMonad)"  (modm .|. shiftMask, xK_q ) $ io exitSuccess
        ] ^++^
      keySet "Audio"
        [ key "Mute"          (0, xF86XK_AudioMute              ) $ spawn $ pactlSetSink "mute" "toggle"
        , key "Lower volume"  (0, xF86XK_AudioLowerVolume       ) $ spawn $ pactlSetSink "volume" "-5%"
        , key "Raise volume"  (0, xF86XK_AudioRaiseVolume       ) $ spawn $ pactlSetSink "volume" "+5%"
        , key "Play / Pause"  (0, xF86XK_AudioPlay              ) $ spawn $ playerctl "play-pause"
        , key "Stop"          (0, xF86XK_AudioStop              ) $ spawn $ playerctl "stop"
        , key "Previous"      (0, xF86XK_AudioPrev              ) $ spawn $ playerctl "previous"
        , key "Next"          (0, xF86XK_AudioNext              ) $ spawn $ playerctl "next"
        ]
      where
      -- mod-[1..9]: Switch to workspace N | mod-shift-[1..9]: Move client to workspace N
      switchWsById =
        [ key (action m <> show i) (m .|. modm, k) (windows $ f i)
            | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
            , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    pactlSetSink attr opt = "pactl set-sink-" <> attr <> " @DEFAULT_SINK@ " <> opt
    playerctl c  = "playerctl --player=spotify,%any " <> c
    key n k a = (k, addName n a)
    keySet s ks = subtitle s : ks
    action m = if m == shiftMask then "Move to " else "Switch to "
    myTerminal = "kitty"
    myTiled = named "Tiled" $ reflectHoriz $ Tall 1 (3 / 100) (4 / 7)
    myLayouts =
      avoidStruts
      . noBorders
      . spacingRaw True (Border 10 10 10 10) True (Border 10 10 10 10) True $
            EitherRatio (BinaryColumn 1.1 100) myTiled ||| Full

------------------------------------------------------------------------
-- Polybar settings (needs DBus client).
--
mkDbusClient :: IO D.Client
mkDbusClient = do
  dbus <- D.connectSession
  D.requestName dbus (D.busName_ "org.xmonad.log")
    [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]
  return dbus

-- Emit a DBus signal on log updates
dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str =
  let opath  = D.objectPath_ "/org/xmonad/Log"
      iname  = D.interfaceName_ "org.xmonad.Log"
      mname  = D.memberName_ "Update"
      signal = D.signal opath iname mname
      body   = [D.toVariant $ UTF8.decodeString str]
  in  D.emit dbus $ signal { D.signalBody = body }

polybarHook :: D.Client -> PP
polybarHook dbus =
  let wrapper c s | s /= "NSP" = wrap ("%{F" <> c <> "} ") " %{F-}" s
                  | otherwise  = mempty
  in  def { ppOutput          = dbusOutput dbus
          , ppCurrent         = wrapper "#458588"
          , ppVisible         = wrapper "#a89984"
          , ppUrgent          = wrapper "#d65d0e"
          , ppHidden          = wrapper "#928374"
          , ppHiddenNoWindows = wrapper "#282828"
          , ppTitle           = wrapper "#ebdbb2" . shorten 90
          }

polybarLogHook dbus = dynamicLogWithPP (polybarHook dbus)

setFullscreenSupported :: X ()
setFullscreenSupported = addSupported ["_NET_WM_STATE", "_NET_WM_STATE_FULLSCREEN"]

addSupported :: [String] -> X ()
addSupported props = withDisplay $ \dpy -> do
  r <- asks theRoot
  a <- getAtom "_NET_SUPPORTED"
  newSupportedList <- mapM (fmap fromIntegral . getAtom) props
  io $ do
    supportedList <- join . maybeToList <$> getWindowProperty32 dpy a r
    changeProperty32 dpy r a aTOM propModeReplace (nub $ newSupportedList ++ supportedList)

-- Custom Layouts
data EitherRatio p l a = EitherRatio (p a) (l a)
  deriving (Show, Read)

instance (LayoutClass p a, LayoutClass l a) => LayoutClass (EitherRatio p l) a where
  runLayout (W.Workspace i (EitherRatio p l) ms) r@(Rectangle rx ry rw rh)
    | rw < rh = do
      (lrs, newP) <- runLayout (W.Workspace i p ms) r
      return (lrs, fmap (`EitherRatio` l) newP)
    | rw >= rh = do
      (lrs, newL) <- runLayout (W.Workspace i l ms) r
      return (lrs, fmap (EitherRatio p) newL)

  doLayout (EitherRatio p l) r@(Rectangle rx ry rw rh) s
    | rw < rh = do
      (lrs, newP) <- doLayout p r s
      return (lrs, fmap (`EitherRatio` l) newP)
    | rw >= rh = do
      (lrs, newL) <- doLayout l r s
      return (lrs, fmap (EitherRatio p) newL)

  handleMessage (EitherRatio p l) msg = do
    mp <- handleMessage p msg
    ml <- handleMessage l msg
    return $ case (mp, ml) of
      (Just np, Just nl) -> Just $ EitherRatio np nl
      (Just np, Nothing) -> Just $ EitherRatio np l
      (Nothing, Just nl) -> Just $ EitherRatio p nl
      _                  -> Nothing

  description (EitherRatio p l) =
    "[ " ++ description p ++ " | " ++ description l ++ " ]"
