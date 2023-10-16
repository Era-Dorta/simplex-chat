{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Options where

import qualified Data.Attoparsec.ByteString.Char8 as A
import Data.Int (Int64)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Options.Applicative
import Simplex.Chat.Controller (updateStr, versionNumber, versionString)
import Simplex.Chat.Options (ChatOpts (..), CoreChatOpts, coreChatOptsP)
import Simplex.Messaging.Parsers (parseAll)
import Simplex.Messaging.Util (safeDecodeUtf8)

data Publisher = Publisher
  { contactId :: Int64,
    localDisplayName :: Text
  }
  deriving (Eq)

data BroadcastBotOpts = BroadcastBotOpts
  { coreOptions :: CoreChatOpts,
    welcomeMessage :: String
  }

defaultWelcomeMessage = "Hello! I am a broadcast bot.\nI broadcast messages to all connected users."

broadcastBotOpts :: FilePath -> FilePath -> Parser BroadcastBotOpts
broadcastBotOpts appDir defaultDbFileName = do
  coreOptions <- coreChatOptsP appDir defaultDbFileName
  welcomeMessage_ <-
    optional $
      strOption
        ( long "welcome"
            <> metavar "WELCOME"
            <> help "Welcome message to be sent to all connecting users"
        )
  pure
    BroadcastBotOpts
      { coreOptions,
        welcomeMessage = fromMaybe (defaultWelcomeMessage) welcomeMessage_
      }

getBroadcastBotOpts :: FilePath -> FilePath -> IO BroadcastBotOpts
getBroadcastBotOpts appDir defaultDbFileName =
  execParser $
    info
      (helper <*> versionOption <*> broadcastBotOpts appDir defaultDbFileName)
      (header versionStr <> fullDesc <> progDesc "Start chat bot with DB_FILE file and use SERVER as SMP server")
  where
    versionStr = versionString versionNumber
    versionOption = infoOption versionAndUpdate (long "version" <> short 'v' <> help "Show version")
    versionAndUpdate = versionStr <> "\n" <> updateStr

mkChatOpts :: BroadcastBotOpts -> ChatOpts
mkChatOpts BroadcastBotOpts {coreOptions} =
  ChatOpts
    { coreOptions,
      chatCmd = "",
      chatCmdDelay = 3,
      chatServerPort = Nothing,
      optFilesFolder = Nothing,
      showReactions = False,
      allowInstantFiles = True,
      autoAcceptFileSize = 0,
      muteNotifications = True,
      maintenance = False
    }
