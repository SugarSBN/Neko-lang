{
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts #-}
module Lexer where

import Frontend.Syntax
import Frontend.Name
import Frontend.Type
import Control.Monad.Except

}

%wrapper "basic"

$digit = 0-9
$alpha = [a-zA-Z]
$eol   = [\n]

tokens :-

  -- Whitespace insensitive
  $eol                          ;
  $white+                       ;

  -- Comments
  "--".*                        ;

  -- Syntax
  let                           { \s -> TokenLet }
  True                          { \s -> TokenTrue }
  False                         { \s -> TokenFalse }
  in                            { \s -> TokenIn }
  if                            { \s -> TokenIf}
  then                          { \s -> TokenThen}
  else                          { \s -> TokenElse}
  case                          { \s -> TokenCase}
  of                            { \s -> TokenOf}
  do                            { \s -> TokenDo }
  module                        { \s -> TokenModule }
  where                         { \s -> TokenWhere }
  $digit+                       { \s -> TokenNum (read s) }
  "->"                          { \s -> TokenArrow }
  "<-"                          { \s -> TokenLArrow}
  \=                            { \s -> TokenEq }
  \\                            { \s -> TokenLambda }
  [\+]                          { \s -> TokenAdd }
  [\-]                          { \s -> TokenSub }
  [\*]                          { \s -> TokenMul }
  [\/]                          { \s -> TokenDiv }
  "%"                           { \s -> TokenMod }
  "=="                          { \s -> TokenEqv }
  "!="                          { \s -> TokenNeq }
  "<"                           { \s -> TokenLt }
  ">"                           { \s -> TokenGt }
  "<="                          { \s -> TokenLe }
  ">="                          { \s -> TokenGe }
  "&&"                          { \s -> TokenAnd }
  "||"                          { \s -> TokenOr } 
  "::"                          { \s -> TokenColon }
  ";"                           { \s -> TokenSemi }
  \(                            { \s -> TokenLParen }
  \)                            { \s -> TokenRParen }
  \{                            { \s -> TokenLBrace }
  \}                            { \s -> TokenRBrace }
  "_"                           { \s -> TokenDash }
  $alpha [$alpha $digit \_ \']* { \s -> TokenSym s }

{

data Token 
  = TokenLet
  | TokenTrue
  | TokenFalse
  | TokenIn
  | TokenLambda
  | TokenEq
  | TokenIf
  | TokenThen
  | TokenElse
  | TokenNum Int
  | TokenSym String
  | TokenArrow
  | TokenLArrow
  | TokenAdd
  | TokenSub
  | TokenMul
  | TokenDiv
  | TokenMod
  | TokenEqv
  | TokenNeq
  | TokenLt
  | TokenGt
  | TokenLe
  | TokenGe
  | TokenAnd
  | TokenOr
  | TokenLParen
  | TokenRParen
  | TokenLBrace
  | TokenRBrace
  | TokenColon
  | TokenSemi
  | TokenEOF
  | TokenCase
  | TokenOf
  | TokenDo
  | TokenDash
  | TokenModule
  | TokenWhere
  deriving (Eq,Show)

scanTokens :: String -> Except String [Token]
scanTokens str = go ('\n',[],str) where 
  go inp@(_,_bs,str) =
    case alexScan inp 0 of
     AlexEOF -> return []
     AlexError _ -> throwError "Invalid lexeme."
     AlexSkip  inp' len     -> go inp'
     AlexToken inp' len act -> do
      res <- go inp'
      let rest = act (take len str)
      return (rest : res)

}