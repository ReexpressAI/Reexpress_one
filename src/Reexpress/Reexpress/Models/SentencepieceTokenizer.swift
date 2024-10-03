//
//  SentencepieceTokenizer.swift
//  A1Tokenizer
//
//  Created by A on 2/19/23.
//

import Foundation
import NaturalLanguage


enum TokenizerError: Error, LocalizedError {
    case fileError
    
    public var errorDescription: String? {
        switch self {
        case let caughtError:
            return NSLocalizedString("Error: \(String(reflecting: caughtError))", comment: "Error reflection: \(String(reflecting: caughtError))")
        }
    }
}

struct SentencepiecePrompts {
    //static let maxPromptRawCharacterLength = REConstants.DataValidator.maxPromptRawCharacterLength // 250
//    static func getDefaultPrompt() -> String {
//        return "Please classify the following document, explaining your reasoning step-by-step."
//    }
    static func getDefaultPromptWithOptions(topic: String, documentType: String) -> String {
        return "Please classify the \(topic) of the following \(documentType), explaining your reasoning step-by-step."
    }
    static func getDefaultTopicOptions() -> [String] {
        return ["sentiment", "topic", "intent", "grammatical correctness"]
    }
    static func getDefaultDocumentTypeOptions() -> [String] {
        return ["document", "product review", "customer inquiry"]
    }
}

struct SentencepieceConstants {
    static let maxTokenLength = 512 //128 //512
    static let maxCharacterLength = 1024   // Note that with a control file for CJK languages, this may need to be increased. This prevents the word-level HMM from taken an excessive amount of time.
    static let maxSentences = 30  // primarily to avoid runaway input strangely formatted
    
    enum ModelMaxLengthBranches: Int {
        case A = 128
        case B = 256
        case C = 512
        // temp override
//        case A,B,C = 1024 //512 //128
//        case B = 128
//        case C = 128
    }
    enum FastModelMaxLengthBranchesBatchSizes: Int {
        case A = 32
        case B = 16
        case C = 8
    }
    
    enum ModelType {
        //case Billion(branch: Branch)
        case Fast(branch: Branch)
        case Faster(branch: Branch)
        case Fastest(branch: Branch)
        
        enum Branch {
            case A
            case B
            case C
        }
    }
    
    enum ModelGroup: Int, CaseIterable {
        //case Billion
        case Fast
        case Faster
        case Fastest
    }
        
    static func getModelGroupName(modelGroup: ModelGroup) -> String {
        switch modelGroup {
        case .Fast:
            return "Fast I"
        case .Faster:
            return "Faster I"
        case .Fastest:
            return "FastestDraft I"
//        default:
//            return "Not implementd"
        }
    }
    
    static func getModelGroupMaxTokens(modelGroup: ModelGroup) -> Int {
        switch modelGroup {
        case .Fast:
            return 512
        case .Faster:
            return 512
        case .Fastest:
            return 512
//        default:
//            return 512
        }
    }
    
    static func getKeyModelInputDimension(modelGroup: ModelGroup) -> Int {
        let attributesSize = REConstants.KeyModelConstraints.attributesSize
        switch modelGroup {
        case .Fast:
            return 5822 + attributesSize
        case .Faster:
            return 3774 + attributesSize
        case .Fastest:
            return 3262 + attributesSize
        }
    }

    static func getModelParameterCountForDisplay(modelGroup: ModelGroup) -> String {
        switch modelGroup {
        case .Fast:
            return "3.2 billion"
        case .Faster:
            return "1.2 billion"
        case .Fastest:
            return "640 million"
//        default:
//            return "Not available"
        }
    }
    
    enum ForwardType: Int, CaseIterable {
        case onlyEmbeddingForTraining
        case fullTraining
        case inference
        case trainingAndInference
    }
    
    static func getFileSizeEstimateForDisplay(modelGroup: ModelGroup, forwardType: ForwardType) -> String {
        switch modelGroup {
        case .Fast:
            return "488 GB"
        case .Faster:
            return "488 GB"
        case .Fastest:
            return "488 GB"
        }
    }
    
    static func getMaxLength(modelType: ModelType) -> Int {
        switch modelType {
//        case ModelType.Billion(branch: .A):
//            return ModelMaxLengthBranches.A.rawValue
//        case ModelType.Billion(branch: .B):
//            return ModelMaxLengthBranches.B.rawValue
//        case ModelType.Billion(branch: .C):
//            return ModelMaxLengthBranches.C.rawValue
            
        case ModelType.Fast(branch: .A):
            return ModelMaxLengthBranches.A.rawValue
        case ModelType.Fast(branch: .B):
            return ModelMaxLengthBranches.B.rawValue
        case ModelType.Fast(branch: .C):
            return ModelMaxLengthBranches.C.rawValue
        
        case ModelType.Faster(branch: .A):
            return ModelMaxLengthBranches.A.rawValue
        case ModelType.Faster(branch: .B):
            return ModelMaxLengthBranches.B.rawValue
        case ModelType.Faster(branch: .C):
            return ModelMaxLengthBranches.C.rawValue
            
        case ModelType.Fastest(branch: .A):
            return ModelMaxLengthBranches.A.rawValue
        case ModelType.Fastest(branch: .B):
            return ModelMaxLengthBranches.B.rawValue
        case ModelType.Fastest(branch: .C):
            return ModelMaxLengthBranches.C.rawValue
        }
    }
    
