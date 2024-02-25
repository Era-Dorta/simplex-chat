{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

module Main where

import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Monad
import qualified Data.Text as T
import Simplex.Chat.Bot
import Simplex.Chat.Controller
import Simplex.Chat.Core
import Simplex.Chat.Options
import Simplex.Chat.Terminal (terminalChatConfig)
import Simplex.Chat.Types
import System.Directory (getAppUserDataDirectory)

main :: IO ()
main = do
  opts <- welcomeGetOpts
  simplexChatCore terminalChatConfig opts myPingBot

welcomeGetOpts :: IO ChatOpts
welcomeGetOpts = do
  appDir <- getAppUserDataDirectory "simplex"
  opts@ChatOpts {coreOptions = CoreChatOpts {dbFilePrefix}} <- getChatOpts appDir "simplex_pingbot"
  putStrLn $ "SimpleX Chat Bot v" ++ versionNumber
  putStrLn $ "db: " <> dbFilePrefix <> "_chat.db, " <> dbFilePrefix <> "_agent.db"
  pure opts

welcomeMessage :: String
welcomeMessage = "Hello! I am ping bot. I will ping you every 24 hours"

myPingBot :: User -> ChatController -> IO ()
myPingBot _user cc = do
  initializeBotAddress cc
  sendChatCmd cc ListContacts >>= \case
    CRContactsList _ cts -> void . forkIO $ do
      void $ forkIO $ forever $ do -- Send ping to existing contacts
        threadDelay (24 * 60 * 60 * 1000000)  -- 24 hours delay
        let cts' = filter broadcastTo cts
        forM_ cts' $ \ct' -> sendMessage cc ct' "Ping"
        where
          broadcastTo Contact {activeConn = Nothing} = False
          broadcastTo _ct'@Contact {activeConn = Just conn@Connection {connStatus}} =
            (connStatus == ConnSndReady || connStatus == ConnReady)
              && not (connDisabled conn)
    r -> putStrLn $ "Error getting contacts list: " <> show r
  race_ (forever $ void getLine) . forever $ do
    (_, _, resp) <- atomically . readTBQueue $ outputQ cc
    case resp of
      CRContactConnected _ ct _ -> do
        contactConnected ct
        sendMessage cc ct welcomeMessage
        void $ forkIO $ forever $ do -- Send ping to new contacts
          threadDelay (24 * 60 * 60 * 1000000)  -- 24 hours delay
          sendMessage cc ct "Ping"
      _ -> pure ()
  where
    contactConnected Contact {localDisplayName} = putStrLn $ T.unpack localDisplayName <> " connected"
