#!/usr/bin/env stack
{- stack script
 --resolver lts-22.43
 --package text,cassava,bytestring,vector,unordered-containers,parsec
 -}

{-# LANGUAGE OverloadedStrings #-}

import           Control.Applicative    (empty)
import qualified Data.ByteString.Char8  as B8
import qualified Data.ByteString.Lazy   as BL
import           Data.Char              (ord,isAscii,isAlphaNum)
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
import qualified Data.Text.IO as TIO

--input  = "v66.1240K.aadr.PUB"
--output = "AADR_v66_1240K"
--input  = "v66.2M.aadr.PUB"
--output = "AADR_v66_2M"
--input  = "v66.2M_compatibility.aadr.PUB"
--output = "AADR_v66_2M_compatibility"
--input  = "v66.HO.aadr.PUB"
--output = "AADR_v66_HO"
input  = "v66.compatibility_HO.aadr.PUB"
output = "AADR_v66_HO_compatibility"

main :: IO ()
main = do
    indFile <- readIndFile $ "tmp/" ++  input ++ ".ind"
    nameMap <- readColumnNameMap "aadr_columns_renamed.csv"
    (forwardHeader, anno) <- readAnno nameMap $ "tmp/" ++ input ++ ".anno"
    let janno = V.map anno2janno $ V.zip indFile anno
    writeJanno ("tmp/" ++  output ++ ".janno") forwardHeader janno

readAnno :: ColumnNameMap -> FilePath -> IO (Csv.Header, V.Vector AnnoRow)
readAnno nameMap path = do
    bs <- BL.readFile path
    case Csv.decodeByNameWith (Csv.DecodeOptions $ fromIntegral (ord '\t')) bs of
      Left err     -> fail err
      Right (header, records) -> do
          -- reportHeaderRenamings nameMap header
          -- inefficient to do the renaming on the per-row level, but it's convenient
          let renamedHeader = V.map (\k -> HM.lookupDefault k k nameMap) header
          rows <- V.imapM (parseRenamedWithRow nameMap) records
          pure (renamedHeader, rows)

parseRenamedWithRow :: ColumnNameMap -> Int -> Csv.NamedRecord -> IO AnnoRow
parseRenamedWithRow nameMap i record = do
  let renamed = renameColumns nameMap record
      rowNum = i + 2  -- +1 because imapM is 0-based, +1 because header is line 1
  case Csv.runParser (Csv.parseNamedRecord renamed) of
    Left err -> do
      let gid = fromMaybe "<unknown>" (HM.lookup "AADR_Genetic_ID" renamed)
      fail $ "Error in .anno row " ++ show rowNum
          ++ " (AADR_Genetic_ID = " ++ B8.unpack gid ++ "):\n"
          ++ err
    Right r  -> pure r

reportHeaderRenamings :: ColumnNameMap -> Csv.Header -> IO ()
reportHeaderRenamings nameMap header = do
    putStrLn "Header rename mapping:"
    mapM_ reportOne (V.toList header)
  where
    reportOne k = case HM.lookup k nameMap of
        Nothing -> B8.putStrLn $ color red $ "> [UNCHANGED] " <> k
        Just k' -> B8.putStrLn $ color green $ "> " <> k <> " -> " <> k'

writeJanno :: FilePath -> Csv.Header -> V.Vector JannoRow -> IO ()
writeJanno path forwardHeader rows = do
    let opts = Csv.defaultEncodeOptions { Csv.encDelimiter = fromIntegral (ord '\t') }
        fullHeader = Csv.header (jannoHeader ++ V.toList forwardHeader)
        bs = Csv.encodeByNameWith opts fullHeader (V.toList rows)
    BL.writeFile path bs

-- ### .ind file ### --
data IndFileRow = IndFileRow {
    _iPoseidonID :: T.Text
  , _iSex :: Char
  , _iGroupName :: T.Text
  }

readIndFile :: FilePath -> IO (V.Vector IndFileRow)
readIndFile path = do
    contents <- TIO.readFile path
    V.fromList <$> mapM parseIndLine (filter (not . T.null) $ T.lines contents)

parseIndLine :: T.Text -> IO IndFileRow
parseIndLine line =
    case T.words line of
        [poseidonID, sexTxt, groupName] ->
            case T.unpack sexTxt of
                [sex] -> pure $ IndFileRow poseidonID sex groupName
                _     -> fail $ "Invalid sex field in line: " ++ T.unpack line
        _ -> fail $ "Invalid .ind line: " ++ T.unpack line

-- #### Column name change #### --
data ColumnNameMapRow = ColumnNameMapRow {
    simplifiedName :: B8.ByteString
  , originalName   :: B8.ByteString
  } deriving Show

instance Csv.FromNamedRecord ColumnNameMapRow where
  parseNamedRecord m =
    ColumnNameMapRow
      <$> m Csv..: "Simplified .anno column name"
      <*> m Csv..: "AADR .anno file column name"

type ColumnNameMap = HM.HashMap B8.ByteString B8.ByteString

readColumnNameMap :: FilePath -> IO ColumnNameMap
readColumnNameMap path = do
  bs <- BL.readFile path
  case Csv.decodeByNameWith (Csv.DecodeOptions $ fromIntegral (ord ',')) bs of
    Left err -> fail err
    Right (_, v) -> pure $ HM.fromList [(originalName r, simplifiedName r) | r <- V.toList v]

renameColumns :: ColumnNameMap -> Csv.NamedRecord -> Csv.NamedRecord
renameColumns nameMap = HM.fromList . map (\(k,v) -> (HM.lookupDefault k k nameMap, v)) . HM.toList

-- #### Input data type: AnnoRow #### --
data AnnoRow = AnnoRow {
      _annoGeneticID      :: T.Text
    , _annoSuffix         :: T.Text
    , _annoFullDate       :: FullDate
    , _annoMeanDate       :: Int
    , _annoLongitude      :: Maybe Double
    , _annoLatitude       :: Maybe Double
    , _annoPublication    :: T.Text
    , _annoColumnsHashmap :: Csv.NamedRecord
    } deriving Show

instance Csv.FromNamedRecord AnnoRow where
    parseNamedRecord m = do
        geneticID   <- filterLookup m "AADR_Genetic_ID"
        suffix      <- filterLookup m "AADR_Call_Suffix"
        fullDate    <- filterLookup m "AADR_Date_Full_Info"
        meanDate    <- filterLookup m "AADR_Date_Mean_BP"
        longitude   <- filterLookupOptional m "AADR_Long"
        latitude    <- filterLookupOptional m "AADR_Lat"
        publication <- filterLookup m "AADR_Publication"
        pure $ AnnoRow {
              _annoGeneticID   = geneticID
            , _annoSuffix      = suffix
            , _annoFullDate    = fullDate
            , _annoMeanDate    = meanDate
            , _annoLongitude   = longitude
            , _annoLatitude    = latitude
            , _annoPublication = publication
            , _annoColumnsHashmap = m
            }

filterLookup :: Csv.FromField a => Csv.NamedRecord -> B8.ByteString -> Csv.Parser a
filterLookup m name = maybe empty Csv.parseField $ cleanInput $ HM.lookup name m

filterLookupOptional :: Csv.FromField a => Csv.NamedRecord -> B8.ByteString -> Csv.Parser (Maybe a)
filterLookupOptional m name = maybe (pure Nothing) (\bs -> Just <$> Csv.parseField bs) $ cleanInput $ HM.lookup name m

cleanInput :: Maybe B8.ByteString -> Maybe B8.ByteString
cleanInput Nothing           = Nothing
cleanInput (Just rawInputBS) = transNA rawInputBS
    where
        transNA ".."  = Nothing
        transNA ""    = Nothing
        transNA "n/a" = Nothing
        transNA x     = Just x

-- #### Output data type: JannoRow #### --
data JannoRow = JannoRow {
      jPoseidonID        :: T.Text
    , jGeneticSex        :: Char
    , jGroupName         :: T.Text
    , jDateType          :: T.Text
    , jDateC14Labnr      :: ListColumn T.Text
    , jDateC14UncalBP    :: ListColumn Int
    , jDateC14UncalBPErr :: ListColumn Int
    , jDateBCADStart     :: Maybe Int
    , jDateBCADMedian    :: Int
    , jDateBCADStop      :: Int
    , jLongitude         :: Maybe Double
    , jLatitude          :: Maybe Double
    , jGenotypePloidy    :: T.Text
    , jPublication       :: T.Text
    , jAADRColumns       :: Csv.NamedRecord
    }
    deriving Show

newtype ListColumn a = ListColumn {getListColumn :: [a]}
    deriving (Eq, Ord, Show)
instance (Csv.ToField a, Show a) => Csv.ToField (ListColumn a) where
    toField x = B8.intercalate ";" $ map Csv.toField $ getListColumn x

instance Csv.DefaultOrdered JannoRow where
    headerOrder _ = Csv.header jannoHeader
jannoHeader :: [B8.ByteString]
jannoHeader = [
      "Poseidon_ID"
    , "Genetic_Sex"
    , "Group_Name"
    --, "Individual_ID"
    --, "Species"
    --, "Alternative_IDs", "Alternative_IDs_Context"
    --, "Relation_To", "Relation_Degree", "Relation_Type"
    --, "Collection_ID", "Custodian_Institution"
    --, "Cultural_Era", "Cultural_Era_URL", "Archaeological_Culture", "Archaeological_Culture_URL"
    --, "Country", "Country_ISO"
    --, "Location", "Site",
    , "Latitude", "Longitude"
    , "Date_Type"
    , "Date_C14_Labnr", "Date_C14_Uncal_BP", "Date_C14_Uncal_BP_Err"
    , "Date_BC_AD_Start", "Date_BC_AD_Median", "Date_BC_AD_Stop"
    --, "Chromosomal_Anomalies"
    --, "MT_Haplogroup", "Y_Haplogroup"
    --, "Source_Material"
    --, "Nr_Libraries", "Library_Names"
    --, "Capture_Type", "UDG", "Library_Built",
    , "Genotype_Ploidy"
    --, "Data_Preparation_Pipeline_URL"
    --, "Endogenous", "Nr_SNPs", "Coverage_on_Target_SNPs", "Damage"
    --, "Contamination", "Contamination_Err", "Contamination_Meas"
    --, "Genetic_Source_Accession_IDs"
    --, "Primary_Contact"
    , "Publication"
    --, "Note"
    --, "Keywords"
    ]
        
instance Csv.ToNamedRecord JannoRow where
    toNamedRecord j = explicitNA $ Csv.namedRecord [
          "Poseidon_ID"                     Csv..= jPoseidonID j
        , "Genetic_Sex"                     Csv..= jGeneticSex j
        , "Group_Name"                      Csv..= jGroupName j
        , "Date_Type"                       Csv..= jDateType j
        , "Date_C14_Labnr"                  Csv..= jDateC14Labnr j
        , "Date_C14_Uncal_BP"               Csv..= jDateC14UncalBP j
        , "Date_C14_Uncal_BP_Err"           Csv..= jDateC14UncalBPErr j
        , "Date_BC_AD_Start"                Csv..= jDateBCADStart j
        , "Date_BC_AD_Median"               Csv..= jDateBCADMedian j
        , "Date_BC_AD_Stop"                 Csv..= jDateBCADStop j
        , "Longitude"                       Csv..= jLongitude j
        , "Latitude"                        Csv..= jLatitude j
        , "Genotype_Ploidy"                 Csv..= jGenotypePloidy j
        , "Publication"                     Csv..= jPublication j
        ] `HM.union` jAADRColumns j

explicitNA :: Csv.NamedRecord -> Csv.NamedRecord
explicitNA = HM.map (\x -> if B8.null x then "n/a" else x)

-- #### anno2janno transformation #### --

anno2janno :: (IndFileRow, AnnoRow) -> JannoRow
anno2janno (ind, anno) =
    JannoRow {
                             -- using the .anno data here ensures equal order
        jPoseidonID        = _annoGeneticID anno -- _iPoseidonID ind
      , jGeneticSex        = _iSex ind
      , jGroupName         = _iGroupName ind
      , jDateType          = getDateType $ _annoFullDate anno
      , jDateC14Labnr      = ListColumn $ map getLabCode $ getC14 $ _annoFullDate anno
      , jDateC14UncalBP    = ListColumn $ map (fst . getMeanSD) $ getC14 $ _annoFullDate anno
      , jDateC14UncalBPErr = ListColumn $ map (snd . getMeanSD) $ getC14 $ _annoFullDate anno
      , jDateBCADStart     = fst $ getAgeRange $ _annoFullDate anno
      , jDateBCADMedian    = bp2bcece $ _annoMeanDate anno
      , jDateBCADStop      = snd $ getAgeRange $ _annoFullDate anno
      , jLongitude         = _annoLongitude anno
      , jLatitude          = _annoLatitude anno
      , jGenotypePloidy    = suffix2ploidy $ _annoSuffix anno
      , jPublication       = cleanPubKeys $ _annoPublication anno
      , jAADRColumns       = _annoColumnsHashmap anno
      }

cleanPubKeys :: T.Text -> T.Text
cleanPubKeys = T.filter (\x -> isAlphaNum x && isAscii x)

suffix2ploidy :: T.Text -> T.Text
suffix2ploidy x | T.isSuffixOf "DG" x = "diploid"
                | T.isSuffixOf "SG" x = "diploid"
                | T.isSuffixOf "HO" x = "diploid"
                | otherwise = "haploid"

-- extract age info
getDateType :: FullDate -> T.Text
getDateType Present = "modern"
getDateType x | null (getC14 x) = "contextual"
              | otherwise = "C14"
getC14 :: FullDate -> [C14]
getC14 (ArchContextAge _) = []
getC14 (C14Age _ (One x)) = mapMaybe unwrapProper [x]
getC14 (C14Age _ (Combine (CombineC14 _ xs))) = mapMaybe unwrapProper xs
getC14 Present = []
unwrapProper :: OneC14 -> Maybe C14
unwrapProper (ProperC14 x) = Just x
unwrapProper _ = Nothing
getLabCode :: C14 -> T.Text
getLabCode (C14 _ _ labcodes _) = T.intercalate "/" labcodes
getMeanSD :: C14 -> (Int,Int)
getMeanSD (C14 _ (Just fremeansd) _ _) = fremeansd
getMeanSD (C14 meansd _ _ _) = meansd
getAgeRange :: FullDate -> (Maybe Int, Int)
getAgeRange (ArchContextAge (AgeRange start stop)) = (start, stop)
getAgeRange (C14Age (AgeRange start stop) _) = (start, stop)
getAgeRange Present = (Just 2000, 2000)

-- #### age parser #### --
-- full date
data FullDate = Present | ArchContextAge AgeRange | C14Age AgeRange C14Info
    deriving Show

instance Csv.FromField FullDate where
    parseField bs =
        let raw = TE.decodeUtf8 bs
            fixed = normalizeFullDate raw
        in case P.parse parseFullDate "Full Date" fixed of
            Left err -> fail (show err)
            Right fd -> pure fd

normalizeFullDate :: T.Text -> T.Text
normalizeFullDate x = fromMaybe x (lookup x rules)
rules :: [(T.Text, T.Text)]
rules =
    [ ( "7502-7325 calBCE (8703±27 BP) [R_Combine: TRa-954, TUa-1257, TRa-952, TUa-2106, TRa-951, TRa-953, TUa-2107)]"
      , "7502-7325 calBCE (8703±27 BP) [R_Combine: (TRa-954), (TUa-1257), (TRa-952), (TUa-2106), (TRa-951), (TRa-953), (TUa-2107)]")
    , ( "54-668 CE [union of two dates: (54-130 calCE), (548-668 calCE)]"
      , "54-668 CE")
    , ( "650-1026 calCE [union of two dates: (650-980 calCE), (890-1026 calCE)]"
      , "650-1026 calCE")
    , ( "988-1163 calCE (1065±, EZV-00225)"
      , "988-1163 calCE (EZV-00225)")
    , ( "2271-2039 calBCE (3741±20 BP) (R_Combine: (3770±30, Beta-446187), (3720±25, PSUAMS-7848)]"
      , "2271-2039 calBCE (3741±20 BP) [R_Combine: (3770±30, Beta-446187), (3720±25, PSUAMS-7848)]")
    , ( "3933-3382 calBCE (4875±80 BP, OxA-646), 3951-3641 calBCE (4970±80 BP, OxA-738), 3944-3527 calBCE (4915±80 BP, OxA-739)"
      , "3933-3382 calBCE [(4875±80 BP, OxA-646), (4970±80 BP, OxA-738), (4915±80 BP, OxA-739)]")
    , ( "8282-7608 calBCE (8870±130 BP, OxA-7109 (Ly-612)"
      , "8282-7608 calBCE (8870±130 BP, OxA-7109, Ly-612)")
    , ( "35170-34519 calBCE (ETH-99101.1.1/MAMS-42268(R-EVA-3335)"
      , "35170-34519 calBCE [(ETH-99101.1.1), (MAMS-42268), (R-EVA-3335)]")
    , ( "39956-35756 calBCE (34950±990 BP) [R_Combine: (34290±970-870 BP, GrA-22810), (>35200 BP, OxA-11711)]"
      , "39956-35756 calBCE (34950±990 BP) [R_Combine: (34290±970-870 BP, GrA-22810), (OxA-11711)]")
    , ( "1437-1473 calCE (429±16 BP, MAMS-35124); 1441-1617 calCE (405±21 BP, MAMS-58729)"
      , "1437-1473 calCE [(429±16 BP, MAMS-35124), (405±21 BP, MAMS-58729)]")
    , ( "1516-1810 calCE±40 CE (237±40 BP, LTL20392A)"
      , "1516-1810 calCE (237±40 BP, LTL20392A)")
    , ( "411-381 calBCE (uncalibrated 2330±20 BP)"
      , "411-381 calBCE")
    , ( "1880-1420 calBCE (MAMS-40615*)"
      , "1880-1420 calBCE (MAMS-40615)")
    ]

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
    c14 <- parseC14Info
    _ <- P.many P.space
    _ <- P.eof
    return (C14Age ageRange c14)

data C14Info =
      One OneC14
    | Combine CombineC14
    deriving Show

parseC14Info :: P.Parser C14Info
parseC14Info = P.try (Combine <$> parseCombineC14) P.<|> (One <$> parseOneC14)

data CombineC14 = 
    CombineC14 {
    _c14Union :: Maybe C14,
    _c14Components :: [OneC14]
    } deriving Show

parseCombineC14 :: P.Parser CombineC14
parseCombineC14 = do
    union <- P.optionMaybe parseC14
    _ <- P.many P.space
    _ <- P.char '['
    _ <- parseUntilParen
    componentC14s <- P.many $ do
        _ <- parseUntilParen
        parseOneC14
    _ <- P.optional (P.char ']')
    return (CombineC14 union componentC14s)

parseUntilParen = P.manyTill P.anyChar (P.lookAhead (P.oneOf "()[]"))

data OneC14 = ProperC14 C14 | OnlyLabcode T.Text deriving Show

parseOneC14 :: P.Parser OneC14
parseOneC14 = P.try (ProperC14 <$> parseC14) P.<|> parseOnlyLabcode

parseOnlyLabcode :: P.Parser OneC14
parseOnlyLabcode = do
    _ <- P.char '('
    labcode <- parseLabCode
    _ <- P.char ')'
    return (OnlyLabcode labcode)

parseLabCode :: P.Parser T.Text
parseLabCode = T.pack <$> P.many1 (
          P.alphaNum
    P.<|> P.char '-'
    P.<|> P.char '.'
    P.<|> P.char '/'
    P.<|> P.try (P.string " - " >> return '-')
    P.<|> P.try (P.string " / " >> return '/')
    )

data C14 = C14 {
      _c14MeanSd :: (Int, Int)
    , _c14FRE :: Maybe (Int, Int)
    , _c14Labcode :: [T.Text]
    , _c14Comment :: Maybe T.Text
    } deriving Show

parseC14 :: P.Parser C14
parseC14 = do
    _ <- P.char '('
    meansd <- parseMeanSd
    meansdFRE <- P.optionMaybe $ P.try $ do
        _ <- P.string ","
        _ <- P.many P.space
        parseFRE
    labcodes <- P.option [] $ do
        _ <- P.string ","
        _ <- P.many P.space
        P.sepBy parseLabCode (P.string ", " P.<|> P.try (P.string " & "))
    _ <- P.many P.space
    comment <- P.optionMaybe $ P.try $ do
        _ <- P.many P.space
        parseC14Comment
    _ <- parseUntilParen
    _ <- P.char ')'
    return (C14 meansd meansdFRE labcodes comment)

parseFRE :: P.Parser (Int,Int)
parseFRE = do
    _ <- P.char '['
    _ <- P.optional $ P.string "FRE:"
    (mean,sd) <- parseMeanSd
    _ <- P.char ']'
    return (mean,sd)

parseC14Comment :: P.Parser T.Text
parseC14Comment = do
    _ <- P.char '('
    comment <- T.pack <$> parseUntilParen
    _ <- P.char ')'
    return comment

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

-- #### helper functions #### --
parsePositiveInt :: P.Parser Int
parsePositiveInt = fromIntegral <$> parseWord

parseWord :: P.Parser Word
parseWord = read <$> parseNumber

parseNumber :: P.Parser [Char]
parseNumber = P.many1 P.digit

color :: B8.ByteString -> B8.ByteString -> B8.ByteString
color c s = c <> s <> reset
green, red, reset :: B8.ByteString
green = "\ESC[32m"
red   = "\ESC[31m"
reset = "\ESC[0m"
