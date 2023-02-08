
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Redundant <$>" #-}

module Frontend.Traversal where

import Frontend.Syntax
import Control.Monad.Identity

decend :: (Expr -> Expr) -> Expr -> Expr
decend f ex = runIdentity (decendM (return . f) ex)

decendM :: (Monad m, Applicative m) => (Expr -> m Expr) -> Expr -> m Expr
decendM f e = case e of 
    EApp a b      -> EApp  <$> decendM f a <*> decendM f b 
    EVar a        -> EVar  <$> pure a
    ELam a b      -> ELam  <$> pure a <*> decendM f b
    ELit n        -> ELit  <$> pure n 
    ELet n a b    -> ELet  <$> pure n <*> decendM f a <*> decendM f b 
    EIf a b c     -> EIf   <$> decendM f a <*> decendM f b <*> decendM f c 
    ECase a xs    -> ECase <$> f a <*> traverse (decendCaseM f) xs
    EAnn a t      -> EAnn  <$> decendM f a <*> pure t
    EOp a b c     -> EOp   <$> pure a <*> decendM f b <*> decendM f c
    EFail         -> pure EFail

decendCaseM :: (Monad m, Applicative m) => (Expr -> m Expr) -> Match -> m Match
decendCaseM f (Match ps a) = Match <$> pure ps <*> decendM f a 

compose :: (Expr -> Expr) -> (Expr -> Expr) -> (Expr -> Expr)
compose f g = decend (f . g)

composeM :: (Monad m, Applicative m) =>
            (Expr -> m Expr) ->
            (Expr -> m Expr) ->
            (Expr -> m Expr)
composeM f g = decendM (f <=< g)

