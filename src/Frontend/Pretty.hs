
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}

module Frontend.Pretty where

import Text.PrettyPrint
import Frontend.Name
import Prelude hiding ((<>))
import Text.Parsec.Error (messageString)
import qualified Frontend.Syntax as S
import Frontend.Deconstructors
import Data.List
import Frontend.Type

class Pretty p where
    ppr :: Int -> p -> Doc

    {-# INLINE pp #-}
    pp :: p -> Doc
    pp = ppr 0

    {-# INLINE ppg #-}
    ppg :: p -> String
    ppg = render . pp

instance Pretty Name where
    ppr _ (Name x) = text x
    ppr _ (Gen nm i) = pp nm <> integer i

instance Pretty String where
    ppr _ = text

instance Pretty Int where
    ppr _ = int

instance Pretty Integer where
    ppr _ = integer

spaced :: Pretty a => Int -> [a] -> Doc
spaced p = hsep . fmap (ppr p)

parensIf :: Bool -> Doc -> Doc
parensIf True = parens
parensIf False = id

tysig :: Pretty a => Name -> a -> Doc
tysig f ty = pp f <+> "::" <+> pp ty

spaces :: Int -> String
spaces n
    | n <= 0 = ""
    | otherwise = replicate n ' '

indent :: Int -> Doc -> Doc
indent i d = hang (text (spaces i) <> d) i empty

block :: Pretty a => [a] -> Doc
block xs =
    char '{'
    $$ nest 2 (vcat (punctuate semi (fmap pp xs)))
    $$ char '}'

commafy :: [Doc] -> Doc
commafy = hsep . punctuate comma

ppmaybe :: Pretty a => Maybe a -> Doc
ppmaybe = maybe empty pp

banner :: Show a => a -> String
banner x = render $
    text (replicate n '=')
    <+>
    text msg
    <+>
    text (replicate n '=')
    where
        msg = show x
        n = (76 - length msg) `div` 2

instance Pretty S.BinOp where
    ppr p op = case op of
         S.Add -> "+" 
         S.Sub -> "-" 
         S.Mul -> "*" 
         S.Div -> "/" 
         S.Mod -> "%" 
         S.Eq  -> "==" 
         S.Neq -> "!=" 
         S.Lt  -> "<" 
         S.Gt  -> ">"
         S.Le  -> "<=" 
         S.Ge  -> ">=" 
         S.And -> "&&" 
         S.Or  -> "||"

instance Pretty S.Expr where
    ppr p ex = case ex of
        S.EVar x             -> pp x
        S.ELit x             -> pp x
        e@(S.EApp {})        -> parensIf (p > 0) $ ppr (p + 1) f <+> args
                                where
                                    (f, xs) = viewApp e
                                    args = sep $ fmap (ppr (p + 1)) xs
        e@(S.ELam {})        -> parensIf (p > 0) $ char '\\' <> hsep vars <+> "->" <+> body
                                where
                                    body = ppr (p + 1) (viewLam e)
                                    vars = fmap pp (viewVars e)
        S.ECase x alts       -> "case" <+> ppr p x <+> "of" <+> char '{'
                                $$ blk (vcat (punctuate semi brs))
                                $$ char '}'
                                where
                                    blk = nest 2
                                    brs = fmap pp alts
        S.EDo stmts          -> "do" <+> char '{'
                                $$ blk (vcat (punctuate semi brs))
                                $$ char '}'
                                where
                                    blk = nest 2
                                    brs = fmap pp stmts
        S.ELet a b c         -> "let" <+> ppr p a <+> "=" <+> ppr p b <+> "in" <+> ppr p c
        S.EIf a b c          -> hang (text "if" <+> ppr (p + 1) a) 2 (vcat [hang (text "then") 2 (ppr (p + 1) b), hang (text "else") 2 (ppr (p + 1) c)])
        S.EAnn x ty          -> parens $ pp x <+> "::" <+> pp ty
        S.EOp op a b         -> parensIf (p > 0) $ ppr (p + 1) a <+> pp op <+> ppr (p + 1) b
        S.EFail              -> "<<Fail!>>"


instance Pretty S.Stmt where
    ppr _ (S.Generator pat ex) = pp pat <+> "<-" <+> pp ex
    ppr _ (S.Qualifier ex) = pp ex

instance Pretty S.Match where
    ppr p (S.Match pat rhs) = sep (fmap (ppr p) pat) <+> "->" <+> ppr p rhs

instance Pretty S.Literal where
    ppr _ (S.LitInt x) = int x
    ppr _ (S.LitChar x) = quotes $ char x
    -- ppr _ (S.LitString x) = x

instance Pretty S.Pattern where
    ppr p e = case e of
        S.PVar a -> ppr p a
        S.PLit a -> ppr p a
        S.PWild  -> "_"
        S.PCon f xs ->
            let args = fmap (ppr (p + 1)) xs in
                parensIf (not (null args)) $ ppr p f <+> sep args

instance Pretty [S.BindGroup] where
    ppr _ xs = vcat (fmap pp xs)

instance Pretty S.BindGroup where
    ppr p (S.BindGroup f xs ty wh) =
        maybe empty (tysig f) ty
        $+$
        vcat (fmap (prefix . ppMatch) xs)
        $+$
        ppWheres wh
        where
            prefix = (pp f <+>)
            ppMatch (S.Match pat rhs) = sep (fmap (ppr p) pat) <+> "=" <+> ppr p rhs

            ppWheres [] = empty
            ppWheres [[]] = empty
            ppWheres ws = nest 2 $ hang "where" 2 (vcat (fmap ppWhere ws))

            ppWhere [] = empty
            ppWhere ws = vcat (fmap pp ws)

instance Pretty S.Module where
    ppr p prg = ("module" <+> pp nm <+> "where")
                $$ vcat (intersperse "" (fmap pp xs))
                where
                    (S.Module nm xs) = prg

instance Pretty S.Decl where
    ppr p decl = (case decl of
        S.FunDecl a -> ppr p a
        S.TypeDecl f -> pp f
        S.DataDecl con_id args cons ->
            "data" <+> ppr p con_id <+> spaced p args <+>
            "where" $+$ nest 2 (vcat (fmap pp cons))
        S.ClassDecl preds con_id args defs ->
            "class" <+> ppcontext preds <+> ppr p con_id <+> spaced p args <+>
            "where" $+$ nest 2 (vcat (fmap pp defs))
        S.InstDecl preds con_id ty defs ->
            "instance" <+> ppcontext preds <+> ppr p con_id <+> ppr p ty <+>
            "where" $+$ nest 2 (vcat (fmap pp defs))
        ) <+> ";"

instance Pretty S.ConDecl where
    ppr _ (S.ConDecl datacon ty) = tysig datacon ty
    ppr _ (S.RecDecl con fds ty) =
        braces (hcat (punctuate comma (fmap go fds)))
        <+> "->" <+> pp ty
        where
            go (a, b) = pp a <+> ":" <+> pp b

ppexpr :: S.Expr -> String
ppexpr = ppg

ppsdecl :: S.Decl -> String
ppsdecl = ppg

ppmodule :: S.Module -> String
ppmodule = ppg

-- | Types
isArrow :: Type -> Bool
isArrow TArr {} = True
isArrow _ = False

instance Pretty Type where
    ppr p ty = case ty of
        TArr a b -> parensIf (isArrow a) (ppr p a) <+> "->" <+> ppr p b
        TVar a   -> ppr p a
        TCon a | a == AlgTyCon "Unit" -> "()"
        TCon a   -> ppr p a

        TApp a b | a == tyList -> brackets (ppr p b)
        TApp (TApp a b) c | a == tyPair -> parens $ ppr p b <> char ',' <+> ppr p c
        TApp a b
            | isArrow b -> parensIf (p > 0) $ ppr p a <+> parens (ppr (p + 1) b)
            | otherwise -> parensIf (p > 0) $ ppr p a <+> ppr (p + 1) b
        _ -> error "ERROR in <ppr Type>: unhandled case!"

instance Pretty TVar where
    ppr _ (TV x) = pp x

instance Pretty TyCon where
    ppr _ (AlgTyCon x) = pp x
    ppr _ (PrimTyCon x) = pp x <> char '#'

instance Pretty Pred where
    ppr p (IsIn name ty) = pp name <+> ppr p ty

ppcontext :: [Pred] -> Doc
ppcontext [] = empty
ppcontext [pred] = pp pred
ppcontext preds = parens (hcat (punctuate comma (fmap pp preds)))

pptype :: Type -> String
pptype = ppg

pptvar :: TVar -> String
pptvar = ppg

ppsignature :: (Name, Type) -> String
ppsignature (a, b) = render $ pp a <+> "::" <+> pp (pptype b)

pppred :: Pred -> String
pppred = ppg

-- | Kinds
isKArrow :: Kind -> Bool
isKArrow KArr {} = True
isKArrow _ = False

instance Pretty Kind where
    ppr p (KArr a b) = parensIf (isKArrow a) (ppr p a) <+> text "->" <+> ppr p b
    ppr _ KStar = "*"
    ppr _ (KVar s) = pp s
    ppr _ KPrim = "#"

ppkind :: Kind -> String
ppkind = ppg