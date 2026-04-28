#!/usr/bin/env stack
{- stack script
 --resolver lts-22.43
 --package text,cassava,bytestring,vector,unordered-containers
 -}

{-# LANGUAGE OverloadedStrings      #-}

import qualified Data.Text as T
import qualified Data.Csv as Csv
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as B8
import qualified Data.Vector as V
import qualified Data.HashMap.Strict as HM
import           Control.Applicative   (empty)
import           Data.Char                     (ord)

data AnnoRow = AnnoRow {
      _annoGeneticID :: T.Text
    --, dating
    , _annoAdditionalColumns :: Csv.NamedRecord
} deriving Show

instance Csv.FromNamedRecord AnnoRow where
    parseNamedRecord m = do
        geneticID <- filterLookup m "Genetic ID (suffices: \".DG\" is a high coverage shotgun genome with diploid genotype calls; \".SG\" is a high coverage shotgun genome with diploid genotype calls; \".AG,  .TW, .BY, .AA, .EC, .WGC\"  are Agilent 1240K or Twist Ancient DNA or \"Big Yoruba\" or \"Archaic Admixture\" or \"Exome\" or \"Whole-Genome Capture\" data respectively; each analyzed position is represented by a randomly chosen sequence allowing for combinations when merged (separable by readgroups if possible).  \".HO\" is Affymetrix Human Origins genotype data and \"REF\" is reference haploid data."
        -- tempPos <- Csv.parseNamedRecord m
        additionalColumns <- pure m -- pure (CsvNamedRecord (m `HM.difference` jannoRefHashMap))
        pure $ AnnoRow {
              _annoGeneticID = geneticID
            , _annoAdditionalColumns = additionalColumns
            }

filterLookup :: Csv.FromField a => Csv.NamedRecord -> B8.ByteString -> Csv.Parser a
filterLookup m name = maybe empty Csv.parseField $ HM.lookup name m

readAnno :: FilePath -> IO (V.Vector AnnoRow)
readAnno path = do
    bs <- BL.readFile path
    case Csv.decodeByNameWith (Csv.DecodeOptions $ fromIntegral (ord '\t')) bs of
      Left err -> fail err
      Right (_, v) -> pure v
      
main :: IO ()
main = do
    anno <- readAnno "tmp/v66.1240K.aadr.PUB.anno"
    print $ V.head anno