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
import Data.List
import Data.Maybe

data AnnoRow = AnnoRow {
      _annoGeneticID :: T.Text
    , _annoFullDate :: FullDate
    , _annoAdditionalColumns :: Csv.NamedRecord
    }
    
instance Show AnnoRow where
    show (AnnoRow a b _) = T.unpack a ++ ": " ++ show b

data FullDate = 
      Present
    | ArchContextAge AgeRange
    | C14Age {_cRange :: AgeRange --, _cCombinedBP = C14
      , _cDates :: C14
      } 
      deriving Show

instance Csv.FromField FullDate where
    parseField bs =
        case P.parse parseFullDate "Full Date" (TE.decodeUtf8 bs) of
            Left err -> fail (show err)
            Right fd -> pure fd

parseFullDate :: P.Parser FullDate
parseFullDate = parsePresent P.<|> P.try parseC14Age P.<|> P.try parseArchContextAge

parsePresent = do
    _ <- P.string "present"
    _ <- P.many P.space
    _ <- P.eof
    return Present

parseArchContextAge :: P.Parser FullDate
parseArchContextAge = do
    ageRange <- parseAgeRange
    _ <- P.many P.space
    _ <- P.eof
    return (ArchContextAge ageRange)

data AgeRange = AgeRange (Maybe Int) Int deriving Show
parseAgeRange = do
    start <- parseStart
    _ <- P.many P.space
    stop <- P.optionMaybe parseStop
    case (start,stop) of
        -- only one date case
        ((True ,start',Just BCE), Nothing)          -> return (AgeRange Nothing ((-1)*start'))
        ((False,start',Just BCE), Nothing)          -> return (AgeRange (Just ((-1)*start')) ((-1)*start'))
        ((False,start',Just CE ), Nothing)          -> return (AgeRange (Just start') start')
        ((False,start',Just BP ), Nothing)          -> return (AgeRange (Just $ bp2bcece start') (bp2bcece start'))
        -- crossing BC/AD case
        ((False,start',Just BCE), Just (stop',CE))  -> return (AgeRange (Just ((-1)*start')) stop')
        -- regular range case
        ((False,start',Nothing),  Just (stop',BCE)) -> return (AgeRange (Just ((-1)*start')) ((-1)*stop'))
        ((False,start',Nothing),  Just (stop', CE)) -> return (AgeRange (Just start') stop')
        ((False,start',Nothing),  Just (stop', BP)) -> return (AgeRange (Just $ bp2bcece start') (bp2bcece stop'))
        -- anything else
        _ -> error $ show (start,stop)

bp2bcece :: Int -> Int
bp2bcece x = ((-1)*x) + 1950

maybe2Bool :: Maybe a -> Bool
maybe2Bool (Just _) = True
maybe2Bool Nothing = False

parseStart :: P.Parser (Bool,Int,Maybe BCECE)
parseStart = do
    olderThan <- maybe2Bool <$> P.optionMaybe (P.char '>')
    start <- parsePositiveInt
    _ <- P.many P.space
    bcece <- P.optionMaybe parseBCECE
    return (olderThan,start,bcece)

parseStop :: P.Parser (Int,BCECE)
parseStop = do
    _ <- P.oneOf "-–"
    _ <- P.many P.space
    stop <- parsePositiveInt
    _ <- P.many P.space
    bcece <- parseBCECE
    return (stop,bcece)



data BCECE = BCE | CE | BP deriving Show
parseBCECE = P.try parseBCE P.<|> parseCE P.<|> parseBP
parseBCE = do _ <- P.choice [P.string "BCE", P.try (P.string "calBCE"), P.try (P.string "cal BCE")]; return BCE
parseCE = do _ <- P.choice [P.string "CE", P.try (P.string "calCE"), P.try (P.string "cal CE")]; return CE
parseBP = do _ <- P.string "BP"; return BP

parseC14Age :: P.Parser FullDate
parseC14Age = do
    ageRange <- parseAgeRange
    _ <- P.many P.space
    dates <- parseC14
    _ <- P.many P.space
    _ <- P.eof
    return (C14Age ageRange dates)

data C14 =
      SingleC14 {
        _c14Mean :: Int
      , _c14Sd :: Int
      , _c14Labcode :: [T.Text]
      }
    | Combine (Maybe C14) [C14]
    | OnlyLabcode T.Text
    deriving Show

parseC14 :: P.Parser C14
parseC14 = P.try parseCombine P.<|> P.try parseSingleC14 P.<|> parseOnlyLabcode

parseCombine :: P.Parser C14
parseCombine = do
    union <- P.optionMaybe parseSingleC14
    _ <- P.many P.space
    _ <- P.char '['
    _ <- parseUntilParen
    _ <- P.many P.space
    inputc14s <- fmap catMaybes $ P.many $ do
        _ <- parseUntilParen
        P.choice
          [ Just <$> P.try parseSingleC14
          , Just <$> P.try parseOnlyLabcode
          , skipParenBlock >> return Nothing
          ]
    _ <- P.optional (P.char ')')
    _ <- P.optional (P.char ']')
    return (Combine union inputc14s)

parseUntilParen = P.manyTill P.anyChar (P.lookAhead (P.oneOf "()[]"))

parseOnlyLabcode :: P.Parser C14
parseOnlyLabcode = do
    _ <- P.char '('
    labcode <- parseLabCode
    _ <- P.char ')'
    return (OnlyLabcode labcode)

parseLabCode :: P.Parser T.Text
parseLabCode = T.pack <$> P.many1 (P.alphaNum P.<|> P.char '-' P.<|> P.char '.')

parseSingleC14 :: P.Parser C14
parseSingleC14 = do
    _ <- P.char '('
    mean <- parsePositiveInt
    _ <- P.string "±" P.<|> P.try (P.string "?±") P.<|> P.string "?"
    sd <- parsePositiveInt
    _ <- P.many P.space
    _ <- P.optional (P.string "BP")
    labcodes <- P.option [] $ do 
       _ <- P.string ","
       _ <- P.many P.space
       items <- P.sepBy parseLabItem (P.string ", ")
       return [ code | Just code <- items ]
    _ <- parseUntilParen
    _ <- P.char ')'
    return (SingleC14 mean sd labcodes)

parseLabItem :: P.Parser (Maybe T.Text)
parseLabItem = (Just <$> parseLabCode) P.<|> (skipSquareBlock >> return Nothing)

skipSquareBlock :: P.Parser ()
skipSquareBlock = do
    _ <- P.char '['
    _ <- P.manyTill P.anyChar (P.char ']')
    return ()

skipParenBlock :: P.Parser ()
skipParenBlock = do
    _ <- P.char '('
    _ <- P.manyTill P.anyChar (P.char ')')
    return ()

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
    print $ anno V.! 11888