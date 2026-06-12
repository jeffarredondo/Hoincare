module Main where

import Linear.V2
import Linear.Metric

-- A point on the Poincaré disk (|z| < 1)
newtype DiskPoint = DiskPoint (V2 Double)
  deriving (Show)

-- Smart constructor that enforces the disk constraint
mkDiskPoint :: Double -> Double -> Maybe DiskPoint
mkDiskPoint x y
  | norm (V2 x y) < 1.0 = Just (DiskPoint (V2 x y))
  | otherwise            = Nothing

-- Poincaré disk distance
poincareDistance :: DiskPoint -> DiskPoint -> Double
poincareDistance (DiskPoint u) (DiskPoint v) =
  let num   = norm (u - v) ** 2
      denom = (1 - norm u ** 2) * (1 - norm v ** 2)
  in acosh (1 + 2 * num / denom)

-- Find the nearest neighbor to a given point
nearestNeighbor :: DiskPoint -> [(String, DiskPoint)] -> Maybe (String, Double)
nearestNeighbor _ [] = Nothing
nearestNeighbor target points =
  let distances = [ (label, poincareDistance target p) | (label, p) <- points ]
      best      = foldl1 (\acc x -> if snd x < snd acc then x else acc) distances
  in Just best

-- Render the disk to ASCII
renderDisk :: [(String, DiskPoint)] -> String
renderDisk points =
  unlines . filter (any (/= ' ')) $ [ [ cellChar x y | x <- [0..width-1 :: Int] ] | y <- [0..height-1 :: Int] ]
  where
    width  = 61 :: Int
    height = 31 :: Int
    radius = 14.0 :: Double

    toDisk :: Int -> Int -> (Double, Double)
    toDisk x y =
      ( (fromIntegral x - fromIntegral width  / 2) / radius
      , (fromIntegral y - fromIntegral height / 2) / radius * (-1.9)
      )

    cellChar :: Int -> Int -> Char
    cellChar x y =
      let (dx, dy) = toDisk x y
          r = sqrt (dx*dx + dy*dy)
      in if r > 1.02      then ' '
         else if r > 0.98 then 'O'
         else findPoint dx dy '.'

    findPoint :: Double -> Double -> Char -> Char
    findPoint dx dy def =
      let matches = [ label
                    | (label, DiskPoint (V2 px py)) <- points
                    , sqrt ((dx-px)**2 + (dy-py)**2) < 0.08
                    ]
      in case matches of
           (l:_) -> case l of
                      (c:_) -> c
                      []    -> def
           []    -> def

main :: IO ()
main = do
  let points = [ ("A", DiskPoint (V2 0.0    0.0 ))
               , ("B", DiskPoint (V2 0.5    0.0 ))
               , ("C", DiskPoint (V2 0.9    0.0 ))
               , ("D", DiskPoint (V2 0.0    0.5 ))
               , ("E", DiskPoint (V2 (-0.5) 0.5 ))
               , ("F", DiskPoint (V2 0.99   0.0))
               , ("G", DiskPoint (V2 0.999  0.0))
               , ("H", DiskPoint (V2 0.9999 0.0))
               ]
  putStrLn "\n=== Hoincare Disk ==="
  putStr (renderDisk points)
  putStrLn "\nDistances from A (origin):"
  case lookup "A" points of
    Nothing -> putStrLn "Point A not found!"
    Just a  -> mapM_ (\(l, p) -> putStrLn $ "  A -> " ++ l ++ ": " ++ show (poincareDistance a p))
                     (drop 1 points)

  putStrLn "\nNearest neighbors:"
  mapM_ (\(l, p) ->
    case nearestNeighbor p (filter (\(l2, _) -> l2 /= l) points) of
      Nothing      -> putStrLn $ "  " ++ l ++ " -> nobody home"
      Just (nb, d) -> putStrLn $ "  " ++ l ++ " -> " ++ nb ++ " (d=" ++ show d ++ ")"
    ) points