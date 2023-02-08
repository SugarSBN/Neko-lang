module Frontend.Variables where

import qualified Data.Set as Set
import Frontend.Name
import Frontend.Syntax


class AllVars a where
    allVars :: a -> Set.Set Name

class FreeVars a where
    freeVars :: a -> Set.Set Name

instance AllVars a => AllVars [a] where
    allVars = Set.unions . fmap allVars

instance FreeVars a => FreeVars [a] where
    freeVars = Set.unions . fmap freeVars

instance AllVars Pattern where
    allVars pt = case pt of
        PVar n    -> Set.singleton n
        PCon _ ps -> Set.unions $ fmap allVars ps
        PLit _    -> Set.empty
        PWild     -> Set.empty

instance AllVars Match where
    allVars ex = case ex of
        Match _ rhs -> allVars rhs

instance AllVars Stmt where
    allVars ex = case ex of
        Generator pat x -> allVars pat `Set.union` allVars x
        Qualifier x     -> allVars x

instance AllVars Expr where
    allVars ex = case ex of
        EVar x      -> Set.singleton x
        ELet n v e  -> Set.unions [Set.singleton n, allVars v, allVars e]
        ELam _ e    -> allVars e
        EApp a b    -> allVars a `Set.union` allVars b
        ECase n as  -> allVars n `Set.union` Set.unions (fmap allVars as)
        ELit _      -> Set.empty
        EIf c x y   -> Set.unions [allVars c, allVars x, allVars y]
        EDo xs      -> Set.unions (fmap allVars xs)
        EAnn x _    -> allVars x
        EOp _ x y   -> allVars x `Set.union` allVars y
        EFail       -> Set.empty

instance AllVars Decl where
    allVars (FunDecl bg) = allVars bg
    allVars _ = Set.empty

instance AllVars BindGroup where
    allVars (BindGroup _ pats _ _) = Set.unions (fmap allVars pats)

---------------------------------------------------------------------------------------------

instance FreeVars Expr where
    freeVars ex = case ex of
        EVar x        -> Set.singleton x
        ELet n v e    -> (freeVars e Set.\\ Set.singleton n) `Set.union` freeVars v
        ELam n x      -> freeVars x Set.\\ Set.singleton n
        EApp f xs     -> freeVars f `Set.union` freeVars xs
        ECase e m     -> freeVars e `Set.union` Set.unions (fmap freeVars m)
        ELit _        -> Set.empty
        EIf c x y     -> freeVars c `Set.union` freeVars x `Set.union` freeVars y
        EDo xs        -> Set.unions (fmap freeVars xs)
        EAnn x _      -> freeVars x
        EOp _ x y     -> freeVars x `Set.union` freeVars y
        EFail         -> Set.empty

instance FreeVars Match where
    freeVars ex = case ex of
        Match pats rhs -> freeVars rhs Set.\\ Set.unions (fmap allVars pats)

instance FreeVars Stmt where
    freeVars ex = case ex of
        Generator pat x -> freeVars x Set.\\ allVars pat
        Qualifier x -> freeVars x

instance FreeVars Decl where
    freeVars (FunDecl bg) = freeVars bg
    freeVars _ = Set.empty

instance FreeVars BindGroup where
    freeVars (BindGroup _ pats _ _) = Set.unions (fmap freeVars pats)

---------------------------------------------------------------------------------------------

occursIn :: AllVars a => Name -> a -> Bool
occursIn name ex = name `Set.member` allVars ex

boundVars :: (FreeVars a, AllVars a) => a -> Set.Set Name
boundVars ex = allVars ex Set.\\ freeVars ex

-- Free pattern variables
freePvs :: Pattern -> [Name]
freePvs (PVar a) = [a]
freePvs (PCon _ b) = concatMap freePvs b
freePvs (PLit _) = []
freePvs PWild = []
