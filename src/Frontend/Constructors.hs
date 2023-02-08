{-# LANGUAGE OverloadedStrings #-}
module Frontend.Constructors where

import Frontend.Name
import Frontend.Syntax
import Data.Foldable

_paircon, _concon, _nilcon :: Name
_paircon = "Pair"
_concon = "Cons"
_nilcon = "Nil"

mkEApp :: Expr -> [Expr] -> Expr
mkEApp = foldl' EApp

mkELam :: Expr -> [Name] -> Expr
mkELam = foldr ELam

mkPair :: [Expr] -> Expr
mkPair = foldr1 pair
    where
        pair x y = mkEApp (EVar _paircon) [x, y]

mkList :: [Expr] -> Expr
mkList = foldr cons nil
    where
        cons x y = mkEApp (EVar _concon) [x, y]
        nil = EVar _nilcon

mkIf :: Expr -> Expr
mkIf (EIf c x y) = 
    ECase c [
        Match [PCon "True" []] x,
        Match [PCon "False" []] y
    ]
mkIf x = x

