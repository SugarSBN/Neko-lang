
{-# LANGUAGE DeriveGeneric #-}
module Frontend.Name where

import Data.String
import GHC.Generics 
import Data.Hashable
import Control.Monad

data Name = Gen String Integer | Name String
    deriving (Eq, Ord, Show, Read, Generic)

instance IsString Name where
    fromString = Name

instance Hashable Name where

prefix :: String -> Name -> Name
prefix p (Gen nm i) = Gen (p <> nm) i 
prefix p (Name nm) = Name (p <> nm)

unName :: IsString a => Name -> a 
unName (Name s) = fromString s
unName (Gen s n) = fromString (s <> show n)

letters :: [String]
letters = [1..] >>= flip replicateM ['a'..'z']

genNames :: [Name]
genNames = zipWith Gen letters [0..]

class Named a where
    getName :: a -> Name