module Kore.MatchingLogic.ProofSystem.ProofTestUtils
  (GoalId(..), MLProof(..), NewGoalId(..)) where

import           Data.Kore.AST.Common                             (Application (..),
                                                                  Attributes (..),
                                                                  Definition (..),
                                                                  Id (..), Meta,
                                                                  Module (..),
                                                                  ModuleName (..),
                                                                  Pattern (..),
                                                                  Sentence (..),
                                                                  SentenceSymbol (..),
                                                                  Sort (..),
                                                                  Symbol (..),
                                                                  SymbolOrAlias (..),
                                                                  Variable,
                                                                  Object)

import           Kore.MatchingLogic.HilbertProof                  (Proof (..))
import           Kore.MatchingLogic.ProofSystem.Minimal           (MLRule (..))
import           Data.Text.Prettyprint.Doc
import           Data.Kore.MetaML.AST                             (MetaMLPattern)
import           Kore.MatchingLogic.ProofSystem.Minimal.Syntax
import           Data.Kore.Parser.ParserImpl                      (sortParser,
                                                                   unifiedVariableOrTermPatternParser,
                                                                   symbolParser)
import           Kore.MatchingLogic.ProverRepl                    (checkProof, 
                                                                   parseCommand,
                                                                   Command,
                                                                   Parser)
import           Data.Kore.MetaML.MetaToKore
import           Kore.MatchingLogic.ProofSystem.MLProofSystem     (formulaVerifier)
import           Data.Kore.Parser.Parser                  
import           Data.Kore.ASTVerifier.DefinitionVerifier         (verifyAndIndexDefinition)
                                                       

import          Data.Kore.ASTVerifier.AttributesVerifier          (AttributesVerification (..))
import          Kore.MatchingLogic.Error
import          Data.Kore.AST.Kore                                (UnifiedPattern)
import          Text.Parsec.Prim

newtype NewGoalId = NewGoalId Int
newtype GoalId = GoalId Int
    deriving (Eq, Show, Ord)

instance Pretty GoalId where
    pretty (GoalId i) = pretty "goalId:" <> pretty i

type MLProof =
    Proof
        GoalId
        (MLRule
            (Sort Meta)
            (SymbolOrAlias Meta)
            (Variable Meta)
            (MetaMLPattern Variable)
        )
        (MetaMLPattern Variable)

type MLProofCommand = 
    Command 
        GoalId
        (MLRule
            (Sort Meta)
            (SymbolOrAlias Meta)
            (Variable Meta)
            (MetaMLPattern Variable)
        )
        UnifiedPattern
        
{-
 - Parsers for proof object
 - In order to process object level proof objects, we need the  
 - following parsers - 
 -  1. CommandParser: Add/Derive commands need
 -     - Parser Id -> Parser Formula -> Parser (rule id) 
 -     - Use parseCommand :: Parser Id ->  Parser Formula -> Parser Rule
 -
 -  2. RuleParser: Parser different rules     
 -     - Use parseMLRule :: Parser Sort -> Parser Label -> Parser Variable 
 -                          -> Parser Formula
 -  
 -}


goalIdParser                :: Parser GoalId
objectSortParser            :: Parser (Sort          Object)
metaViaObjectSortParser     :: Parser (Sort          Meta)
objectSymbolParser          :: Parser (SymbolOrAlias Object)
metaViaObjectSymbolParser   :: Parser (SymbolOrAlias Meta)
objectVariableParser        :: Parser (Variable      Object)
metaViaObjectVariableParser :: Parser (Variable      Meta)
formulaParser               :: Parser UnifiedPattern
metaViaFormulaParser        :: Parser (MetaMLPattern Variable)
testCommandParser           :: Parser MLProofCommand
testRuleParser              :: Parser (MLRule
                                       (Sort          Meta)
                                       (SymbolOrAlias Meta)
                                       (Variable      Meta)
                                       (MetaMLPattern Variable)
                                       (GoalId)
                                      )

goalIdParser                = do
                                x <- many digitChar
                                return $ GoalId (read x)

objectSortParser            = sortParser Object
metaViaObjectSortParser     = objectSortParser                   >>= return $ patternKoreToMeta
objectSymbolParser          = symbolParser Object
metaViaObjectSymbolParser   = objectSymbolParser                 >>= return $ patternKoreToMeta
formulaParser               = unifiedVariableOrTermPatternParser
metaViaFormulaParser        = formulaParser                      >>= return $ patternKoreToMeta
objectVariableParser        = variableParser Object
metaViaObjectVariableParser = objectVariableParser               >>= return $ patternKoreToMeta



testRuleParser             = parseMLRule 
                              metaViaObjectSortParser 
                              metaViaObjectSymbolParser
                              metaViaObjectVariableParser 
                              metaViaFormulaParser
                              goalIdParser

testCommandParser          = parseCommand goalIdParser metaViaFormulaParser testRuleParser



testFormulaVerifier :: String -> Either (MLError) ()

testFormulaVerifier moduleStr formula =  
  case (fromKore moduleStr) of 
    Left  _          -> Left MLError
    Right definition -> ( case (verifyAndIndexDefinition DoNotVerifyAttributes definition) of
                            Left  _             -> (Left (MLError))
                            Right indexedModule -> formulaVerifier indexedModule formula)  
