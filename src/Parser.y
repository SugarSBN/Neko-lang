{
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Parser where

import Lexer
import Frontend.Syntax
import Frontend.Name
import Frontend.Type
import Control.Monad.Except

}

-- Entry point
%name modu

-- Entry point
%name modu

-- Lexer structure 
%tokentype { Token }

-- Parser monad
%monad { Except String } { (>>=) } { return }
%error { parseError }

-- Token Names
%token
    let   { TokenLet }
    true  { TokenTrue }
    false { TokenFalse }
    in    { TokenIn }
    NUM   { TokenNum $$ }
    VAR   { TokenSym $$ }
    if    { TokenIf}
    then  { TokenThen }
    else  { TokenElse }
    case  { TokenCase }
    of    { TokenOf }
    do    { TokenDo }
    module { TokenModule}
    where { TokenWhere}
    '\\'  { TokenLambda }
    '='   { TokenEq }
    '->'  { TokenArrow }
    '<-'  { TokenLArrow }
    ';'   { TokenSemi }

    '+'   { TokenAdd }
    '-'   { TokenSub }
    '*'   { TokenMul }
    '/'   { TokenDiv }
    '%'   { TokenMod }
    '=='  { TokenEqv }
    '!='  { TokenNeq }    
    '<='  { TokenLe }
    '>='  { TokenGe }
    '<'   { TokenLt }
    '>'   { TokenGt }
    '&&'  { TokenAnd }
    '||'  { TokenOr }

    '::'  { TokenColon }
    '('   { TokenLParen }
    ')'   { TokenRParen }
    '{'   { TokenLBrace }
    '}'   { TokenRBrace } 
    '_'   { TokenDash }

-- Operators
%left ';'
%left '::'
%left '->' '<-'
%left '==' '<=' '>=' '!=' '<' '>'
%left '&&' '||'
%left '+' '-'
%left '*' '/' '%'
%%

Module : module VAR where ListDeclaration { Module (Name $2) $4}

ListDeclaration : Declaration      { [$1] }
                | Declaration ';' ListDeclaration { $1 : $3 }

Declaration : BindGroup            { FunDecl $1}

Expr : let VAR '=' Expr in Expr    { EApp (ELam (Name $2) $6) $4 }
     | '\\' VAR '->' Expr          { ELam (Name $2) $4 }
     | Expr '+' Expr               { EOp Add $1 $3}
     | Expr '-' Expr               { EOp Sub $1 $3}
     | Expr '*' Expr               { EOp Mul $1 $3}
     | Expr '/' Expr               { EOp Div $1 $3}
     | Expr '%' Expr               { EOp Mod $1 $3}
     | Expr '==' Expr              { EOp Eq $1 $3}
     | Expr '!=' Expr              { EOp Neq $1 $3}
     | Expr '<=' Expr              { EOp Le $1 $3}
     | Expr '>=' Expr              { EOp Ge $1 $3}
     | Expr '<' Expr               { EOp Lt $1 $3}
     | Expr '>' Expr               { EOp Gt $1 $3}
     | Expr '&&' Expr              { EOp And $1 $3}
     | Expr '||' Expr              { EOp Or $1 $3}
     | if Expr then Expr else Expr { EIf $2 $4 $6}
     | Expr Expr                   { EApp $1 $2}
     | '(' Expr ')'                { $2 }
     | Literal                     { ELit $1 }  
     | VAR                         { EVar (Name $1) }
     | VAR '::' Type               { EAnn (EVar (Name $1)) $3}
     | case Expr of '{' ListMatch '}' { ECase $2 $5}
     | do '{' ListStatement '}'    { EDo $3 }


BindGroup : VAR '::' Type            {BindGroup (Name $1) [] (Just $3) []}
          | VAR '=' Expr             {BindGroup (Name $1) [Match [] $3] Nothing [] }
          | VAR ListPattern '=' Expr {BindGroup (Name $1) [Match $2 $4] Nothing []} 

ListStatement : Statement ';'               { [$1] }
              | Statement ';' ListStatement { $1 : $3 }

Statement : Pattern '<-' Expr      { Generator $1 $3 }
          | Expr                   { Qualifier $1 }

Literal : NUM { LitInt $1 }
        | true { LitBool True }
        | false { LitBool False }
Type : VAR                         { TVar (TV (Name $1))}
     | Type '->' Type              { TArr $1 $3}
     | '(' Type ')'                { $2 }

ListMatch : Match                  { [$1] }
          | Match ';' ListMatch    { $1 : $3 }

Match : ListPattern '->' Expr      { Match $1 $3}

Pattern : VAR                      { PVar (Name $1)}
        | VAR ListPattern          { PCon (Name $1) $2}
        | Literal                  { PLit $1}
        | '_'                      { PWild}
        | '(' Pattern ')'          { $2 }

ListPattern : Pattern              { [$1] }
            | Pattern ListPattern  { $1 : $2 }

{

parseError :: [Token] -> Except String a
parseError (l:ls) = throwError (show (l : ls))
parseError [] = throwError "Unexpected end of Input"

parseTokens :: String -> Either String [Token]
parseTokens = runExcept . scanTokens
    
parse :: String -> Either String Module
parse input = runExcept $ do
  tokenStream <- scanTokens input
  modu tokenStream

}