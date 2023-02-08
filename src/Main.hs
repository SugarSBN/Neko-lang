module Main where

import Parser
import Frontend.Pretty

b (Right x) = x 

main :: IO ()
main = do
    s <- readFile "in.neko"
    writeFile "out.neko" (ppg $ b (parse s))
