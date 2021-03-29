{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

import qualified Codec.Binary.UTF8.String as UTF8
import Control.Monad
import Data.List
import qualified Data.Map as M
import Data.Maybe
import XMonad
import XMonad.Hooks.DynamicLog
  ( PP (..),
    dynamicLogWithPP,
    wrap,
  )
import XMonad.Hooks.EwmhDesktops
  ( ewmh,
    fullscreenEventHook,
  )
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Layout.BinaryColumn
import XMonad.Layout.Decoration (Theme (..))
import XMonad.Layout.Named (named)
import XMonad.Layout.NoBorders (noBorders)
import XMonad.Layout.Reflect (reflectHoriz)
import XMonad.Layout.Spacing
  ( Border (..),
    spacingRaw,
  )
import qualified XMonad.StackSet as W
import qualified XMonad.Util.CustomKeys as C
import XMonad.Util.EZConfig
import XMonad.Util.Font (Align (AlignLeft, AlignRightOffset))
import XMonad.Util.Scratchpad (scratchpadManageHook, scratchpadSpawnActionCustom)

main =
  launch $
    ewmh $
      docks
        def
          { terminal = myTerminal,
            modMask = mod4Mask,
            layoutHook = myLayouts,
            manageHook =
              composeAll
                [ manageHook def,
                  manageDocks,
                  isFullscreen --> doFullFloat,
                  scratchpadManageHook $ W.RationalRect 0.25 0.25 0.5 0.5
                ],
            handleEventHook =
              composeAll
                [ handleEventHook def,
                  fullscreenEventHook
                ],
            startupHook = setFullscreenSupported
          }
        `additionalKeys` [ ((mod4Mask, xK_Escape), spawn "loginctl lock-session"),
                           ((mod4Mask, xK_b), sendMessage ToggleStruts)
                         ]
  where
    myTerminal = "kitty"
    myTiled = named "Tiled" $ reflectHoriz $ Tall 1 (3 / 100) (4 / 7)
    myLayouts =
      spacingRaw True (Border 10 10 10 10) True (Border 10 10 10 10) True $
        avoidStruts $
          noBorders $
            EitherRatio (BinaryColumn 1.1 100) myTiled ||| Full

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
      _ -> Nothing

  description (EitherRatio p l) =
    "[ " ++ description p ++ " | " ++ description l ++ " ]"

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
