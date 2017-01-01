{-# LANGUAGE OverloadedStrings #-}

module Nauva.Catalog.Elements
    ( pageRoot

    , pageH2
    , pageH3
    , pageH4

    , pageUL
    , pageOL

    , pageParagraph
    , pageBlockquote
    , pageCodeBlock
    , pageElementContainer
    , pageHint
    , pageCode
    ) where


import           Data.Text          (Text)
import           Data.Monoid

import           Nauva.DOM
import           Nauva.Internal.Types
import           Nauva.Internal.Events
import           Nauva.View


pageRoot :: [Element] -> Element
pageRoot = div_ [style_ style]
  where
    style = mkStyle $ do
        margin "0 30px 0 40px"
        maxWidth "64em"
        display flex
        flexFlow row wrap
        padding "48px 0px"



pageH2 :: [Element] -> Element
pageH2 = h2_ [style_ style]
  where
    style = mkStyle $ do
        fontStyle "normal"
        fontWeight "400"
        color "#003B5C"
        fontFamily "'Roboto', sans-serif"
        fontSize "27.648px"
        lineHeight "1.2"
        flexBasis "100%"
        margin "48px 0 0 0"


pageH3 :: [Element] -> Element
pageH3 = h3_ [style_ style]
  where
    style = mkStyle $ do
        fontStyle "normal"
        fontWeight "400"
        color "#003B5C"
        fontFamily "'Roboto', sans-serif"
        fontSize "23.04px"
        lineHeight "1.2"
        flexBasis "100%"
        margin "48px 0 0 0"


pageH4 :: [Element] -> Element
pageH4 = h4_ [style_ style]
  where
    style = mkStyle $ do
        fontStyle "normal"
        fontWeight "400"
        color "#003B5C"
        fontFamily "'Roboto', sans-serif"
        fontSize "19.2px"
        lineHeight "1.2"
        flexBasis "100%"
        margin "16px 0 0 0"


pageParagraph :: [Element] -> Element
pageParagraph = p_ [style_ style]
  where
    style = mkStyle $ do
        fontStyle "normal"
        fontWeight "400"
        color "#333333"
        fontFamily "'Roboto', sans-serif"
        fontSize "16px"
        lineHeight "1.44"
        flexBasis "100%"
        margin "16px 0 0 0"



pageBlockquote :: [Element] -> Element
pageBlockquote = blockquote_ [style_ style]
  where
    style = mkStyle $ do
        quotes none
        margin "48px 0 32px -20px"
        padding "0 0 0 20px"
        borderLeft "1px solid #D6D6D6"

        -- blockquote > p
        fontStyle "normal"
        fontWeight "400"
        color "#333333"
        fontFamily "'Roboto', sans-serif"
        fontSize "19.2px"
        lineHeight "1.44"
        flexBasis "100%"
        -- margin "16px 0 0 0"


pageCodeBlock :: Text -> Element
pageCodeBlock s = div_ [style_ pageCodeBlockStyle]
    [ section_ [style_ sectionStyle]
        [ pre_ [style_ preStyle]
            [ code_ [style_ codeStyle]
                [ str_ s
                ]
            ]
        ]
    ]
  where
    pageCodeBlockStyle = mkStyle $ do
        display "flex"
        flexBasis "100%"
        maxWidth "100%"
        flexWrap "wrap"
        margin "24px 0px 0px"
        padding "0px"
        position "relative"

    codeStyle = mkStyle $ do
        fontFamily "'Source Code Pro', monospace"
        fontWeight "400"

    preStyle = mkStyle $ do
        fontStyle "normal"
        fontWeight "400"
        color "rgb(0, 38, 62)"
        fontFamily "Roboto, sans-serif"
        fontSize "14.6059px"
        lineHeight "1.44"
        background "rgb(255, 255, 255)"
        border "none"
        display "block"
        height "auto"
        margin "0px"
        overflow "auto"
        padding "20px"
        whiteSpace "pre"
        width "100%"

    sectionStyle = mkStyle $ do
        fontStyle "normal"
        fontWeight "400"
        color "rgb(51, 51, 51)"
        fontFamily "'Source Code Pro', monospace"
        fontSize "14.6059px"
        lineHeight "1.44"
        display "block"
        width "100%"
        background "rgb(255, 255, 255)"
        border "1px solid rgb(238, 238, 238)"


pageElementContainer :: [Element] -> Element
pageElementContainer = div_ [style_ style]
  where
    style = mkStyle $ do
        background "url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAAAAACoWZBhAAAAF0lEQVQI12P4BAI/QICBFCaYBPNJYQIAkUZftTbC4sIAAAAASUVORK5CYII=)"
        borderRadius "2px"
        border none
        display block
        padding "20px"
        position relative
        width "100%"


pageHint :: [Element] -> Element
pageHint = div_ [style_ pageHintDefaultStyle]
  where
    pageHintDefaultStyle = pageHintStyle "rgb(255, 180, 0)" "rgb(255, 246, 221)" "rgb(255, 239, 170)"
    -- pageHintDirectiveStyle = pageHintStyle "rgb(47, 191, 98)" "rgb(234, 250, 234)" "rgb(187, 235, 200)"

    pageHintStyle fg bg b = mkStyle $ do
        fontStyle "normal"
        fontWeight "400"
        color fg
        fontFamily "Roboto, sans-serif"
        fontSize "16px"
        lineHeight "1.44"
        background bg
        border $ CSSValue $ "1px solid " <> b
        borderRadius "2px"
        padding "20px"
        flexBasis "100%"



pageCode :: [Element] -> Element
pageCode = code_ [style_ style]
  where
    style = mkStyle $ do
        background "#F2F2F2"
        border "1px solid #eee"
        borderRadius "1px"
        display inlineBlock
        fontFamily "'Source Code Pro', monospace"
        lineHeight "1"
        padding "0.12em 0.2em"
        cssTerm "text-indent" "0"


pageUL :: [Element] -> Element
pageUL = ul_ [style_ style]
  where
    style = mkStyle $ do
        width "100%"
        marginLeft "0"
        paddingLeft "2rem"
        fontStyle "normal"
        fontWeight "400"
        -- textRendering "optimizeLegibility"
        -- -webkit-font-smoothing "antialiased"
        -- -moz-osx-font-smoothing "grayscale"
        color "#333333"
        fontFamily "'Roboto', sans-serif"
        fontSize "16px"
        lineHeight "1.44"
        listStyle "disc"
        marginTop "16px"
        marginBottom "0"

pageOL :: [Element] -> Element
pageOL = ol_ [style_ style]
  where
    style = mkStyle $ do
        width "100%"
        marginLeft "0"
        paddingLeft "2rem"
        fontStyle "normal"
        fontWeight "400"
        -- textRendering "optimizeLegibility"
        -- -webkit-font-smoothing "antialiased"
        -- -moz-osx-font-smoothing "grayscale"
        color "#333333"
        fontFamily "'Roboto', sans-serif"
        fontSize "16px"
        lineHeight "1.44"
        listStyle "disc"
        marginTop "16px"
        marginBottom "0"