    static func getBatchSize(modelType: ModelType) -> Int {
        let fasterModelMultiple = 2
        let fastestModelMultiple = 4
        
        switch modelType {
//        case ModelType.Billion(branch: .A):
//            return 4
//        case ModelType.Billion(branch: .B):
//            return 2
//        case ModelType.Billion(branch: .C):
//            return 1
            
        case ModelType.Fast(branch: .A):
            return FastModelMaxLengthBranchesBatchSizes.A.rawValue
        case ModelType.Fast(branch: .B):
            return FastModelMaxLengthBranchesBatchSizes.B.rawValue
        case ModelType.Fast(branch: .C):
            return FastModelMaxLengthBranchesBatchSizes.C.rawValue
        
        case ModelType.Faster(branch: .A):
            return fasterModelMultiple*FastModelMaxLengthBranchesBatchSizes.A.rawValue
        case ModelType.Faster(branch: .B):
            return fasterModelMultiple*FastModelMaxLengthBranchesBatchSizes.B.rawValue
        case ModelType.Faster(branch: .C):
            return fasterModelMultiple*FastModelMaxLengthBranchesBatchSizes.C.rawValue
            
        case ModelType.Fastest(branch: .A):
            return fastestModelMultiple*FastModelMaxLengthBranchesBatchSizes.A.rawValue
        case ModelType.Fastest(branch: .B):
            return fastestModelMultiple*FastModelMaxLengthBranchesBatchSizes.B.rawValue
        case ModelType.Fastest(branch: .C):
            return fastestModelMultiple*FastModelMaxLengthBranchesBatchSizes.C.rawValue
        }
    }
}

typealias TokenIdType = Int32 //Float32  // This is peculiar as a float (instead of Int), but matches the model conversion.
typealias TokenLMProbabilityType = Double

/**
 The Sentencepiece tokenizer differs from most other tokenization approaches in that it utilizes a unigram LM to determine the sub-word token boundaries. This class is a nearly exact re-implmentation using a simple HMM and the normalization of the built-in function .precomposedStringWithCompatibilityMapping().
 
 Only a small number of edge cases remain, but are too rare to make a difference. For example, `I<SOMEUNKCHAR>ve` is arguably handled incorrectly by the original implementation as it splits with an extraneous insertion of tokenPrefixSymbol after `I`, which would imply that that the tokenization is not reversible barring special handling. This case is handled correctly in our re-implmentation. The remaining edge cases are as follows: The treatment of splits of some emojis, text-based emojis, some URLs, and duplicated characters. The latter are cases where the duplication is otherwise non-identifiable barring a particular convention for the HMM backtrace. For example,
 
 ```bash
         line: -------
         Original implementation: ['▁', '---', '---', '-', '</s>']
         Our re-implementation: ['▁', '-', '---', '---', '</s>']
 ```
 These remaining edge cases are sufficiently rare to justify not adding the additional complexity to match exactly.
 Note that care must be taken if the unkHolderSymbol occurs in the vocab AND byte-level fallback is not used.
 */
class SentencepieceTokenizer {
    
    /// The document token strings are useful for debugging, but are not actually used directly, so documentTokens is Optional to save memory in tight multi-threaded calls when called in a TaskGroup.
    typealias DocumentTokenizationResult = (documentTokens: [String]?, documentTokenIds: [TokenIdType], documentSentencesRanges: [Range<String.Index>], documentSentencesToTokenArrayIndexes: [Int: (Int, Int)], startingIndexOfTruncatedWords: String.Index, startingSentenceArrayIndexOfDocument: Int, documentWithPromptDocumentStartRangeIndex: String.Index)

    
    var tokenToId: [String: TokenIdType]
    var tokenToLM: [String: TokenLMProbabilityType]
    
    //var unicodeScalarTokenToId: [UnicodeScalar: TokenIdType]
    
    let padString = "<pad>"
    let eosString = "</s>"
    let unkString = "<unk>"
    
    let tokenPrefixSymbol = "▁"
//    this actually occurs in the multilingual vocab: let unkHolderSymbol = "Ġ"  // This is not used by the tokenizer directly. It is simply used here as a placeholder for a length 1 token.
    let unkHolderSymbol = "亝"  // This is not used by the tokenizer directly. It is simply used here as a placeholder for a length 1 token. It is important this does not occur in the vocab. (This is a rare Japanese Kanji meaning 'uniform' or 'regular'.)
    
    let padId: TokenIdType = 0
    let eosId: TokenIdType = 1
    let unkId: TokenIdType = 2
//    let prefixSymbolId: TokenIdType = 3 for lm 259 for multi_lm (go through self.tokenToId to access)
    let maxDictionaryKeyLength = 16
    
    var language: NLLanguage = .english // language argument for tokenizers
    var isMultilingual: Bool = false
    
