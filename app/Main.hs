{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}

module Main where

import System.Environment
import Data.Monoid
import Shelly
import Data.Time.Format
import Data.Time.LocalTime
import Data.Time.Clock
import Network.HostName
import qualified Data.Text as T
default (T.Text)

drive = run_ (fromText "drive") 
ls' = run_ (fromText "ls")
gpg = run_ (fromText "gpg2")
tar = run_ (fromText "tar")

dthrnow :: IO T.Text
dthrnow = do
  ct <- getCurrentTime
  tz <- getTimeZone ct
  let dthr = utcToLocalTime tz ct
  pure $ T.pack $ formatTime defaultTimeLocale "%d%m%Y-%H%M%S" dthr

main :: IO ()
main = do
  args <- getArgs
  home <- shelly $ get_env "HOME"
  dthr <- dthrnow
  hostname <- getHostName
  case home of
    Just h  -> shelly $ silently $ do
      tar ["-zcvf", tgz, (h <> "/notes")]
      gpg ["--yes", "--user", "ja@px.io", "-ae", tgz]
      drive ["push", tgz <> ".asc"]
      rm (fromText $ tgz)
      rm (fromText $ tgz <> ".asc")
      liftIO $ putStrLn message
        where
          tgz = h <> "/drive/notes/notes-" <> dthr <> "-" <> T.pack hostname <> ".tar.gz"
          message = T.unpack $ tgz <> ".asc is bkp!"
    Nothing -> putStrLn "Oops"
