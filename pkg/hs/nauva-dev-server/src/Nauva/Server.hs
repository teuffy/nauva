{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}

module Nauva.Server
    ( devServer
    , Message(..)
    ) where


import           Data.Text             (Text)
import qualified Data.Text             as T
import qualified Data.Aeson            as A
import qualified Data.ByteString.Char8 as BS8
import qualified Data.ByteString.Lazy  as LBS
import           Data.Monoid

import qualified Text.Blaze.Html5               as H
-- import qualified Text.Blaze.Html5.Attributes    as A

import           Control.Applicative
import           Control.Concurrent
import           Control.Concurrent.STM
import           Control.Monad
import           Control.Monad.Writer

import           System.Directory
import           System.Environment

import           Nauva.Handle
import           Nauva.Internal.Types
import           Nauva.App

import qualified Network.WebSockets as WS
import           Network.WebSockets.Snap

import qualified Snap.Core           as Snap
import           Snap.Http.Server    (ConfigLog(..), httpServe, setPort, setAccessLog, setErrorLog)
import           Snap.Blaze          (blaze)

import           Prelude



newHeadH :: Handle -> IO HeadH
newHeadH nauvaH = do
    var <- newTVarIO []
    pure $ HeadH
        { hElements = var
        , hReplace = \newElements -> do
            print (length newElements)
            atomically $ writeTVar var newElements
            processSignals nauvaH
        }


newRouterH :: Handle -> IO RouterH
newRouterH nauvaH = do
    var <- newTVarIO (Location "/")
    chan <- newTChanIO

    pure $ RouterH
        { hLocation = (var, chan)
        , hPush = \url -> do
            putStrLn $ "Router hPush: " <> T.unpack url

            atomically $ do
                writeTVar var (Location url)
                writeTChan chan (Location url)

            processSignals nauvaH

            -- This is a hack to send the whole spine to the client when
            -- the user reloads the browser.
            atomically $ do
                currentInstance <- takeTMVar (hInstance nauvaH)
                writeTChan (changeSignal nauvaH) (ChangeRoot currentInstance)
                putTMVar (hInstance nauvaH) currentInstance
        }


devServer :: App -> IO ()
devServer app = do
    nauvaH <- newHandle
    appH <- AppH <$> newHeadH nauvaH <*> newRouterH nauvaH
    render nauvaH (rootElement app appH)

    -- Try to restore the application from the snapshot.
    stateExists <- doesFileExist "snapshot.json"
    when stateExists $ do
        f <- LBS.readFile "snapshot.json"
        case A.decode f of
            Nothing -> pure ()
            Just v -> restoreSnapshot nauvaH v

    -- Persist the state after each change.
    changeSignalCopy <- atomically $ dupTChan (changeSignal nauvaH)
    void $ forkIO $ forever $ do
        m <- atomically $ do
            void $ readTChan changeSignalCopy
            createSnapshot nauvaH
        LBS.writeFile "snapshot.json" (A.encode m)

    port <- (read . head) <$> getArgs

    let config = setPort port . setAccessLog (ConfigIoLog BS8.putStrLn) . setErrorLog (ConfigIoLog BS8.putStrLn) $ mempty
    httpServe config $ foldl1 (<|>)
        [ Snap.path "_nauva" (runWebSocketsSnap (websocketApplication nauvaH appH))
        , blaze index
        ]


websocketApplication :: Handle -> AppH -> WS.PendingConnection -> IO ()
websocketApplication nauvaH appH pendingConnection = do
    conn <- WS.acceptRequest pendingConnection
    WS.forkPingThread conn 5

    locationSignalCopy <- atomically $ dupTChan (snd $ hLocation $ routerH appH)
    void $ forkIO $ forever $ do
        path <- atomically $ do
            locPathname <$> readTChan locationSignalCopy

        WS.sendTextData conn $ A.encode [A.toJSON ("location" :: Text), A.toJSON path, A.Null]

    -- Fork a thread to the background and send the spine to the client
    -- whenever the root instance in the 'Handle' changes.
    changeSignalCopy <- atomically $ dupTChan (changeSignal nauvaH)
    void $ forkIO $ forever $ do
        spine <- atomically $ do
            void $ readTChan changeSignalCopy
            rootInstance <- readTMVar (hInstance nauvaH)
            toSpine rootInstance

        headSpines <- atomically $ do
            elements <- readTVar (hElements $ headH appH)
            instances <- map fst <$> mapM (runWriterT . instantiate (Path [])) elements
            mapM toSpine instances

        WS.sendTextData conn $ A.encode [A.toJSON ("spine" :: Text), A.toJSON spine, A.toJSON headSpines]

    -- Send the current state of the application.
    spine <- atomically $ do
        rootInstance <- readTMVar (hInstance nauvaH)
        toSpine rootInstance

    headSpines <- atomically $ do
        elements <- readTVar (hElements $ headH appH)
        instances <- map fst <$> mapM (runWriterT . instantiate (Path [])) elements
        mapM toSpine instances

    WS.sendTextData conn $ A.encode [A.toJSON ("spine" :: Text), A.toJSON spine, A.toJSON headSpines]

    -- Forever read messages from the WebSocket and process.
    forever $ do
        datum <- WS.receiveData conn
        case A.eitherDecode datum of
            Left e -> do
                putStrLn "Failed to decode message"
                print datum
                print e

            Right msg -> do
                processSignals nauvaH

                case msg of
                    (HookM path value) -> do
                        void $ dispatchHook nauvaH path value

                    (ActionM path _ value) -> do
                        void $ dispatchEvent nauvaH path value

                    (RefM path value) -> do
                        void $ dispatchRef nauvaH path value

                    (LocationM path) -> do
                        hPush (routerH appH) path


data Message
    = HookM !Path !A.Value
    | ActionM !Path !Text !A.Value
    | RefM !Path !A.Value
    | LocationM !Text

instance A.ToJSON Message where
    toJSON (HookM path value)        = A.toJSON [A.String "hook", A.toJSON path, value]
    toJSON (ActionM path text value) = A.toJSON [A.String "action", A.toJSON path, A.toJSON text, value]
    toJSON (RefM path value)         = A.toJSON [A.String "ref", A.toJSON path, value]
    toJSON (LocationM text)          = A.toJSON [A.String "location", A.toJSON text]

instance A.FromJSON Message where
    parseJSON v = do
        list <- A.parseJSON v
        case list of
            (A.String "hook"):path:value:[] -> HookM
                <$> A.parseJSON path
                <*> A.parseJSON value

            (A.String "action"):path:name:value:[] -> ActionM
                <$> A.parseJSON path
                <*> A.parseJSON name
                <*> A.parseJSON value

            (A.String "ref"):path:value:[] -> RefM
                <$> A.parseJSON path
                <*> A.parseJSON value

            (A.String "location"):path:[] -> LocationM
                <$> A.parseJSON path

            _ -> fail "Message"


index :: H.Html
index = H.docTypeHtml $ do
    H.head $ do
        H.title "Nauva Dev Server"

    H.body $ do
        H.div $ ""