    init(language: NLLanguage = .english, isMultilingual: Bool = false) {
        func getControlStructures(lmControlFilename: String) -> (tokenToId: [String: TokenIdType], tokenToLM: [String: TokenLMProbabilityType]) {
            var localTokenToId: [String: TokenIdType] = [:]
            var localTokenToLM: [String: TokenLMProbabilityType] = [:]

            if let controlUrl = Bundle.main.url(forResource: lmControlFilename, withExtension: "txt"), let vocabTxt = try? String(contentsOf: controlUrl, encoding: .utf8) {
                let stringLines = vocabTxt.split(separator: "\n").map { String($0) }
                
                for line in stringLines {
                    let lineSplit = line.components(separatedBy: NSCharacterSet.whitespaces)
                    let token = lineSplit[0]
                    let tokenId = TokenIdType(lineSplit[1])
                    let lmLogProb = TokenLMProbabilityType(lineSplit[2])
                    
                    // IMPORTANT: In the multi_lm_control.txt, some obscure characters will resolve to the same string token when making the comparisons via Swift String's. There are 36 such cases. Here, the final such occurrence is used, which will have the lowest probability.
                    localTokenToId[token] = tokenId
                    localTokenToLM[token] = lmLogProb
                }
            } else {
                print("Unable to load LM control file.")
            }
            return (tokenToId: localTokenToId, tokenToLM: localTokenToLM)
        }
        var lmControlFilename = "lm_control"
        if isMultilingual {
            lmControlFilename = "multi_lm_control"
        }
        let controlStructures = getControlStructures(lmControlFilename: lmControlFilename)
        self.tokenToId = controlStructures.tokenToId
        self.tokenToLM = controlStructures.tokenToLM
        
        self.language = language
        self.isMultilingual = isMultilingual
        
        if isMultilingual {
            assert(self.tokenToId.count+36 == 248328+36, "Unexpected file format for multi_lm_control.txt.")
            assert(self.tokenToLM["ଙ"] == -20.2801, "Unexpected file format for multi_lm_control.txt.")
            assert(self.tokenToId["ଙ"] == 249999, "Unexpected file format for multi_lm_control.txt.")
        }
        assert(self.tokenToLM[self.unkHolderSymbol] == nil, "The unknown holder symbol occurs in the vocab. This will prevent byte-level fallback (where applicable), and may cause other unexpected behavior.")
    }
    
