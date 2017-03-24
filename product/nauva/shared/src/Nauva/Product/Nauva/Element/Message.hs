{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}

module Nauva.Product.Nauva.Element.Message
    ( messageEl
    , MessageProps(..)
    , MessageSeverity(..)

    , catalogPage
    ) where


import           Data.Text (Text)
import qualified Data.Text as T

import           Nauva.Internal.Types
import           Nauva.View

import           Nauva.Catalog.TH (nauvaCatalogPage)

import           Prelude hiding (rem)


data MessageSeverity
    = MSError
    | MSWarning
    deriving (Eq)

data MessageProps = MessageProps
    { filePath :: Text
    , messages :: [Text]
    , severity :: MessageSeverity
    }

messageEl :: MessageProps -> Element
messageEl props = div_ [style_ rootStyle]
    [ div_ [style_ filePathStyle] [str_ $ filePath props]
    , div_ [style_ messageStyle] $ map (\x -> div_ [str_ x]) strippedMessages
    ]
  where
    rootStyle :: Style
    rootStyle = mkStyle $ do
        display flex
        flexDirection column
        marginBottom "20px"

    filePathStyle :: Style
    filePathStyle = mkStyle $ do
        fontSize "14px"
        padding (px 8) (px 12)
        case severity props of
            MSError -> backgroundColor "#f23"
            MSWarning -> backgroundColor "#444"
        color "white"
        overflow "hidden"

    messageStyle :: Style
    messageStyle = mkStyle $ do
        fontFamily "'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, Courier, monospace"
        fontSize "12px"
        lineHeight "16px"
        padding (px 12) (px 12)
        whiteSpace "pre"
        backgroundColor "#f1f1f1"
        overflowX "auto"

    strippedMessages = stripLeadingSpaces (messages props)
    stripLeadingSpaces xs = if allHaveALeadingSpace then stripLeadingSpaces (map (T.tail) xs) else xs
      where
        hasLeadingSpace :: Text -> Bool
        hasLeadingSpace x = case T.uncons x of
            Just (' ', _) -> True
            _ -> False

        allHaveALeadingSpace :: Bool
        allHaveALeadingSpace = and $ map hasLeadingSpace xs


catalogPage :: Element
catalogPage = [nauvaCatalogPage|

Messages are warnings or errors which are generated during compilation.
They are shown in the browser window.

```nauva
messageEl $ MessageProps
    { filePath = "/Users/tomc/src/nauva/product/nauva/shared/src/Nauva/Product/Nauva/Element/Message.hs"
    , messages =
        [ "    • No instance for (Term [Text -> Element] Element)"
        , "        arising from a use of ‘div_’"
        ]
    , severity = MSWarning
    }
```

# Another example of `messageEl`

```nauva
noSource: true
---
messageEl $ MessageProps
    { filePath = "…/Product/Nauva/Element/Message.hs"
    , messages =
        [ "    • No instance for (Term [Text -> Element] Element)"
        , "        arising from a use of ‘div_’"
        ]
    , severity = MSError
    }
```
|]
