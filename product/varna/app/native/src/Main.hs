module Main (main) where


import  Nauva.App
import  Nauva.Client
import  Nauva.Product.Varna.Shared



main :: IO ()
main = do
    putStrLn "Native App"
    runClient $ App (root . headH)