    /// Useful for debugging. Note: tokenizer should not be shared across threads
    func tokenizeStringBySent(text: String, tokenizer: NLTokenizer) -> [String] {
        var sentences: [String] = []
        tokenizer.string = text

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in

            sentences.append(String(text[tokenRange]))
            return true
        }
        return sentences
    }
    
    
    /// Tokenize word and fall back to byte-level representations for any token not in the vocabulary.
    /// - Parameter word: String.
    /// - Returns: tokens and tokenids
    ///  This differs from tokenizeWord() only in the use of the byte fallback, which can only be used if the original model was used with such a scheme. That is, the resulting bytes must correspond to token id's in the vocab. Note that if max length is extended beyond 512, it may become necessary to pre-tokenize CJK strings to avoid excessive processing time with the HMM.
    func tokenizeWordWithByteLevelFallback(word: String) -> (tokens: [String], tokenIds: [TokenIdType]) {
        let specialTokensOffset: TokenIdType = 3
        // This assumes that .precomposedStringWithCompatibilityMapping has already been applied
//        var wordArray = word.split(separator: "")
        var wordArray = word.unicodeScalars.map { String($0) }
        if wordArray.count > SentencepieceConstants.maxCharacterLength {
            // This is an additional guard to prevent runaway processing on an ill-formed input with no spaces, and/or to handle CJK (no space) languages, which
            // will largely resolve to unk when not using the multilingual LM. Note that typically tokenizeStringByWordUpToMax() should already be called on long sequences, so this serves as an additional guard in case the internal tokenizer did not split the long sequence.
            wordArray = Array(wordArray[0..<SentencepieceConstants.maxCharacterLength])
        }
        let n = wordArray.count
        var wordLattice = [""] + wordArray.map { String($0) }
        var latticeIndexToUnkString = [""] + wordArray.map { String($0) }
        var maxProbLattice: [TokenLMProbabilityType] = Array(repeating: -Double.infinity, count: n+1)
        maxProbLattice[0] = 0.0
        var idLattice: [TokenIdType] = Array(repeating: unkId, count: n+1)
        for i in 0..<n+1 {
            for j in 0..<i {
                if i-j > self.maxDictionaryKeyLength {
                    // The processing time could be explosively large without this check, but this simple HMM is otherwise fast enough in practice since maxDictionaryKeyLength is small in practice (16, as of writing).
                    continue
                }
                let subwordArray = wordArray[j..<i]
                var subwordLen = subwordArray.count
                var subword = String(subwordArray.joined(separator: ""))
                var logProb: TokenLMProbabilityType = -100.0
                if let subwordLogProb = self.tokenToLM[subword] {
                    logProb = subwordLogProb
                } else {
                    subword = unkHolderSymbol
                    subwordLen = 1
                }
                if logProb + maxProbLattice[i - subwordLen] > maxProbLattice[i] {
                    maxProbLattice[i] = logProb + maxProbLattice[i - subwordLen]
                    wordLattice[i] = subword
                    if let subwordId = self.tokenToId[subword] {
                        idLattice[i] = subwordId
                    } else {
                        idLattice[i] = unkId
                        // The following is because we are replacing each unknown *character* with the byte representation:
                        if let finalCharacter = wordArray[j..<i].last {
                            latticeIndexToUnkString[i] = String(finalCharacter)
                        }
                    }
                }
            }
        }
        
        var tokens: [String] = []
        var tokenIds: [TokenIdType] = []
        var i = n
        while i > 0 {
            // In principle, self.tokenToLM[wordLattice[i]] == nil should never occur since we are now initializing maxProbLattice with -Double.infinity
            if wordLattice[i] == unkHolderSymbol || self.tokenToLM[wordLattice[i]] == nil {
                let originalSubword = latticeIndexToUnkString[i]
                
                // If applicable, fall back to byte-level:
                if originalSubword.count > 0 {
                    let utf8Data = Data(originalSubword.utf8)
                    var byteTokens: [String] = []
                    var byteTokenIds: [TokenIdType] = []
                    for oneByte in utf8Data.reversed() {  // Note use of .reversed()
                        byteTokens.append(unkString+String(TokenIdType(oneByte) + specialTokensOffset))
                        byteTokenIds.append(TokenIdType(oneByte) + specialTokensOffset)
                        // Can suspend byte conversion after max has been reached. -1 to account for eos
                        if byteTokenIds.count > (SentencepieceConstants.maxTokenLength-1) {
                            // This particular case should not occur in the current version since we are doing the conversion at the character-level. Keeping this in case the convention is changed.
                            break
                        }
                    }
                    tokens.append(contentsOf: byteTokens)
                    tokenIds.append(contentsOf: byteTokenIds)
                }
                
            } else {
                tokens.append(wordLattice[i])
                tokenIds.append(idLattice[i])
            }
//            i = i - wordLattice[i].count
            // The max() here is just as a safeguard against malformed/unusual control characters. That is, it is just a check to make sure we never fall into an infinite loop.
            i = i - max(1, wordLattice[i].count)
        }
        return (tokens: tokens.reversed(), tokenIds: tokenIds.reversed())
    }
    
    func tokenizeWordWithUnknownTokens(word: String) -> (tokens: [String], tokenIds: [TokenIdType]) {
        // This assumes that .precomposedStringWithCompatibilityMapping has already been applied
        var wordArray = word.split(separator: "")
        if wordArray.count > SentencepieceConstants.maxCharacterLength {
            // This is an additional guard to prevent runaway processing on an ill-formed input with no spaces, and/or to handle CJK (no space) languages, which
            // will largely resolve to unk when not using the multilingual LM. Note that typically tokenizeStringByWordUpToMax() should already be called on long sequences, so this serves as an additional guard in case the internal tokenizer did not split the long sequence.
            wordArray = Array(wordArray[0..<SentencepieceConstants.maxCharacterLength])
        }
        let n = wordArray.count
        var wordLattice = [""] + wordArray.map { String($0) }

        var maxProbLattice: [TokenLMProbabilityType] = Array(repeating: -Double.infinity, count: n+1)
        
        maxProbLattice[0] = 0.0
        var idLattice: [TokenIdType] = Array(repeating: unkId, count: n+1)
        for i in 0..<n+1 {
            for j in 0..<i {
                if i-j > self.maxDictionaryKeyLength {
                    // The processing time could be explosively large without this check, but this simple HMM is otherwise fast enough in practice since maxDictionaryKeyLength is small in practice (16, as of writing).
                    continue
                }
                let subwordArray = wordArray[j..<i]
                var subwordLen = subwordArray.count
                var subword = String(subwordArray.joined(separator: ""))
                var logProb: TokenLMProbabilityType = -100.0
                if let subwordLogProb = self.tokenToLM[subword] {
                    logProb = subwordLogProb
                } else {
                    subword = unkHolderSymbol
                    subwordLen = 1
                }
                if logProb + maxProbLattice[i - subwordLen] > maxProbLattice[i] {
                    maxProbLattice[i] = logProb + maxProbLattice[i - subwordLen]
                    wordLattice[i] = subword
                    if let subwordId = self.tokenToId[subword] {
                        idLattice[i] = subwordId
                    } else {
                        idLattice[i] = unkId
                    }
                }
            }
        }

        var tokens: [String] = []
        var tokenIds: [TokenIdType] = []
        var i = n
        while i > 0 {
            // In principle, self.tokenToLM[wordLattice[i]] == nil should never occur since we are now initializing maxProbLattice with -Double.infinity
            if wordLattice[i] == unkHolderSymbol || self.tokenToLM[wordLattice[i]] == nil {
                if (tokenIds.count == 0) || (tokenIds.count > 0 && tokenIds.last! != unkId) {  // do not double count unk
                    tokens.append(unkString)
                    tokenIds.append(unkId)
                }
            } else {
                tokens.append(wordLattice[i])
                tokenIds.append(idLattice[i])
            }
//            i = i - wordLattice[i].count
            // The max() here is just as a safeguard against malformed/unusual control characters. That is, it is just a check to make sure we never fall into an infinite loop.
            i = i - max(1, wordLattice[i].count)
        }
        return (tokens: tokens.reversed(), tokenIds: tokenIds.reversed())
    }
    
    /// Typically use tokenizeDocumentBySentence() instead to get the sentence boundaries.
    func tokenizeDocument(document: String) async -> (documentTokens: [String], documentTokenIds: [TokenIdType]) {
        
        var documentTokens: [String] = []
        var documentTokenIds: [TokenIdType] = []
        for word in document.components(separatedBy: NSCharacterSet.whitespacesAndNewlines) {
            let wordNormalized = word.precomposedStringWithCompatibilityMapping
            if wordNormalized != "" {
                let wordNormalizedWithPrefix = tokenPrefixSymbol + wordNormalized

                let tokenizationStructureForWord = tokenizeWord(word: wordNormalizedWithPrefix)
                documentTokens.append(contentsOf: tokenizationStructureForWord.tokens)
                documentTokenIds.append(contentsOf: tokenizationStructureForWord.tokenIds)
                // Can suspend tokenization after max has been reached. -1 to account for eos
                if documentTokenIds.count > (SentencepieceConstants.maxTokenLength-1) {
                    break
                }
            }
        }
        // add eos
        documentTokens = documentTokens[0..<min(SentencepieceConstants.maxTokenLength-1, documentTokens.count)] + [eosString]
        documentTokenIds = documentTokenIds[0..<min(SentencepieceConstants.maxTokenLength-1, documentTokenIds.count)] + [eosId]
        return (documentTokens: documentTokens, documentTokenIds: documentTokenIds)
    }
    
