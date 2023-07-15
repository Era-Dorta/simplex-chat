{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Concurrent (forkIO)
import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Monad.Reader
import qualified Data.Text as T
import Options
import Simplex.Chat.Bot
import Simplex.Chat.Controller
import Simplex.Chat.Core
import Simplex.Chat.Messages
import Simplex.Chat.Messages.ChatItemContent
import Simplex.Chat.Options
import Simplex.Chat.Protocol (MsgContent (..))
import Simplex.Chat.Terminal (terminalChatConfig)
import Simplex.Chat.Types
import System.Directory (getAppUserDataDirectory)

main :: IO ()
main = do
  opts <- welcomeGetOpts
  simplexChatCore terminalChatConfig (mkChatOpts opts) Nothing $ broadcastBot opts

welcomeGetOpts :: IO BroadcastBotOpts
welcomeGetOpts = do
  appDir <- getAppUserDataDirectory "simplex"
  opts@BroadcastBotOpts {coreOptions = CoreChatOpts {dbFilePrefix}} <- getBroadcastBotOpts appDir "simplex_anonymous_broadcast_bot"
  putStrLn $ "SimpleX Chat Bot v" ++ versionNumber
  putStrLn $ "db: " <> dbFilePrefix <> "_chat.db, " <> dbFilePrefix <> "_agent.db"
  pure opts

broadcastBot :: BroadcastBotOpts -> User -> ChatController -> IO ()
broadcastBot BroadcastBotOpts {welcomeMessage} _user cc = do
  initializeBotAddress cc
  race_ (forever $ void getLine) . forever $ do
    (_, resp) <- atomically . readTBQueue $ outputQ cc
    case resp of
      CRContactConnected _ ct _ -> do
        contactConnected ct
        sendMessage cc ct welcomeMessage
      CRNewChatItem _ (AChatItem _ SMDRcv (DirectChat ct) ci@ChatItem {content = CIRcvMsgContent mc}) ->
        if allowContent mc
          then do
            sendChatCmd cc "/contacts" >>= \case
              CRContactsList _ cts -> void . forkIO $ do
                let cts' = filter broadcastTo cts
                forM_ cts' $ \ct' -> sendComposedMessage cc ct' Nothing mc
                sendReply $ "Your message was forwarded succesfully!"
              r -> putStrLn $ "Error getting contacts list: " <> show r
          else sendReply "!1 Message is not supported!"
        where
          sendReply = sendComposedMessage cc ct (Just $ chatItemId' ci) . textMsgContent
          allowContent = \case
            MCText _ -> True
            MCLink {} -> True
            MCImage {} -> True
            _ -> False
          broadcastTo ct'@Contact {activeConn = conn@Connection {connStatus}} =
            (connStatus == ConnSndReady || connStatus == ConnReady)
              && not (connDisabled conn)
              && contactId' ct' /= contactId' ct
      _ -> pure ()
  where
    contactConnected ct = putStrLn $ T.unpack (localDisplayName' ct) <> " connected"
