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

data AnnoRow = AnnoRow {
      _annoGeneticID :: T.Text
    , _annoFullDate :: FullDate
    , _annoAdditionalColumns :: Csv.NamedRecord
    } deriving Show

data FullDate = 
      Present
    | ArchContextAge AgeRange
    | C14Age {_cRange :: AgeRange --, _cCombinedBP = C14
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
    ageRange <- parseAgeRange
    return (ArchContextAge ageRange)

data AgeRange = AgeRange (Maybe Int) Int deriving Show
parseAgeRange = do
    start <- parseStart
    stop <- P.optionMaybe parseStop
    case (start,stop) of
        -- only one date case
        ((True ,start',Just BCE), Nothing)          -> return (AgeRange Nothing ((-1)*start'))
        ((False,start',Just BCE), Nothing)          -> return (AgeRange (Just ((-1)*start')) ((-1)*start'))
        ((False,start',Just CE ), Nothing)          -> return (AgeRange (Just start') start')
        -- crossing BC/AD case
        ((False,start',Just BCE), Just (stop',CE))  -> return (AgeRange (Just ((-1)*start')) stop')
        -- regular range case
        ((False,start',Nothing),  Just (stop',BCE)) -> return (AgeRange (Just ((-1)*start')) ((-1)*stop'))
        ((False,start',Nothing),  Just (stop', CE)) -> return (AgeRange (Just start') stop')
        -- anything else
        _ -> error "huhu"

maybe2Bool :: Maybe a -> Bool
maybe2Bool (Just _) = True
maybe2Bool Nothing = False

parseStart :: P.Parser (Bool,Int,Maybe BCECE)
parseStart = do
    olderThan <- maybe2Bool <$> P.optionMaybe (P.char '>')
    start <- parsePositiveInt
    _ <- P.optional P.space
    bcece <- P.optionMaybe parseBCECE
    return (olderThan,start,bcece)

parseStop :: P.Parser (Int,BCECE)
parseStop = do
    _ <- P.optional P.space
    _ <- P.char '-'
    _ <- P.optional P.space
    stop <- parsePositiveInt
    _ <- P.optional P.space
    bcece <- parseBCECE
    return (stop,bcece)

data BCECE = BCE | CE
parseBCECE = P.try parseBCE P.<|> parseCE
parseBCE = do _ <- P.choice [P.string "calBCE", P.string "BCE"]; return BCE
parseCE = do _ <- P.choice [P.string "calCE", P.string "CE"]; return CE

parseC14Age :: P.Parser FullDate
parseC14Age = do
    ageRange <- parseAgeRange
    dates <- P.sepBy parseC14 (P.char ' ')
    return (C14Age ageRange dates)

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