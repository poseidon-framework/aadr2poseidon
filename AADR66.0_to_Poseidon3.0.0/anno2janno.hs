#!/usr/bin/env stack
{- stack script
 --resolver lts-22.43
 --package text,cassava,bytestring,vector,unordered-containers,parsec
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
import qualified Text.Parsec        as P
import qualified Text.Parsec.Combinator as P
import qualified Data.Text.Encoding as TE
import qualified Text.Parsec.Text as P
-- import qualified Text.Parsec.Number as P

data AnnoRow = AnnoRow {
      _annoGeneticID :: T.Text
    , _annoFullDate :: FullDate
    , _annoAdditionalColumns :: Csv.NamedRecord
} deriving Show

data FullDate = 
      Present
    | ArchContextAge {
        _acrStart :: Int
      , _acrStop :: Int
      }
    | C14Age {
        _cstart :: Int
      , _cstop :: Int
      --, _cCombinedBP = C14
      , _cDates :: [C14]
      }
    deriving Show

instance Csv.FromField FullDate where
    parseField bs =
        case P.parse parseFullDate "Full Date" (TE.decodeUtf8 bs) of
            Left err  -> fail (show err)
            Right fd -> pure fd

parseFullDate :: P.Parser FullDate
parseFullDate = P.try parseArchContextAge P.<|> parseC14Age

parseArchContextAge :: P.Parser FullDate
parseArchContextAge = do
    start <- parsePositiveInt
    _ <- P.char '-'
    stop <- parsePositiveInt
    _ <- P.space
    bcece <- parseBCE P.<|> parseCE
    case bcece of
        BCE -> return (ArchContextAge ((-1)*start) ((-1)*stop))
        CE -> return (ArchContextAge start stop)

data BCECE = BCE | CE
parseBCE = do _ <- P.string "BCE"; return BCE
parseCE = do _ <- P.string "CE"; return CE

data CalBCECE = CalBCE | CalCE
parseCalBCE = do _ <- P.string "calBCE"; return CalBCE
parseCalCE = do _ <- P.string "calCE"; return CalCE

parseC14Age :: P.Parser FullDate
parseC14Age = do
    start <- parsePositiveInt
    _ <- P.char '-'
    stop <- parsePositiveInt
    _ <- P.space
    calbcece <- P.try parseCalBCE P.<|> parseCalCE
    dates <- P.sepBy parseC14 (P.char ' ')
    case calbcece of
        CalBCE -> return (C14Age ((-1)*start) ((-1)*stop) dates)
        CalCE -> return (C14Age start stop dates)

data C14 = C14 {
      _c14Mean :: Int
    , _c14Sd :: Int
    , _c14Labcode :: [T.Text]
} deriving Show

parseC14 :: P.Parser C14
parseC14 = do
    _ <- P.char '('
    mean <- parsePositiveInt
    _ <- P.oneOf "±"
    sd <- parsePositiveInt
    _ <- P.string " BP"
    labcodes <- P.option [] $ do 
       _ <- P.string ", "
       fmap T.pack <$> P.sepBy (P.many1 P.anyChar) (P.string ", ")
    _ <- P.char ')'
    return (C14 mean sd labcodes)

parsePositiveInt :: P.Parser Int
parsePositiveInt = fromIntegral <$> parseWord

parseWord :: P.Parser Word
parseWord = read <$> parseNumber

parseNumber :: P.Parser [Char]
parseNumber = P.many1 P.digit

instance Csv.FromNamedRecord AnnoRow where
    parseNamedRecord m = do
        geneticID <- filterLookup m "Genetic ID (suffices: \".DG\" is a high coverage shotgun genome with diploid genotype calls; \".SG\" is a high coverage shotgun genome with diploid genotype calls; \".AG,  .TW, .BY, .AA, .EC, .WGC\"  are Agilent 1240K or Twist Ancient DNA or \"Big Yoruba\" or \"Archaic Admixture\" or \"Exome\" or \"Whole-Genome Capture\" data respectively; each analyzed position is represented by a randomly chosen sequence allowing for combinations when merged (separable by readgroups if possible).  \".HO\" is Affymetrix Human Origins genotype data and \"REF\" is reference haploid data."
        fullDate <- filterLookup m "Full Date One of two formats. (Format 1) 95.4% CI calibrated radiocarbon age (Conventional Radiocarbon Age BP, Lab number) e.g. 2624-2350 calBCE (3990+-40 BP, Ua-35016). (Format 2) Archaeological context range, e.g. 2500-1700 BCE"
        additionalColumns <- pure m -- pure (CsvNamedRecord (m `HM.difference` jannoRefHashMap))
        pure $ AnnoRow {
              _annoGeneticID = geneticID
            , _annoFullDate  = fullDate
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