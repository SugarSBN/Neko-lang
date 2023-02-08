module Frontend.Syntax where

import Frontend.Name
import Frontend.Type
import Data.Word

type Constr = Name

data BinOp = Add | Sub | Mul | Div | Mod | Eq | Neq | Lt | Gt | Le | Ge | And | Or
           deriving (Eq, Show)

data Expr = EApp  Expr Expr       -- a b 
          | EVar  Name            -- x
          | ELam  Name Expr       -- \x -> e
          | ELit  Literal         -- 1, 'a'
          | ELet  Name Expr Expr  -- let x = e1 in e2
          | EIf   Expr Expr Expr  -- if e1 then e2 else e3
          | ECase Expr [Match]    -- case e of { p -> e1; ...}
          | EAnn  Expr Type       -- e :: Type
          | EDo   [Stmt]          -- do { ... }
          | EOp   BinOp Expr Expr -- e1 + e2
          | EFail                 -- pattern match failure
          deriving (Eq, Show)

-- | Do notation statement, is divided into 2 classes:
data Stmt = Generator Pattern Expr -- Monadic, pat <- e
          | Qualifier Expr         -- Non-monadic, e
          deriving (Eq, Show)


data Literal = LitInt  Int           -- 1
             | LitChar Char          -- 'a'
             | LitBool Bool          -- True, False
             -- | LitString [Word8]     -- C-stype string, type addr
             deriving (Eq, Show)

-- Inside of case ... of statement, there are pattern matchings:
data Match = Match {
    _macthPat  :: [Pattern],
    _matchBody :: Expr
} deriving (Eq, Show)

data Pattern = PVar Name             -- x
             | PCon Constr [Pattern] -- C x y
             | PLit Literal          -- 3
             | PWild                 -- _
             deriving (Eq, Show)

-- Declarations and implementations should be binded
-- | A binding group is a single line of definition for a function declaration. 
-- | e.g. the following function has two binding groups:
-- | fac :: Int -> Int                # This is function declaration
-- | fac 0 = 1                        # This is binding group 1
-- | fac n = n * fac (n - 1)          # This is binding group 2
data BindGroup = BindGroup {
    _matchName  :: Name,
    _matchPats  :: [Match],
    _matchType  :: Maybe Type,
    _matchWhere :: [[Decl]]
} deriving (Eq, Show)

-- | Declarations
data ConDecl = ConDecl Constr Type                -- T :: a -> T a
             | RecDecl Constr [(Name, Type)] Type -- T :: {label :: a} -> T a
             deriving (Eq, Show, Ord)

data Decl = FunDecl BindGroup                   -- f x = x + 1
          | TypeDecl Type                       -- f :: Int -> Int
          | DataDecl Constr [Name] [ConDecl]    -- data T where {...}
          | ClassDecl [Pred] Name [Name] [Decl] -- class (P) => T where {...}
          | InstDecl [Pred] Name Type [Decl]    -- instance (P) => T where {...}
          | FixityDecl FixitySpec               -- infixl 1 {..}
          deriving (Eq, Show)

data FixitySpec = FixitySpec {
    fixityFix  :: Fixity,
    fixityName :: String
} deriving (Eq, Show)

data Assoc = L | R | N 
    deriving (Eq, Ord, Show)

data Fixity = Infix Assoc Int
            | Prefix Int
            | Postfix Int
            deriving (Eq, Ord, Show)

data Module = Module Name [Decl] -- module T where {..}
    deriving (Eq, Show)

