module Coroutine (example) where

import Control.Monad (replicateM_, unless)
import Control.Monad.Cont ( ContT(runContT) )
import Control.Monad.State
  ( MonadIO (..),
    MonadState (get, put),
    MonadTrans (lift),
    StateT,
    evalStateT,
  )
import Control.Monad.Trans.Cont (shiftT)

newtype CoroutineState r m = CoroutineState {getState :: [CoroutineT r m r]}

-- newtype ContT r m a = ContT { runContT :: (a -> m r) -> m r }
type CoroutineT r m a = ContT r (StateT (CoroutineState r m) m) a

-- Used to manipulate the coroutine queue.
getCCs :: (Monad m) => CoroutineT r m [CoroutineT r m r]
getCCs = getState <$> lift get

putCCs :: (Monad m) => [CoroutineT r m r] -> CoroutineT r m ()
putCCs = lift . put . CoroutineState

-- Pop and push coroutines to the queue.
dequeue :: (Monad m) => CoroutineT r m r
dequeue = do
  current_ccs <- getCCs
  case current_ccs of
    [] -> error "Queue is empty"
    (p : ps) -> do
      putCCs ps
      p

queue :: (Monad m) => CoroutineT r m r -> CoroutineT r m ()
queue p = do
  ccs <- getCCs
  putCCs (ccs ++ [p])

-- The interface.
yield :: (Monad m) => CoroutineT r m ()
yield = shiftT $ \k -> do
  queue (lift $ k ())
  dequeue

fork :: (Monad m) => CoroutineT r m () -> CoroutineT r m ()
fork p = shiftT $ \k -> do
  queue (lift $ k ())
  p
  dequeue

-- Exhaust passes control to suspended coroutines repeatedly until there isn't any left.
exhaust :: (Monad m) => CoroutineT r m ()
exhaust = do
  exhausted <- null <$> getCCs
  unless exhausted $ yield >> exhaust

-- Runs the coroutines in the base monad.
runCoroutineT :: (Monad m) => CoroutineT r m r -> m r
runCoroutineT = flip evalStateT (CoroutineState []) . 
  flip runContT return . (<* exhaust)

printOne :: (MonadIO m, Show a) => a -> CoroutineT r m ()
printOne n = do
  liftIO (print n)
  yield

example :: IO ()
example = runCoroutineT $ do
  fork $ replicateM_ 3 (printOne 3)
  fork $ replicateM_ 4 (printOne 4)
  replicateM_ 2 (printOne 2)