//    func tokenizeStringByWordUpToMax(text: String, tokenizer: NLTokenizer, separateUnicodescalars: Bool = true) -> [String] {
//        var wordPieces: [String] = []
//        tokenizer.string = text
//        var wordCount = 0
//        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
//            if separateUnicodescalars {
//                let separatedWordPieces = getSeparateUnicodescalarsAsStrings(text: String(text[tokenRange]))
//                wordCount += separatedWordPieces.count
//                wordPieces.append(contentsOf: separatedWordPieces)
//            } else {
//                wordPieces.append(String(text[tokenRange]))
//                wordCount += 1
//            }
//            if wordCount >= SentencepieceConstants.maxTokenLength {
//                return false
//            } else {
//                return true
//            }
//        }
//        return wordPieces
//    }
//
//    func getSeparateUnicodescalarsAsStrings(text: String) -> [String] {
//        var wordPieces: [String] = []
//        for uScalar in text.unicodeScalars {
//            wordPieces.append(String(uScalar))
//            if wordPieces.count > SentencepieceConstants.maxTokenLength {
//                // This should never occur since this function is intended to be used after a character-level check; it only serves as a safeguard to prevent ruanwary processing.
//                break
//            }
//        }
//        return wordPieces
//    }
    
    func tokenizeStringByWordUpToMax(text: String, tokenizer: NLTokenizer) -> [String] {
        // Note that this will elimenate punctuation, which is different than the standard Sentencepiece tokenizers.
        var wordPieces: [String] = []
        tokenizer.string = text
        var wordCount = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            wordPieces.append(String(text[tokenRange]))
            wordCount += 1
            if wordCount >= SentencepieceConstants.maxTokenLength {
                return false
            } else {
                return true
            }
        }
        return wordPieces
    }
        
    /// If a whitespace delimited token is long, make educated guesses as to reasonable breaks. Without this, the HMM run time has the potential to be unacceptably long.
    func tokenizeStringByWordUpToMaxViaTagger(text: String, tagger: NLTagger, options: NLTagger.Options) -> [String] {
        //NLTagger(tagSchemes: [.lexicalClass])
        //let options: NLTagger.Options = []
        var text = text
        if text.count > SentencepieceConstants.maxCharacterLength * 3 {
            // hard cut; should rarely occur. The reason for this is if the text is exessively long, we do not want to enumerate the tagger (as unclear if the implementation is streaming).
            text = String(text.prefix(SentencepieceConstants.maxCharacterLength * 3))
        }
        
        var wordPieces: [String] = []
        tagger.string = text

        var runningWord = ""
        var runningCount = 0
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { _, tokenRange in
            let wordPiece = String(text[tokenRange])
            runningWord += wordPiece
            runningCount += wordPiece.count
            if runningCount > SentencepieceConstants.maxCharacterLength {
                wordPieces.append(runningWord)
                runningWord = ""
                runningCount = 0
            }

            if wordPieces.count >= SentencepieceConstants.maxTokenLength {
                return false
            } else {
                return true
            }
        }
        if wordPieces.count < SentencepieceConstants.maxTokenLength && runningWord != "" {
            wordPieces.append(runningWord)
        }
        
        return wordPieces
    }
    
    
    func tokenizeStringBySentReturnRanges(text: String, tokenizer: NLTokenizer) -> [Range<String.Index>] {
        var sentenceRanges: [Range<String.Index>] = []
        tokenizer.string = text
        var sentenceCount = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            
            sentenceRanges.append(tokenRange)
            sentenceCount += 1
            if sentenceCount == SentencepieceConstants.maxSentences {
                return false
            } else {
                return true
            }
        }
        return sentenceRanges
    }
    
    func tokenizeStringBySentReturnRangesWithPrompt(promptWithTrailingSpaceIfApplicable: String, documentWithPrompt: String, tokenizer: NLTokenizer) -> (sentenceRanges: [Range<String.Index>], startingSentenceArrayIndexOfDocument: Int, documentWithPromptDocumentStartRangeIndex: String.Index) {
        
        var sentenceRanges: [Range<String.Index>] = []
        tokenizer.string = documentWithPrompt
        var sentenceCount = 0
        
        var promptRange = documentWithPrompt.range(of: promptWithTrailingSpaceIfApplicable)
        var startingSentenceArrayIndexOfDocument: Int = 0
        var documentWithPromptDocumentStartRangeIndex = documentWithPrompt.startIndex
        
        tokenizer.enumerateTokens(in: documentWithPrompt.startIndex..<documentWithPrompt.endIndex) { tokenRange, _ in
            var alreadyAdded: Bool = false
            if let pRange = promptRange {
                if tokenRange.contains(pRange.upperBound) {
                    // NOTE: We reset the range array. In this way, a prompt is always treated as a single feature/sentence. We assume the prompt always preceeds the document.
                    sentenceCount = 1
                    sentenceRanges = [pRange.lowerBound..<pRange.upperBound]
                    startingSentenceArrayIndexOfDocument = 1 // Prompt is present at the first index
                    documentWithPromptDocumentStartRangeIndex = pRange.upperBound
                    promptRange = nil
                    if sentenceCount == SentencepieceConstants.maxSentences {
                        return false
                    }
                    
                    // check for remaining indexes:
                    if pRange.upperBound < tokenRange.upperBound {
                        sentenceRanges.append(pRange.upperBound..<tokenRange.upperBound)
                        sentenceCount += 1
                    }
                    alreadyAdded = true
                }
            }
            if !alreadyAdded {
                sentenceRanges.append(tokenRange)
                sentenceCount += 1
            }
            if sentenceCount == SentencepieceConstants.maxSentences {
                return false
            } else {
                return true
            }
        }
        return (sentenceRanges: sentenceRanges, startingSentenceArrayIndexOfDocument: startingSentenceArrayIndexOfDocument, documentWithPromptDocumentStartRangeIndex: documentWithPromptDocumentStartRangeIndex)
    }
    
    func getSentenceIndexByMatching(documentSentencesRanges: [Range<String.Index>], document: String, word: String, startingSentenceIndex: Int, startingStartBound: String.Index) -> (sentenceIndex: Int, startBound: String.Index)? {

        for (nominalSentenceIndex, sentenceRange) in documentSentencesRanges[startingSentenceIndex...].enumerated() {
            let sentenceIndex = startingSentenceIndex + nominalSentenceIndex
                        
            if nominalSentenceIndex == 0 {
                // In this case, start at the index of the supplied argument
                if let wordRange = document.range(of: word, range: startingStartBound..<sentenceRange.upperBound) {
                    return (sentenceIndex: sentenceIndex, startBound: wordRange.upperBound)
                }
            } else {
                if let wordRange = document.range(of: word, range: sentenceRange) {
                    return (sentenceIndex: sentenceIndex, startBound: wordRange.upperBound)
                }
            }
        }
        
        return nil
    }
    
    func tokenizeWord(word: String) -> (tokens: [String], tokenIds: [TokenIdType]) {
        if self.isMultilingual {
            return tokenizeWordWithByteLevelFallback(word: word)
        } else {
            return tokenizeWordWithUnknownTokens(word: word)
        }
    }
    
    /// Main entry point for tokenization, given a raw document input (which can include newlines and any other symbols included in the raw input from the user)
    /// - Parameters:
    ///   - document: String containing raw text
    ///   - returnDocumentTokenStrings: Typically we do not need the actual token strings, but if needed, set to true and documentTokens will contain the token strings as an optional array; otherwise, it is nil
    /// - Returns: documentTokens: documentTokensOptional, documentTokenIds: documentTokenIds, documentSentencesRanges: documentSentencesRanges, documentSentencesToTokenArrayIndexes: documentSentencesToTokenArrayIndexes, startingIndexOfTruncatedWords: startingIndexOfTruncatedWords, startingSentenceArrayIndexOfDocument: startingSentenceArrayIndexOfDocument)
    /// - `documentTokenIds` always ends with the eos id.
    /// - `documentSentencesRanges` is an array of ranges up to SentencepieceConstants.maxSentences. Note that a document with many sentences may exceed the sentence max. When visualization the output, any attributes of documentSentencesRanges.last should be applied up to the end of the document (.endIndex) as a remaining catch-all, so we guarantee `documentSentencesRanges.last!.upperBound == document.endIndex` even if the max sentence count has been exceeded. Note that it is possible that the highest sentence index in `documentSentencesToTokenArrayIndexes` does not correspond to `documentSentencesRanges.last!`; for example, if the final sentence is a newline, or the final sentence(s) exceed the tokenization max length.
    ///  - `documentSentencesToTokenArrayIndexes` Is a dictionary with sentence indexes to [initial token index, final token index) (note the open bracket). Some keys may be missing (e.g., if a sentence consisted of a new line). The highest key (sentence index) will always have a tuple value with the second element as the count of the documentTokenIds Array.
    ///   - `startingIndexOfTruncatedWords` can be used as `document[startingIndexOfTruncatedWords..<document.endIndex]` to index the truncated words. `startingIndexOfTruncatedWords` is `document.endIndex` if there is no truncation, so the aforementioned indexing is always safe, and will return `""` if there is no truncation.
    ///   - `startingSentenceArrayIndexOfDocument`: This is the length of the sentence tokenized prompt. I.e., this is the first index into documentSentencesRanges that corresponds to a document sentence (as opposed to the prefix prompt). If the document is blank, this will exceed the length of documentSentencesRanges.

    func tokenizeDocumentBySentence(documentOnly: String, prompt: String, returnDocumentTokenStrings: Bool=false, overrideTokenizerLanguageWith: NLLanguage? = nil) async throws -> SentencepieceTokenizer.DocumentTokenizationResult {

        if Task.isCancelled {
            throw MLForwardErrors.tokenizationWasCancelled
        }
        // Combine the prompt with the document
        let document: String
        let promptWithTrailingSpaceIfApplicable: String
        if prompt.isEmpty {
            document = documentOnly
            promptWithTrailingSpaceIfApplicable = prompt
        } else {
            document = prompt + " " + documentOnly
            promptWithTrailingSpaceIfApplicable = prompt + " "
        }
        let sentenceTokenizer = NLTokenizer(unit: .sentence)  // Note: shouldn't be shared across threads
//        let wordTokenizer = NLTokenizer(unit: .word)  // Note: shouldn't be shared across threads
        let wordTokenizer = NLTagger(tagSchemes: [.lexicalClass])  // Note: Now Tagger rather than tokenizer
        let tokenizerOptions: NLTagger.Options = []
//        sentenceTokenizer.setLanguage(.english)
        if let overrideTokenizerLanguageWith = overrideTokenizerLanguageWith {
            sentenceTokenizer.setLanguage(overrideTokenizerLanguageWith)
//            wordTokenizer.setLanguage(overrideTokenizerLanguageWith)
        } else {
            sentenceTokenizer.setLanguage(language)
            
//            wordTokenizer.setLanguage(language)
        }
        
//        var documentSentencesRanges: [Range<String.Index>] = tokenizeStringBySentReturnRanges(text: document, tokenizer: sentenceTokenizer)
        // NOTE: Care is taken to make sure indexes are always w.r.t. prompt + document.
        let documentWithPromptSentencesStructure = tokenizeStringBySentReturnRangesWithPrompt(promptWithTrailingSpaceIfApplicable: promptWithTrailingSpaceIfApplicable, documentWithPrompt: document, tokenizer: sentenceTokenizer)
        var documentSentencesRanges: [Range<String.Index>] = documentWithPromptSentencesStructure.sentenceRanges
        
        var documentSentenceIdsIndexedByTokenIds: [Int] = []
        
        var documentTokens: [String] = []
        var documentTokenIds: [TokenIdType] = []
        var startingSentenceIndex = 0
        var startingStartBound = document.startIndex
        
        var startingIndexOfTruncatedWords = document.endIndex
        var prevStartingStartBound = document.startIndex
        

    documentTokenizationLoop: for word in document.components(separatedBy: NSCharacterSet.whitespacesAndNewlines) {
        if Task.isCancelled {
            throw MLForwardErrors.tokenizationWasCancelled
        }
            if let sentenceIndexTuple = getSentenceIndexByMatching(documentSentencesRanges: documentSentencesRanges, document: document, word: word, startingSentenceIndex: startingSentenceIndex, startingStartBound: startingStartBound) {
                prevStartingStartBound = startingStartBound
                startingSentenceIndex = sentenceIndexTuple.sentenceIndex
                startingStartBound = sentenceIndexTuple.startBound
            }
            
            let wordNormalized = word.precomposedStringWithCompatibilityMapping
            if wordNormalized != "" {
                // Check length. If too long, we break the word into separate tokens to avoid the HMM taking too long. This should rarely occur with languages split by whitespace, but will be very common for languages such as Japanese.
                var wordNormalizedPieces: [String] = []
                if wordNormalized.count > SentencepieceConstants.maxCharacterLength {
                    let separatedWordPieces = tokenizeStringByWordUpToMaxViaTagger(text: wordNormalized, tagger: wordTokenizer, options: tokenizerOptions)
//                    let separatedWordPieces = tokenizeStringByWordUpToMax(text: wordNormalized, tokenizer: wordTokenizer)
                    wordNormalizedPieces.append(contentsOf: separatedWordPieces)
                } else {
                    wordNormalizedPieces = [wordNormalized]
                    
                }

            subwordProcessingLoop: for (wordNormalizedPieceIndex, var wordNormalizedPiece) in wordNormalizedPieces.enumerated() {
                    if wordNormalizedPieceIndex == 0 {
                        wordNormalizedPiece = tokenPrefixSymbol + wordNormalizedPiece
                    }
                    let tokenizationStructureForWord = tokenizeWord(word: wordNormalizedPiece)
//                    if (tokenizationStructureForWord.tokenIds.count == 1 && tokenizationStructureForWord.tokenIds.first! == unkId) && (documentTokenIds.count > 0 && documentTokenIds.last! == unkId) {
//
//                    }
                    if (tokenizationStructureForWord.tokenIds.count > 0 && tokenizationStructureForWord.tokenIds.first! == unkId) && (documentTokenIds.count > 0 && documentTokenIds.last! == unkId) {
                        if tokenizationStructureForWord.tokenIds.count == 1 {
                            // in this case, we can simply skip since it is a single unk and unk has already been previously added
                            continue subwordProcessingLoop
                        }
                        documentTokens.removeLast()
                        documentTokenIds.removeLast()
                    }
                                        
                    documentTokens.append(contentsOf: tokenizationStructureForWord.tokens)
                    documentTokenIds.append(contentsOf: tokenizationStructureForWord.tokenIds)
                    documentSentenceIdsIndexedByTokenIds.append(contentsOf: Array(repeating: startingSentenceIndex, count: tokenizationStructureForWord.tokenIds.count))
                        
                    // Can suspend tokenization after max has been reached. -1 to account for eos
                    if documentTokenIds.count > (SentencepieceConstants.maxTokenLength-1) {
                        startingIndexOfTruncatedWords = prevStartingStartBound
                        break documentTokenizationLoop
                    }
                }
            }
        }
        
        // add eos
        documentTokens = documentTokens[0..<min(SentencepieceConstants.maxTokenLength-1, documentTokens.count)] + [eosString]
        documentTokenIds = documentTokenIds[0..<min(SentencepieceConstants.maxTokenLength-1, documentTokenIds.count)] + [eosId]
        
        documentSentenceIdsIndexedByTokenIds = Array(documentSentenceIdsIndexedByTokenIds[0..<min(SentencepieceConstants.maxTokenLength-1, documentSentenceIdsIndexedByTokenIds.count)])
        if let finalSentenceIndex = documentSentenceIdsIndexedByTokenIds.last {
            documentSentenceIdsIndexedByTokenIds.append(finalSentenceIndex)
        } else {
            documentSentenceIdsIndexedByTokenIds.append(0)
        }
        
        var documentSentencesToTokenArrayIndexes: [Int: (Int, Int)] = [:]  // Note that some keys (sentence indexes) could be missing; for example, if a raw string sentence is a new line
        var prevSentenceIndex = 0
        documentSentencesToTokenArrayIndexes[prevSentenceIndex] = (0, 1)
        for (arrayIndex, sentenceIndex) in documentSentenceIdsIndexedByTokenIds.enumerated() {
            if (sentenceIndex != prevSentenceIndex) {
                if let initialIndex = documentSentencesToTokenArrayIndexes[prevSentenceIndex] {
                    documentSentencesToTokenArrayIndexes[prevSentenceIndex] = (initialIndex.0, arrayIndex)
                }
                documentSentencesToTokenArrayIndexes[sentenceIndex] = (arrayIndex, arrayIndex+1)
            }
            prevSentenceIndex = sentenceIndex
        }
        // final index
        if let initialIndex = documentSentencesToTokenArrayIndexes[prevSentenceIndex] {
            documentSentencesToTokenArrayIndexes[prevSentenceIndex] = (initialIndex.0, documentSentenceIdsIndexedByTokenIds.count)
        }

        // documentSentencesToTokenArrayIndexes == [0: (0, 0)] if documentSentenceIdsIndexedByTokenIds == [] or sentence 0 is not attested
        // Remove to avoid confusion, but note that this will not occur with the current convention, since sentences always end with an eos symbol,
        // so blank lines will consist of the single eos_id character:
        if let indexForKey0 = documentSentencesToTokenArrayIndexes[0] {
            if indexForKey0.1 == 0 {
                documentSentencesToTokenArrayIndexes.removeValue(forKey: 0)
            }
        }
        // Note that sentenced indexes can be missing from documentSentencesToTokenArrayIndexes
        
        // Note that a document with many sentences may exceed the sentence max. When visualization the output, any attributes of documentSentencesRanges.last should be applied up to the end of the document, so we update the final range to always include document.endIndex:
        if let finalSentenceRange = documentSentencesRanges.last {
            documentSentencesRanges[documentSentencesRanges.count-1] = finalSentenceRange.lowerBound..<document.endIndex
        }
        
        // document[startingIndexOfTruncatedWords..<document.endIndex] includes the truncated words, if applicable, xor ""
        var documentTokensOptional: [String]? = nil
        if returnDocumentTokenStrings {
            documentTokensOptional = documentTokens
        }
        
        
//        let promptSentencesRanges: [Range<String.Index>] = tokenizeStringBySentReturnRanges(text: prompt, tokenizer: sentenceTokenizer)
        
        return (documentTokens: documentTokensOptional, documentTokenIds: documentTokenIds, documentSentencesRanges: documentSentencesRanges, documentSentencesToTokenArrayIndexes: documentSentencesToTokenArrayIndexes, startingIndexOfTruncatedWords: startingIndexOfTruncatedWords, startingSentenceArrayIndexOfDocument: documentWithPromptSentencesStructure.startingSentenceArrayIndexOfDocument, documentWithPromptDocumentStartRangeIndex: documentWithPromptSentencesStructure.documentWithPromptDocumentStartRangeIndex) //promptWithTrailingSpaceIfApplicable.endIndex)
    }
    
    /*func parallelTokenizationBySentence(lines: [String], returnDocumentTokenStrings: Bool=false, overrideTokenizerLanguageWith: NLLanguage? = nil) async -> [Int: SentencepieceTokenizer.DocumentTokenizationResult] {
        await withTaskGroup(
            of: (Int, SentencepieceTokenizer.DocumentTokenizationResult).self,
            returning: [Int: SentencepieceTokenizer.DocumentTokenizationResult].self
        ) { [self] group in
            for (documentIndex, document) in lines.enumerated() {
                group.addTask { await (documentIndex, self.tokenizeDocumentBySentence(documentOnly: document, prompt: "", returnDocumentTokenStrings: returnDocumentTokenStrings, overrideTokenizerLanguageWith: overrideTokenizerLanguageWith )) }
            }

            var tokenizedDocumentDict: [Int: SentencepieceTokenizer.DocumentTokenizationResult] = [:]

            for await result in group {
                tokenizedDocumentDict[result.0] = result.1
            }

            return tokenizedDocumentDict
        }
    }*/
    
    func parallelTokenizationBySentenceWithPrompt(lines: [String], prompts: [String], returnDocumentTokenStrings: Bool=false, overrideTokenizerLanguageWith: NLLanguage? = nil) async throws -> [Int: SentencepieceTokenizer.DocumentTokenizationResult] {
        try await withThrowingTaskGroup(
            of: (Int, SentencepieceTokenizer.DocumentTokenizationResult).self,
            returning: [Int: SentencepieceTokenizer.DocumentTokenizationResult].self
        ) { [self] group in
            for (documentIndex, document) in lines.enumerated() {
                group.addTask { await (documentIndex, try self.tokenizeDocumentBySentence(documentOnly: document, prompt: prompts[documentIndex], returnDocumentTokenStrings: returnDocumentTokenStrings, overrideTokenizerLanguageWith: overrideTokenizerLanguageWith )) }
            }
            
            var tokenizedDocumentDict: [Int: SentencepieceTokenizer.DocumentTokenizationResult] = [:]
            
            for try await result in group {
                tokenizedDocumentDict[result.0] = result.1
            }
            
            return tokenizedDocumentDict
        }
    }
    
}


