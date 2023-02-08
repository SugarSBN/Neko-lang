{-# LANGUAGE BangPatterns #-}
module Frontend.Deconstructors where

import Frontend.Syntax
import Frontend.Name

viewVars :: Expr -> [Name]
viewVars (ELam n a) = n : viewVars a
viewVars _ = []

viewLam :: Expr -> Expr
viewLam (ELam _ a) = viewLam a 
viewLam x = x 

viewApp :: Expr -> (Expr, [Expr])
viewApp = go []
    where
        go :: [Expr] -> Expr -> (Expr, [Expr])
        go !xs (EApp a b) = go (b : xs) a
        go xs f = (f, xs)