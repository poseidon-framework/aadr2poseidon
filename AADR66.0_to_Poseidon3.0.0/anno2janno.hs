#!/usr/bin/env stack
{- stack script
 --resolver lts-22.43
 --package text,cassava,bytestring,vector,unordered-containers,parsec
 -}

{-# LANGUAGE OverloadedStrings #-}

import           Control.Applicative    (empty)
import qualified Data.ByteString.Char8  as B8
import qualified Data.ByteString.Lazy   as BL
import           Data.Char              (ord)
import qualified Data.Csv               as Csv
import qualified Data.HashMap.Strict    as HM
import           Data.List
import           Data.Maybe
import qualified Data.Text              as T
import qualified Data.Text.Encoding     as TE
import qualified Data.Vector            as V
import qualified Text.Parsec            as P
import qualified Text.Parsec.Combinator as P
import qualified Text.Parsec.Text       as P

main :: IO ()
main = do
    anno <- readAnno "tmp/v66.1240K.aadr.PUB.anno"
    let testAnno = anno V.! 11888
        janno = anno2janno testAnno
    print janno

readAnno :: FilePath -> IO (V.Vector AnnoRow)
readAnno path = do
    bs <- BL.readFile path
    case Csv.decodeByNameWith (Csv.DecodeOptions $ fromIntegral (ord '\t')) bs of
      Left err     -> fail err
      Right (_, v) -> pure v

-- #### Input data type: AnnoRow #### --
data AnnoRow = AnnoRow {
      _annoGeneticID      :: T.Text
    , _annoFullDate       :: FullDate
    , _annoColumnsHashmap :: Csv.NamedRecord
    }

instance Show AnnoRow where
    show (AnnoRow a b _) = T.unpack a ++ ": " ++ show b

instance Csv.FromNamedRecord AnnoRow where
    parseNamedRecord m = do
        geneticID <- filterLookup m "Genetic ID (suffices: \".DG\" is a high coverage shotgun genome with diploid genotype calls; \".SG\" is a high coverage shotgun genome with diploid genotype calls; \".AG,  .TW, .BY, .AA, .EC, .WGC\"  are Agilent 1240K or Twist Ancient DNA or \"Big Yoruba\" or \"Archaic Admixture\" or \"Exome\" or \"Whole-Genome Capture\" data respectively; each analyzed position is represented by a randomly chosen sequence allowing for combinations when merged (separable by readgroups if possible).  \".HO\" is Affymetrix Human Origins genotype data and \"REF\" is reference haploid data."
        fullDate <- filterLookup m "Full Date One of two formats. (Format 1) 95.4% CI calibrated radiocarbon age (Conventional Radiocarbon Age BP, Lab number) e.g. 2624-2350 calBCE (3990+-40 BP, Ua-35016). (Format 2) Archaeological context range, e.g. 2500-1700 BCE"
        pure $ AnnoRow {
              _annoGeneticID = geneticID
            , _annoFullDate  = fullDate
            , _annoColumnsHashmap = m
            }

filterLookup :: Csv.FromField a => Csv.NamedRecord -> B8.ByteString -> Csv.Parser a
filterLookup m name = maybe empty Csv.parseField $ HM.lookup name m

-- #### Output data type: JannoRow #### --
data JannoRow = JannoRow {
      jPoseidonID        :: T.Text
    , jDateType          :: Maybe T.Text
    , jDateC14Labnr      :: Maybe (ListColumn T.Text)
    , jDateC14UncalBP    :: Maybe (ListColumn Int)
    , jDateC14UncalBPErr :: Maybe (ListColumn Int)
    , jDateBCADStart     :: Maybe Int
    , jDateBCADMedian    :: Maybe Int
    , jDateBCADStop      :: Maybe Int
    --, jAADRColumns       :: Csv.NamedRecord
    }
    deriving Show

newtype ListColumn a = ListColumn {getListColumn :: [a]}
    deriving (Eq, Ord, Show)

instance (Csv.ToField a, Show a) => Csv.ToField (ListColumn a) where
    toField x = B8.intercalate ";" $ map Csv.toField $ getListColumn x

anno2janno :: AnnoRow -> JannoRow
anno2janno anno =
    JannoRow {
        jPoseidonID        = _annoGeneticID anno
      , jDateType          = jDateType'
      , jDateC14Labnr      = Nothing
      , jDateC14UncalBP    = Nothing
      , jDateC14UncalBPErr = Nothing
      , jDateBCADStart     = jDateBCADStart'
      , jDateBCADMedian    = Nothing
      , jDateBCADStop      = jDateBCADStop'
      --, jAADRColumns       = Nothing
      }
    where
        jDateType' = case _annoFullDate anno of
            ArchContextAge ar    -> Just "contextual"
            C14Age _ (OnlyLabcode {}) -> Just "contextual"
            C14Age _ (SingleC14 {}) -> Just "C14"
            --C14Age _ (SingleC14 {}) -> "C14"
            Present              -> Just "modern"
        singleC14s = case _annoFullDate anno of
            C14Age _ c14@(SingleC14 {}) -> [c14]
            _ -> []
        jDateC14Labnr = T.concat <> map (_c14Labcode) singleC14s
        jDateBCADStart' = case _annoFullDate anno of
            ArchContextAge ar -> _arStart ar
            C14Age ar _       -> _arStart ar
            Present           -> Nothing
        jDateBCADStop' = case _annoFullDate anno of
            ArchContextAge ar -> Just $ _arStop ar
            C14Age ar _       -> Just $ _arStop ar
            Present           -> Nothing
        
        

-- #### age parser #### --
-- full date
data FullDate = Present | ArchContextAge AgeRange | C14Age AgeRange C14
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

-- age range
data AgeRange = AgeRange { _arStart :: Maybe Int, _arStop :: Int }
    deriving Show

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
maybe2Bool Nothing  = False

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
parseCE  = do _ <- P.choice [P.string "CE",  P.try (P.string "calCE"),  P.try (P.string "cal CE")];  return CE
parseBP  = do _ <- P.string "BP"; return BP

-- c14
parseC14Age :: P.Parser FullDate
parseC14Age = do
    ageRange <- parseAgeRange
    _ <- P.many P.space
    dates <- parseC14
    _ <- P.many P.space
    _ <- P.eof
    return (C14Age ageRange dates)

data C14 =
      SingleC14 {_c14MeanSd :: (Int, Int), _c14FRE :: Maybe (Int, Int), _c14Labcode :: [T.Text]}
    | Combine {_c14Union :: Maybe C14, _c14Components :: [C14]}
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
    componentC14s <- P.many $ do
        _ <- parseUntilParen
        P.try parseSingleC14 P.<|> parseOnlyLabcode
    _ <- P.optional (P.char ']')
    return (Combine union componentC14s)

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
    meansd <- parseMeanSd
    meansdFRE <- P.optionMaybe $ P.try $ do
        _ <- P.string ","
        _ <- P.many P.space
        parseFRE
    labcodes <- P.option [] $ do
       _ <- P.string ","
       _ <- P.many P.space
       P.sepBy parseLabCode (P.string ", ")
    _ <- parseUntilParen
    _ <- P.char ')'
    return (SingleC14 meansd meansdFRE labcodes)

parseFRE :: P.Parser (Int,Int)
parseFRE = do
    _ <- P.char '['
    _ <- P.optional $ P.string "FRE:"
    (mean,sd) <- parseMeanSd
    _ <- P.char ']'
    return (mean,sd)

parseMeanSd :: P.Parser (Int,Int)
parseMeanSd = do
    mean <- parsePositiveInt
    _ <- P.many P.space
    _ <- P.string "±" P.<|> P.try (P.string "?±") P.<|> P.string "?"
    _ <- P.many P.space
    sd <- parsePositiveInt
    _ <- P.many P.space
    _ <- P.optional (P.string "BP")
    return (mean,sd)

-- #### parser helpers #### --
parsePositiveInt :: P.Parser Int
parsePositiveInt = fromIntegral <$> parseWord

parseWord :: P.Parser Word
parseWord = read <$> parseNumber

parseNumber :: P.Parser [Char]
parseNumber = P.many1 P.digit
