{-# LANGUAGE OverloadedStrings #-}

module Frontend.Type where

import Frontend.Name
import Data.String
import Data.Foldable

data Type = TVar TVar
          | TCon TyCon
          | TApp Type Type
          | TArr Type Type
          | TForall [Pred] [TVar] Type
          deriving (Show, Eq, Ord)

data Kind = KStar
          | KArr Kind Kind
          | KPrim
          | KVar Name
          deriving (Show, Eq, Ord)

data TyCon = AlgTyCon { tyId :: Name }
           | PrimTyCon { tyId :: Name }
           deriving (Show, Eq, Ord)

instance IsString TyCon where
    fromString = AlgTyCon . fromString

data Pred = IsIn Name Type
    deriving (Show, Eq, Ord)


-- | Type Variables
newtype TVar = TV {
    tvName :: Name
} deriving (Show, Eq, Ord)

instance IsString TVar where
    fromString x = TV (fromString x)

-- | Alpha Equivalence
class Alpha a where
    aeq :: a -> a -> Bool

instance Alpha TVar where
    aeq _ _ = True

instance Alpha Type where
    aeq (TVar a) (TVar b)     = True
    aeq (TApp a b) (TApp c d) = aeq a c && aeq b d
    aeq (TArr a b) (TArr c d) = aeq a c && aeq b d
    aeq (TCon a) (TCon b)     = a == b
    aeq _ _                   = False

instance Alpha Kind where
    aeq KStar KStar           = True
    aeq KPrim KPrim           = True
    aeq (KArr a b) (KArr c d) = aeq a c && aeq b d
    aeq _ _                   = False

-- | Transformations
predicates :: Type -> [Pred]
predicates (TForall pd _ _) = pd
predicates _ = error "ERROR in <predicates>: Not a Forall type!"

predicate :: [Pred] -> Type -> Type
predicate pd (TForall _ as ty) = TForall pd as ty
predicate _ _ = error "ERROR in <predicate>: Not a Forall type!"

-- | Deconstructors
viewTArr :: Type -> [Type]
viewTArr (TArr a b) = a : viewTArr b
viewTArr a          = [a]

viewTApp :: Type -> [Type]
viewTApp t = go t []
    where
        go :: Type -> [Type] -> [Type]
        go (TApp t1 t2) acc = go t1 (t2 : acc)
        go t acc            = t : acc

typeArity :: Type -> Int
typeArity = length . viewTArr

-- | Constructors
mkTArr :: [Type] -> Type
mkTArr [] = error "ERROR in <mkTArr>: Not defined for empty lists!"
mkTArr [t] = t
mkTArr (t:ts) = TArr t (mkTArr ts)

mkTApp :: TyCon -> [Type] -> Type
mkTApp tcon = foldl' TApp (TCon tcon)

mkTPair :: [Type] -> Type
mkTPair = foldr1 pair
    where
        pair :: Type -> Type -> Type
        pair x y = mkTApp (AlgTyCon "Pair") [x, y]

mkTList :: Type -> Type
mkTList = TApp (TCon (AlgTyCon "List"))

-- | Wried-in Types
tyInt :: Type
tyInt = TCon (PrimTyCon "Int")

tyChar :: Type
tyChar = TCon (PrimTyCon "Char")

tyAddr :: Type
tyAddr = TCon (PrimTyCon "Addr")

tyBool :: Type
tyBool = TCon (AlgTyCon "Bool")

-- []
tyList :: Type
tyList = TCon (AlgTyCon "List")

-- (,)
tyPair :: Type 
tyPair = TCon (AlgTyCon "Pair")

-- ()
tyUnit :: Type
tyUnit = TCon (AlgTyCon "Unit")

-- (->)
tyArrow :: Type
tyArrow = TCon (AlgTyCon "->")