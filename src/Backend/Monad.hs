{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Backend.Monad where

import Control.Monad.Except
import Control.Monad.State
import Control.Applicative
import qualified Data.Text.Lazy as L 
import qualified Frontend.Syntax as Syn
import qualified Frontend.Flag as F
-- | Compiler Monad
type Msg = String

type CompilerMonad = 
    ExceptT Msg 
        (StateT CompilerState IO)

newtype CompilerM a = CompilerM {
    runCompiler :: CompilerMonad a
} deriving (
        Functor,
        Applicative,
        Alternative,
        Monad,
        MonadFix,
        MonadPlus,
        MonadIO,
        MonadState CompilerState,
        MonadError Msg
    )

-- | Compiler State
data CompilerState = CompilerState {
    _fname   :: Maybe FilePath,
    _imports :: [FilePath],
    _src     :: Maybe L.Text,
    _ast     :: Maybe Syn.Module,
    _flags   :: F.Flags
    } deriving (Eq, Show)

-- | Initial empty compiler state.
emptyCS :: CompilerState
emptyCS = CompilerState {
    _fname   = Nothing,
    _imports = mempty,
    _src     = Nothing,
    _ast     = Nothing,
    _flags   = mempty
}

-- | Types
type Pos = String

runCompilerM :: CompilerM a -> CompilerState -> IO (Either Msg a, CompilerState)
runCompilerM = runStateT . runExceptT . runCompiler

inIO :: IO a -> CompilerM a 
inIO = CompilerM . liftIO

-- Run CompilerM a if the flag is set
ifSet :: F.Flag -> CompilerM a -> CompilerM ()
ifSet flag m = do
    flags <- gets _flags
    when (F.isSet flags flag) (void m)