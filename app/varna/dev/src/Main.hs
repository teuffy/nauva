{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}

module Main (main) where


import           Data.ByteString    (ByteString)
import qualified Data.ByteString    as BS
import           Data.Text          (Text)
import qualified Data.Text.Encoding as T
import           Text.Markdown      (def, MarkdownSettings(..))
import           Text.Markdown.Block
import           Text.Markdown.Inline
import           Data.Conduit
import qualified Data.Conduit.List as CL
import           Data.Functor.Identity (runIdentity)

import qualified Text.Blaze.Html5            as H
import qualified Text.Blaze.Html5.Attributes as A

import           Nauva.Server
import           Nauva.DOM
import           Nauva.Internal.Types
import           Nauva.Internal.Events
import           Nauva.NJS
import           Nauva.View

import           App.Varna.Shared



main :: IO ()
main = do
    runServer $ Config 8000 (\_ -> rootElement 1) Nothing $ do
        H.script H.! A.src "https://use.typekit.net/ubj7dti.js" $ ""
        H.script "try{Typekit.load({ async: true });}catch(e){}"

        H.style $ mconcat
            [ "*, *:before, *:after { box-sizing: inherit; }"
            , "html { box-sizing: border-box; }"
            , "body { margin: 0; }"
            ]