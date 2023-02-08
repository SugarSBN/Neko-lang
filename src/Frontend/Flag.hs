module Frontend.Flag where

import qualified Data.Set as S
import Data.List
import Control.Monad

type Flags = S.Set Flag

data Flag = DumpC
          | DumpLLVM         -- ^ \-ddump-llvm
          | DumpASM          -- ^ \-ddump-asm
          | DumpParsed       -- ^ \-ddump-parsed
          | DumpDesugar      -- ^ \-ddump-desugar
          | DumpInfer        -- ^ \-ddump-infer
          | DumpCore         -- ^ \-ddump-core
          | DumpTypes        -- ^ \-ddump-types
          | DumpKinds        -- ^ \-ddump-types
          | DumpStg          -- ^ \-ddump-stg
          | DumpImp          -- ^ \-ddump-imp
          | DumpRenamer      -- ^ \-ddump-rn
          | DumpToFile       -- ^ \-ddump-to-file
          deriving (Eq, Ord, Show)

isSet :: Flags -> Flag -> Bool
isSet = flip S.member

set :: Flags -> Flag -> Flags
set = flip S.insert

unset :: Flags -> Flag -> Flags
unset = flip S.delete

flags :: [(String, Flag)]
flags = [
    ("ddump-parsed"  , DumpParsed), 
    ("ddump-ds"      , DumpDesugar), 
    ("ddump-core"    , DumpCore), 
    ("ddump-infer"   , DumpInfer), 
    ("ddump-types"   , DumpTypes), 
    ("ddump-kinds"   , DumpKinds), 
    ("ddump-stg"     , DumpStg),
    ("ddump-imp"     , DumpImp),
    ("ddump-c"       , DumpC),
    ("ddump-rn"      , DumpRenamer),
    ("ddump-to-file" , DumpToFile)
    ]

matches :: String -> (String, Flag) -> Maybe Flag
matches s (flagstr, flag)
    | ('-' : flagstr) `isPrefixOf` s = Just flag
    | otherwise                      = Nothing

flagOpts :: [String]
flagOpts = fmap fst flags

flagFor :: String -> Maybe Flag
flagFor s = msum $ fmap (matches s) flags
