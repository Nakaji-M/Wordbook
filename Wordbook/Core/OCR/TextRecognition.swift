//
//  TextRecognition.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/08.
//

import PhotosUI
import Vision
import NaturalLanguage
import MLKitTranslate
import SimilaritySearchKit

class TextRecognition {
    private var uiImage: UIImage?
    private var wordsPerPage = 8
    var recognizedTexts: [VNRecognizedTextObservation] = []
    private var whereIsMeaning: MeaningPosition = .below
    private var exertScanExample: Bool
    private var scanIdiom: Bool
    private var words_list : [Word] = []
    private var ocrProcessSelection: OCRProcessSelection = .auto
    private var isManualWordsPerPage = false
    private var isMeaningFromDictionary: Bool
    private var translator: Translator!
    private let ignoreWords: [String] = ["アクセント", "アク", "アク?", "アク？", "アクセント注意", "発音", "発音注意", "スペル", "スペル注意", "スペルミス", "多義語", "多義"]
    private let warningWords: [String] = ["⚠️", "⚠︎", "⬜︎", "⬛︎", "■", "□", "◼︎", "◻︎", "◆", "◇", "○", "●", "△", "▲", "▽", "▼"]
    private let grammerWords: [String] = ["動", "名", "形", "副", "前", "接", "代", "助", "助動", "接続"]
    private let customWords: [String]
    
    init(uiImage: UIImage, addWordsViewModel: AddWordsViewModel, manualProcessViewModel: ManualProcessSelectionViewModel?, exertScanExample: Bool, scanIdiom: Bool) {
        self.uiImage = uiImage
        self.ocrProcessSelection = addWordsViewModel.ocrProcessSelection
        self.isMeaningFromDictionary = addWordsViewModel.isMeaningFromDictionary
        self.exertScanExample = exertScanExample
        self.scanIdiom = scanIdiom
        if ocrProcessSelection == .manual {
            self.isManualWordsPerPage = manualProcessViewModel!.isManualWordsPerPage
            self.whereIsMeaning = manualProcessViewModel!.whereIsMeaning
            self.wordsPerPage = manualProcessViewModel!.wordsPerPage
        }
        customWords = warningWords + grammerWords
    }
    
    func recognize() async -> [Word]{
        recognizeText()
        removeOnlyNumbers()
        recognizeWordsFromPosition()
        if !isMeaningFromDictionary && words_list.count > 0{
            makeWordBlock()
            recognizeMeaningFromPosition()
            removeWordwithZeroMeaning()
            if words_list.count > 0 {
                await naturalLanguageProcessing()
                deleteWordIfNeeded() //単語と意味の取得が完了
                getNeighborLine_Meaning(indexes: Array(0 ..< words_list.count))
                verifyMeaningFromPosition()
                filterMeaningFromPosition()
                writeMeaningString()
                if exertScanExample {
                    findExampleSentence()
                }
            }
        }
        return words_list
    }
        
    
    //テキストの認識を行う
    func recognizeText() {
        guard let cgImage = uiImage?.cgImage else {
            return
        }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLanguages = ["ja", "en"]
        request.customWords = customWords
        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error)")
        }
    }
    
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        self.recognizedTexts = results
    }
    
    func removeOnlyNumbers() {
        recognizedTexts.removeAll(where: { Int($0.topCandidates(1).first!.string ) != nil})
    }
        
    //左上がminX, maxYで, 左下がminX, minYとなるように修正する.一般的な数学の座標と同じ向き
    func fixBoundingBoxOrientation(bounds: CGRect, orientation: UIImage.Orientation) -> CGRect {
        if orientation == .up {
            return bounds
        }
        else if orientation == .down{
            return CGRect(x: 1 - bounds.maxX, y: 1 - bounds.maxY, width: bounds.width, height: bounds.height)
        }
        else if orientation == .left {
            return CGRect(x: 1 - bounds.maxY, y: bounds.minX, width: bounds.height, height: bounds.width)
        }
        else {
            return CGRect(x: bounds.minY, y: 1 - bounds.maxX, width: bounds.height, height: bounds.width)
        }
    }
    
    //認識した各テキストの位置から単語を認識する
    func recognizeWordsFromPosition() {
        let orientation = uiImage!.imageOrientation
        print("orientation", orientation)
        //フォントサイズの大きい順にソートする
        recognizedTexts.sort { (first, second) -> Bool in
            let firstBox = fixBoundingBoxOrientation(bounds: first.boundingBox, orientation: orientation)
            let secondBox = fixBoundingBoxOrientation(bounds: second.boundingBox, orientation: orientation)
            return firstBox.height > secondBox.height
        }
        if recognizedTexts.count == 0 {
            return
        }
        //見出し後のフォントサイズは上位4/5と考えられる
        var wordCandidates = recognizedTexts[0 ..< (recognizedTexts.count - 1) * 4/5]
        
        //見出し語は英語
        if scanIdiom {
            wordCandidates = wordCandidates.filter { $0.topCandidates(1).first!.string.matches( of: /^[a-zA-Z\s-]+$/).count != 0 }
        }else{
            wordCandidates = wordCandidates.filter { $0.topCandidates(1).first!.string.matches( of: /^[a-zA-Z]+$/).count != 0 }
        }
        
        if wordCandidates.count == 0 {
            return
        }
        //位置が左寄りな順にソートする
        wordCandidates.sort { (first, second) -> Bool in
            let firstbox = fixBoundingBoxOrientation(bounds: first.boundingBox, orientation: orientation)
            let secondbox = fixBoundingBoxOrientation(bounds: second.boundingBox, orientation: orientation)
            return firstbox.minX < secondbox.minX
        }
        //第一四分位数を求める
        let boundingbox_1stQuater = wordCandidates[(wordCandidates.count - 1) / 4].boundingBox
        let X_1stQuater = fixBoundingBoxOrientation(bounds:boundingbox_1stQuater, orientation: orientation).minX
        if(!isManualWordsPerPage){
            wordCandidates = wordCandidates.filter {
                let this_X = fixBoundingBoxOrientation(bounds:$0.boundingBox, orientation: orientation).minX
                return (X_1stQuater - 0.05 < this_X) && (this_X < X_1stQuater + 0.05)
            }
            self.words_list = wordCandidates.map{ word in
                let word_item = Word()
                word_item.word = word
                word_item.wordString = word.topCandidates(1).first!.string
                return word_item
            }
        } else {
            //Y座標が四分位数と近い順にwordsPerPage+2個選ぶ. 余分に選んだsurplus個はdeletePriorityを!=0にする
            wordCandidates.sort{ (first, second) -> Bool in
                let firstbox = fixBoundingBoxOrientation(bounds: first.boundingBox, orientation: orientation)
                let secondbox = fixBoundingBoxOrientation(bounds: second.boundingBox, orientation: orientation)
                return abs(firstbox.minX - X_1stQuater) < abs(secondbox.minX - X_1stQuater)
            }
            let surplus = 2
            let length = min(wordsPerPage + surplus, wordCandidates.count)
            wordCandidates = wordCandidates[0 ..< length]
            self.words_list = wordCandidates.map{ word in
                let word_item = Word()
                word_item.word = word
                word_item.wordString = word.topCandidates(1).first!.string
                return word_item
            }
            //余分なものをmayDeleteをtrueにする
            if wordCandidates.count > wordsPerPage {
                for i in wordsPerPage ..< wordCandidates.count {
                    
                    words_list[i].deletePriority = i - wordsPerPage
                }
            }
        }
    }
    
    func makeWordBlock(){
        let orientation = uiImage!.imageOrientation
        //位置が上寄りな順にソートする
        self.words_list.sort{
            let firstbox = fixBoundingBoxOrientation(bounds: $0.word!.boundingBox, orientation: orientation)
            let secondbox = fixBoundingBoxOrientation(bounds: $1.word!.boundingBox, orientation: orientation)
            return firstbox.minY > secondbox.minY
        }
        var indexes_priority_0 : [Int] = []
        for i in 0 ..< words_list.count {
            if words_list[i].deletePriority == 0 {
                indexes_priority_0.append(i)
            }
        }
        //wordBlocksの作成
        for i in 0 ..< self.words_list.count {
            let index_previous_priority_0 = indexes_priority_0.filter{ $0 < i }.last ?? ( i-1 )
            var previousWord_bottomY = (index_previous_priority_0 >= 0) ? fixBoundingBoxOrientation(bounds: self.words_list[index_previous_priority_0].word!.boundingBox, orientation: orientation).minY : 1.0
            let word = self.words_list[i].word!
            let word_bottomY = fixBoundingBoxOrientation(bounds: word.boundingBox, orientation: orientation).minY
            let word_topY = fixBoundingBoxOrientation(bounds: word.boundingBox, orientation: orientation).maxY
            let index_next_priority_0 = indexes_priority_0.filter{ $0 > i }.first ?? ( i+1 )
            var nextWord_topY = (index_next_priority_0 < self.words_list.count) ? fixBoundingBoxOrientation(bounds: self.words_list[index_next_priority_0].word!.boundingBox, orientation: orientation).maxY : 0.0
            
            if previousWord_bottomY == 1.0 && nextWord_topY != 0.0 {
                previousWord_bottomY = word_bottomY + (word_topY - nextWord_topY)
            }
            else if nextWord_topY == 0.0 && previousWord_bottomY != 1.0 {
                nextWord_topY = word_topY - (previousWord_bottomY - word_bottomY)
            }
            
            //Y座標がnextWord_topYより上でpreviousWord_bottomYより下のrecognizedTextを取得
            let wordBlock = recognizedTexts.filter{
                let thisBox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                return thisBox.maxY < previousWord_bottomY && thisBox.minY > nextWord_topY
            }
            words_list[i].wordBlock = wordBlock
        }
    }
    
    //認識した各テキストの位置から意味の候補をいくつか取得する
    func recognizeMeaningFromPosition(){
        let orientation = uiImage!.imageOrientation
        let recognizer = NLLanguageRecognizer()

        //日本語のみを取得
        for i in 0 ..< words_list.count {
            self.words_list[i].wordBlocks_ja = words_list[i].wordBlock.filter{
                recognizer.reset()
                recognizer.processString($0.topCandidates(1).first!.string)
                recognizer.languageConstraints = [.japanese, .english]
                let word_trimed = warningWords.reduce($0.topCandidates(1).first!.string) { $0.replacingOccurrences(of: $1, with: "") }.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .punctuationCharacters)
                let isIgnoreWord = ignoreWords.contains(word_trimed) //無視すべき単語のみからなる要素を検知
                let japaneseWordCount = $0.topCandidates(1).first!.string.matches( of: /[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}]/).count //平仮名、カタカナ、漢字の個数を検知
                return (recognizer.dominantLanguage == NLLanguage.japanese || japaneseWordCount >= 3) && !isIgnoreWord
            }
        }
        //単語の右側に意味がある場合にwords_mid_X、mid_max_Xを用いる
        let words_mid_X = words_list.sorted{
            fixBoundingBoxOrientation(bounds: $0.word!.boundingBox, orientation: orientation).maxX < fixBoundingBoxOrientation(bounds: $1.word!.boundingBox, orientation: orientation).maxX
            //不等号の向きはこれが正しい
        }
        let mid_max_X = fixBoundingBoxOrientation(bounds: words_mid_X[(words_mid_X.count - 1)/2].word!.boundingBox, orientation: orientation).maxX

        for i in 0 ..< words_list.count{
            let wordbox = fixBoundingBoxOrientation(bounds: self.words_list[i].word!.boundingBox, orientation: orientation)
            let word_max_X = wordbox.maxX
            var meaningCandidate = [VNRecognizedTextObservation]()
            if (ocrProcessSelection == .manual && whereIsMeaning == .right) || ocrProcessSelection == .auto {
                //単語の右に意味がある場合
                var meaningCandidate_right = words_list[i].wordBlocks_ja.filter{
                    let thisBox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    return thisBox.minX > max(word_max_X, mid_max_X)
                }
                meaningCandidate_right.sort{
                    let firstbox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    let secondbox = fixBoundingBoxOrientation(bounds: $1.boundingBox, orientation: orientation)
                    return firstbox.minX < secondbox.minX
                }
                //意味の候補が2つ以上ある場合は上位3つを取得
                if meaningCandidate_right.count > 0 {
                    let num = min(3, meaningCandidate_right.count)
                    meaningCandidate += Array(meaningCandidate_right[0 ..< num])
                }
            }
            if (ocrProcessSelection == .manual && whereIsMeaning == .top) || ocrProcessSelection == .auto {
                //単語の上に意味がある場合
                var meaningCandidate_top = words_list[i].wordBlocks_ja.filter{
                    let thisBox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    //単語よりも位置が上、かつ単語の右端よりも左から文が始まるものを抽出
                    let isTop = thisBox.minY > wordbox.maxY
                    let isLeft = thisBox.minX < max(word_max_X, mid_max_X)
                    return isTop && isLeft
                }
                //位置が下寄りな順にソートする。すなわち単語と縦の位置が近い順
                meaningCandidate_top.sort{
                    let firstbox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    let secondbox = fixBoundingBoxOrientation(bounds: $1.boundingBox, orientation: orientation)
                    return firstbox.minY < secondbox.minY
                }
                //意味の候補が2つ以上ある場合は上位3つを取得
                if meaningCandidate_top.count > 0 {
                    let num = min(3, meaningCandidate_top.count)
                    meaningCandidate += Array(meaningCandidate_top[0 ..< num])
                }
                
            }
            if (ocrProcessSelection == .manual && whereIsMeaning == .below) || ocrProcessSelection == .auto {
                //単語の下に意味がある場合
                var meaningCandidate_Below = words_list[i].wordBlocks_ja.filter{
                    let thisBox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    //単語よりも位置が下、かつ単語の右端よりも左から文が始まるものを抽出
                    let isBelow = thisBox.maxY < wordbox.minY
                    let isLeft = thisBox.minX < max(word_max_X, mid_max_X)
                    return isBelow && isLeft
                }
                //位置が上寄りな順にソートする。すなわち単語と縦の位置が近い順
                meaningCandidate_Below.sort{
                    let firstbox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    let secondbox = fixBoundingBoxOrientation(bounds: $1.boundingBox, orientation: orientation)
                    return firstbox.maxY > secondbox.maxY
                }
                //意味の候補が2つ以上ある場合は上位3つを取得
                if meaningCandidate_Below.count > 0 {
                    let num = min(3, meaningCandidate_Below.count)
                    meaningCandidate += Array(meaningCandidate_Below[0 ..< num])
                }
                
            }

            words_list[i].meaningCandidate = meaningCandidate
        }
        for item in words_list{
            print("word", item.word!.topCandidates(1).first!.string, "meaningAll", item.meaningCandidate.map{ $0.topCandidates(1).first!.string })
        }
    }
    
    func removeWordwithZeroMeaning(){
        var i = 0;
        while i < words_list.count {
            if words_list[i].meaningCandidate.count == 0 {
                words_list.remove(at: i)
            }
            else{
                i += 1
            }
        }
    }
    
    func model(forLanguage: TranslateLanguage) -> TranslateRemoteModel {
      return TranslateRemoteModel.translateRemoteModel(language: forLanguage)
    }
    
    func naturalLanguageProcessing() async {
        let model = self.model(forLanguage: .japanese)
        let modelManager = ModelManager.modelManager()
        let conditions = ModelDownloadConditions(
            allowsCellularAccess: true,
            allowsBackgroundDownloading: true
        )
        if !modelManager.isModelDownloaded(model) {
            modelManager.download(model, conditions: conditions)
        }
        let options = TranslatorOptions(sourceLanguage: .japanese, targetLanguage: .english)
        translator = Translator.translator(options: options)
        let similarityIndex = await SimilarityIndex(
            model: NativeEmbeddings(),
            metric: CosineSimilarity()
        )

        for i in 0 ..< words_list.count {
            if words_list[i].meaningCandidate.count == 1 {
                self.words_list[i].meaning = self.words_list[i].meaningCandidate[0]
                print("word", words_list[i].word!.topCandidates(1).first!.string, "meaning", words_list[i].meaningCandidate[0].topCandidates(1).first!.string)
            }
            else {
                similarityIndex.indexItems = []
                var meaningCandidate_en: [String] = []
                for j in 0 ..< words_list[i].meaningCandidate.count {
                    let text = words_list[i].meaningCandidate[j].topCandidates(1).first!.string
                    
                    var translated = ""
                    let semaphore = DispatchSemaphore(value: 0)
                    translate(sourceText: text, completion: { result in
                        translated = result
                        semaphore.signal()
                    }
                    )
                    
                    semaphore.wait()
                    meaningCandidate_en.append(translated)
                }
                words_list[i].meaningCandidates_en = meaningCandidate_en
                
                //類似度が高い単語を取得する
                let word = self.words_list[i].word!.topCandidates(1).first!.string
                for j in 0 ..< words_list[i].meaningCandidates_en.count {
                    //意味の候補をそのまま追加
                    let meaning_en = words_list[i].meaningCandidates_en[j]
                    await similarityIndex.addItem(
                        id: String(j),
                        text: meaning_en,
                        metadata: [:]
                    )
                    //意味の候補からカッコで囲まれた部分を削除したものを追加
                    //(または<から始まり、)または>で終わる部分を削除
                    let meaning_en_withoutParentheses = meaning_en.replacingOccurrences(of: "[\\(|<].+?[\\)|>]", with: "", options: .regularExpression)
                    if meaning_en_withoutParentheses != meaning_en {
                        await similarityIndex.addItem(
                            id: String(j),
                            text: meaning_en_withoutParentheses,
                            metadata: [:]
                        )
                    }
                    
                    //meaning_en_withoutParenthesesから空白文字や改行を削除し、;:①②③④⑤⑥⑦⑧⑨⑩で分割
                    var meaning_en_list = meaning_en_withoutParentheses.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: CharacterSet(charactersIn: ";:；:①②③④⑤⑥⑦⑧⑨⑩"))
                    meaning_en_list.removeAll(where: { $0 == "" })
                    if meaning_en_list.count > 1{
                        for item in meaning_en_list {
                            await similarityIndex.addItem(
                                id: String(j),
                                text: item,
                                metadata: [:]
                            )
                        }
                    }
                }
                
                let results = await similarityIndex.search(word)
                print(results)
                let similar_meaning = results.max { (first, second) -> Bool in
                    //この向きが正しい
                    return first.score < second.score
                }
                
                let similar_meaning_idx = Int(similar_meaning!.id)
                self.words_list[i].meaning = self.words_list[i].meaningCandidate[similar_meaning_idx!]
                print("word", word, "meaning", words_list[i].meaningCandidate[similar_meaning_idx!].topCandidates(1).first!.string)
            }
        }
    }
    
    func verifyMeaningFromPosition(){
        let orientation = uiImage!.imageOrientation
        //words_listの各要素のwordBlockから見たmeaningBlocks[0]の位置を取得する
        let relativePosition = words_list.filter({ $0.deletePriority == 0 }).map{
            let wordBlock = $0.wordBlock
            let meaningBlocks = $0.meaningBlocks.sorted{
                let firstbox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                let secondbox = fixBoundingBoxOrientation(bounds: $1.boundingBox, orientation: orientation)
                return firstbox.minY < secondbox.minY
            }
            let wordbox = fixBoundingBoxOrientation(bounds: $0.word!.boundingBox, orientation: orientation)
            let meaningbox = fixBoundingBoxOrientation(bounds: meaningBlocks[0].boundingBox, orientation: orientation)
            let word_bottomY = wordbox.minY
            let meaning_bottomY = meaningbox.minY
            let word_minX = wordbox.minX
            let meaning_minX = meaningbox.minX
            let relative_bottomY = meaning_bottomY - word_bottomY
            let relative_minX = meaning_minX - word_minX
            return (relative_minX, relative_bottomY)
        }
        
        //カーネル密度推定を行う
        let statistics = Statistics()
        let s_x = statistics.variance(relativePosition.map{ $0.0 })
        let s_y = statistics.variance(relativePosition.map{ $0.1 })
        let h_x = pow(4/3, 1/5) * sqrt(s_x) * pow(Double(words_list.count), -1/5)         //最適なhを求める
        let h_y = pow(4/3, 1/5) * sqrt(s_y) * pow(Double(words_list.count), -1/5)         //最適なhを求める
        var kernel_density_estimation_x = statistics.kernelDensityEstimation(relativePosition.map{ $0.0 }, h_x)
        var kernel_density_estimation_y = statistics.kernelDensityEstimation(relativePosition.map{ $0.1 }, h_y)
        let relativePosition_mode_x = relativePosition[kernel_density_estimation_x.firstIndex(of: kernel_density_estimation_x.max()!)!]
        let relativePosition_mode_y = relativePosition[kernel_density_estimation_y.firstIndex(of: kernel_density_estimation_y.max()!)!]
        
        //fontsize順にソートする
        let words_list_sored_by_fontsize = words_list.sorted{
            let firstbox = fixBoundingBoxOrientation(bounds: $0.word!.boundingBox, orientation: orientation)
            let secondbox = fixBoundingBoxOrientation(bounds: $1.word!.boundingBox, orientation: orientation)
            return firstbox.height > secondbox.height
        }
        let word_fontsize_median = words_list_sored_by_fontsize[(words_list_sored_by_fontsize.count - 1) / 2]
        let wordbox_fontsize_median = fixBoundingBoxOrientation(bounds: word_fontsize_median.word!.boundingBox, orientation: orientation)
        //fontsizeの中央値を取得する
        let fontsize_median = wordbox_fontsize_median.height
        
        var indexes_searchAgain : [Int] = []
        //relativePosition_medianとfontsize_medianからwords_listの各要素について想定される意味の位置を計算
        for i in 0 ..< words_list.count {
            let wordbox = fixBoundingBoxOrientation(bounds: words_list[i].word!.boundingBox, orientation: orientation)
            let relative_minX = relativePosition_mode_x.0
            let relative_bottomY = relativePosition_mode_y.1
            let anticipated_meaningbox = CGRect(x: wordbox.minX + relative_minX, y: wordbox.minY + relative_bottomY, width: fontsize_median * 3, height: fontsize_median)
            let anticipated_meaningbox_big = CGRect(x: wordbox.minX + relative_minX - fontsize_median, y: wordbox.minY + relative_bottomY - fontsize_median / 2, width: fontsize_median * 5, height: fontsize_median * 2)
            let meaningboxes = words_list[i].meaningBlocks.map{ fixBoundingBoxOrientation(bounds:$0.boundingBox, orientation: orientation)}
            let isIntersect = meaningboxes.contains{ anticipated_meaningbox.intersects($0) }
            //重なりが少しでもあるときはその意味を信用
            //重なりがないときは意味を再検討
            if !isIntersect {
                for j in 0 ..< words_list[i].meaningCandidate.count {
                    let meaningbox = fixBoundingBoxOrientation(bounds: words_list[i].meaningCandidate[j].boundingBox, orientation: orientation)
                    let isIntersect = anticipated_meaningbox_big.intersects(meaningbox)
                    if isIntersect {
                        words_list[i].meaning = words_list[i].meaningCandidate[j]
                        indexes_searchAgain.append(i)
                        break
                    }
                }
            }
        }
        //再検討が必要なものを再検討
        getNeighborLine_Meaning(indexes: indexes_searchAgain)
    }
    
    func translate(sourceText: String, completion: @escaping (String) -> Void) {
        let translatorForDownloading = self.translator!
            translatorForDownloading.downloadModelIfNeeded { error in
                guard error == nil else {
                    print("Failed to ensure model downloaded with error \(error!)")
                    return
                }
                    if translatorForDownloading == self.translator {
                        translatorForDownloading.translate(sourceText) { result, error in
                            guard error == nil else {
                                print("Failed with error \(error!)")
                                return
                            }
                            if translatorForDownloading == self.translator {
                                //print(result)
                                completion(result!)

                            }
                        }
                }
        }
    }
    
    func deleteWordIfNeeded() {
        if isManualWordsPerPage && words_list.count > wordsPerPage {
            let deletecount = words_list.count - wordsPerPage
            words_list.sort{
                $0.deletePriority > $1.deletePriority
            }
            for _ in 0 ..< deletecount{
                words_list.remove(at: 0)
            }
        }
    }
    
    func filterMeaningFromPosition(){
        let orientation = uiImage!.imageOrientation
        //words_listの各要素のwordBlockから見たmeaningBlocks[0]の位置を取得する
        var relativePosition = words_list.map{
            let wordbox = fixBoundingBoxOrientation(bounds: $0.word!.boundingBox, orientation: orientation)
            let meaningbox = fixBoundingBoxOrientation(bounds: $0.meaningBlocks[0].boundingBox, orientation: orientation)
            let word_bottomY = wordbox.minY
            let meaning_topY = meaningbox.maxY
            let relative_topY = meaning_topY - word_bottomY
            return relative_topY
        }
        
        relativePosition.sort()
        
        let relativePosition_median = relativePosition[(relativePosition.count - 1) / 2]
                
            
            //fontsize順にソートする
            let words_list_sored_by_fontsize = words_list.sorted{
                let firstbox = fixBoundingBoxOrientation(bounds: $0.meaning!.boundingBox, orientation: orientation)
                let secondbox = fixBoundingBoxOrientation(bounds: $1.meaning!.boundingBox, orientation: orientation)
                return firstbox.height > secondbox.height
            }
            let meaning_fontsize_median = words_list_sored_by_fontsize[(words_list_sored_by_fontsize.count - 1) / 2]
        let meaningbox_fontsize_median = fixBoundingBoxOrientation(bounds: meaning_fontsize_median.meaning!.boundingBox, orientation: orientation)
            //fontsizeの中央値を取得する
            let fontsize_median = meaningbox_fontsize_median.height
            
            //relativePosition_medianとfontsize_medianからwords_listの各要素について想定される意味の位置を計算
            for i in 0 ..< words_list.count {
                let wordbox = fixBoundingBoxOrientation(bounds: words_list[i].word!.boundingBox, orientation: orientation)
                let anticipatedTopY = wordbox.minY + relativePosition_median
                let threshold = anticipatedTopY + fontsize_median
                while words_list[i].meaningBlocks.count > 0 {
                    let meaningbox = fixBoundingBoxOrientation(bounds: words_list[i].meaningBlocks[0].boundingBox, orientation: orientation)
                    let meaningTopY = meaningbox.maxY
                    let meaningString = words_list[i].meaningBlocks[0].topCandidates(1).first!.string
                    let meaningString_top = words_list[i].meaning?.topCandidates(1).first!.string ?? ""
                    if meaningTopY < threshold || meaningString == meaningString_top {
                        break
                    }
                    else {
                        words_list[i].meaningBlocks.remove(at: 0)
                    }
                }
            }
    }
    
    func writeMeaningString(){
        for i in 0 ..< words_list.count {
            words_list[i].meaningString = words_list[i].meaningBlocks.map{ $0.topCandidates(1).first!.string }.joined(separator : "\n")
            print("word", words_list[i].word!.topCandidates(1).first!.string, "meaning", words_list[i].meaningString)
        }
    }
    
    
    func findExampleSentence() {
        let orientation = uiImage!.imageOrientation
        for i in 0 ..< words_list.count {
            //単語・意味と同じ高さの行を取得
            let wordBox = fixBoundingBoxOrientation(bounds: words_list[i].word!.boundingBox, orientation: orientation)
            let meaningBox = fixBoundingBoxOrientation(bounds: words_list[i].meaning!.boundingBox, orientation: orientation)
            let maxX = max(wordBox.maxX, meaningBox.maxX)
            let minY = min(wordBox.minY, meaningBox.minY)
            let maxY = max(wordBox.maxY, meaningBox.maxY)
            let exampleSentenceCandidate = words_list[i].wordBlock.filter{
                let thisBox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                return maxX < thisBox.minX && thisBox.minY < maxY && minY < thisBox.maxY
            }
            //横の位置関係が近いものをまとめる
            var exampleSentenceCandidate_byBlock : [[VNRecognizedTextObservation]] = []
            for j in 0 ..< exampleSentenceCandidate.count {
                let thisBox = fixBoundingBoxOrientation(bounds: exampleSentenceCandidate[j].boundingBox, orientation: orientation)
                let fontSize = thisBox.height
                var isExist = false
                for k in 0 ..< exampleSentenceCandidate_byBlock.count {
                    let block = exampleSentenceCandidate_byBlock[k]
                    let blockBox = fixBoundingBoxOrientation(bounds: block[0].boundingBox, orientation: orientation)
                    if abs(thisBox.minX - blockBox.minX) < 1.5 * fontSize {
                        exampleSentenceCandidate_byBlock[k].append(exampleSentenceCandidate[j])
                        isExist = true
                        break
                    }
                }
                if !isExist {
                    exampleSentenceCandidate_byBlock.append([exampleSentenceCandidate[j]])
                }
            }
            //exampleSentenceCandidate_byBlockの内側の配列を上から順にソート
            for j in 0 ..< exampleSentenceCandidate_byBlock.count {
                exampleSentenceCandidate_byBlock[j].sort{
                    let firstbox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    let secondbox = fixBoundingBoxOrientation(bounds: $1.boundingBox, orientation: orientation)
                    return firstbox.minY > secondbox.minY
                }
            }
            //exampleSentenceCandidate_byBlockを左から順にソート
            exampleSentenceCandidate_byBlock.sort{
                let firstbox = fixBoundingBoxOrientation(bounds: $0[0].boundingBox, orientation: orientation)
                let secondbox = fixBoundingBoxOrientation(bounds: $1[0].boundingBox, orientation: orientation)
                return firstbox.minX < secondbox.minX
            }
            
            //上下の行を取得
            for j in 0 ..< exampleSentenceCandidate_byBlock.count {
                exampleSentenceCandidate_byBlock[j] = getNeighborLine_MultiLines(word: words_list[i], line: exampleSentenceCandidate_byBlock[j][0], searchDirection: .top)
                exampleSentenceCandidate_byBlock[j] = getNeighborLine_MultiLines(word: words_list[i], line: exampleSentenceCandidate_byBlock[j].last!, searchDirection: .bottom)
            }
            words_list[i].exampleSentence_byBlock = exampleSentenceCandidate_byBlock
            words_list[i].exampleSentenceString = exampleSentenceCandidate_byBlock.map{ $0.map{ $0.topCandidates(1).first!.string }.joined(separator: "\n") }.joined(separator: "\n\n")
            print("word", words_list[i].word!.topCandidates(1).first!.string, "example", words_list[i].exampleSentenceString)
        }
    }
    
    func getNeighborLine_Meaning(indexes: [Int]) {
        for i in indexes{
            let neighborLines = getNeighborLine_MultiLines(word: words_list[i], line: words_list[i].meaning!, searchDirection: .both)
            //すでに位置が上寄りな順にソートされている
            words_list[i].meaningBlocks = neighborLines
        }
    }
    
    //上下の複数行を取得
    func getNeighborLine_MultiLines(word: Word, line: VNRecognizedTextObservation, searchDirection : NeighborLineSearchDirection) -> [VNRecognizedTextObservation] {
        var neighborLines: [VNRecognizedTextObservation] = [line]
        var count = 0
        if searchDirection == .both || searchDirection == .top{
            while true{
                //上方向の検出は厳し目に
                let additionalBlock_top = getNeighborLine(word: word, line: neighborLines[0], searchDirection: .top, threshold_upperBound: 0.2, threshold_lowerBound: 0.4)
                if additionalBlock_top.count == 0 || count > 3{
                    break
                }
                else {
                    neighborLines = additionalBlock_top + neighborLines
                }
                count += 1
            }
            
            //②がある場合①もある可能性が高いので左側を探索
            if neighborLines.contains(where: {$0.topCandidates(1).first!.string.contains("②")}) && !neighborLines.contains(where: {$0.topCandidates(1).first!.string.contains("①")}){
                let candidate_blocks = getNeighborLine_horizontal(word: word, line: neighborLines[0], searchDirection: .left)
                let blocks_with_① = candidate_blocks.filter{ $0.topCandidates(1).first!.string.contains("①") }
                neighborLines =  blocks_with_① + neighborLines
                if blocks_with_①.count == 0{
                    let candidate_blocks = getNeighborLine(word: word, line: neighborLines[0], searchDirection: .top, threshold_upperBound: 0.5, threshold_lowerBound: 0.5)
                    let blocks_with_① = candidate_blocks.filter{ $0.topCandidates(1).first!.string.contains("①") }
                    neighborLines =  blocks_with_① + neighborLines
                }
            }
        }
        count = 0
        if  searchDirection == .both || searchDirection == .bottom {
            while true{
                //下方向の検出は緩めに
                let additionalBlock_bottom = getNeighborLine(word: word, line: neighborLines.last!, searchDirection: .bottom, threshold_upperBound: 0.25, threshold_lowerBound: 0.4)
                if additionalBlock_bottom.count == 0 || count > 3 {
                    break
                }
                else {
                    neighborLines = neighborLines + additionalBlock_bottom
                }
                count += 1
            }
            //①がある場合は②もある可能性が高いので左側を探索
            if neighborLines.contains(where: {$0.topCandidates(1).first!.string.contains("①")}) && !neighborLines.contains(where: {$0.topCandidates(1).first!.string.contains("②")}){
                let index_line = neighborLines.firstIndex(where: {$0.topCandidates(1).first!.string.contains("①")}) ?? 0
                let candidate_blocks = getNeighborLine_horizontal(word: word, line: neighborLines[index_line], searchDirection: .right)
                let blocks_with_② = candidate_blocks.filter{ $0.topCandidates(1).first!.string.contains("②") }
                neighborLines =  Array(neighborLines[0 ..< index_line + 1]) + blocks_with_② + Array(neighborLines[index_line + 1 ..< neighborLines.count])
                if blocks_with_②.count == 0{
                    let candidate_blocks = getNeighborLine(word: word, line: neighborLines.last!, searchDirection: .bottom, threshold_upperBound: 0.5, threshold_lowerBound: 0.5)
                    let blocks_with_② = candidate_blocks.filter{ $0.topCandidates(1).first!.string.contains("②") }
                    neighborLines =  Array(neighborLines[0 ..< index_line + 1]) + blocks_with_② + Array(neighborLines[index_line + 1 ..< neighborLines.count])
                }
            }
        }
        return neighborLines
    }
    
    //上下の1行を取得
    func getNeighborLine(word: Word, line: VNRecognizedTextObservation, searchDirection : NeighborLineSearchDirection, threshold_upperBound: Double = 0.25, threshold_lowerBound: Double = 0.4) -> [VNRecognizedTextObservation] {
        var neighborLines: [VNRecognizedTextObservation] = []
        let orientation = uiImage!.imageOrientation
        let lineBox = fixBoundingBoxOrientation(bounds: line.boundingBox, orientation: orientation)
        let fontSize = lineBox.height
        for worditem in word.wordBlock {
            let wordBox = fixBoundingBoxOrientation(bounds: worditem.boundingBox, orientation: orientation)
            let word_bottomY = wordBox.minY
            let word_topY = wordBox.maxY
            let line_bottomY = lineBox.minY
            let line_topY = lineBox.maxY
            let word_bottomY_line_topY = word_bottomY - line_topY
            let line_bottomY_word_topY = line_bottomY - word_topY
            
            let isNeighbor_top = -threshold_lowerBound * fontSize < word_bottomY_line_topY && word_bottomY_line_topY < threshold_upperBound * fontSize
            let isNeighbor_bottom = -threshold_lowerBound * fontSize < line_bottomY_word_topY && line_bottomY_word_topY < threshold_upperBound * fontSize
            let isNeighbor_top_mask = isNeighbor_top && (searchDirection == .top || searchDirection == .both)
            let isNeighbor_bottom_mask = isNeighbor_bottom && (searchDirection == .bottom || searchDirection == .both)
            //連なる行には0.3 * fontSize以内の行間があるとする
            if isNeighbor_top_mask || isNeighbor_bottom_mask {
                let word_minX = wordBox.minX
                let line_minX = lineBox.minX
                //行の左端の差が1.5 * fontSize以内の場合には連なる行とする
                if abs(word_minX - line_minX) < fontSize * 1.5 {
                    neighborLines.append(worditem)
                }
            }
        }
        return neighborLines
    }
    
    //左右の1行を取得
    func getNeighborLine_horizontal(word: Word, line: VNRecognizedTextObservation, searchDirection : NeighborLineSearchDirection_horizontal) -> [VNRecognizedTextObservation] {
        var neighborLines: [VNRecognizedTextObservation] = []
        let orientation = uiImage!.imageOrientation
        let lineBox = fixBoundingBoxOrientation(bounds: line.boundingBox, orientation: orientation)
        let fontSize = lineBox.height
        for worditem in word.wordBlock {
            let wordBox = fixBoundingBoxOrientation(bounds: worditem.boundingBox, orientation: orientation)
            
            let word_maxX = wordBox.maxX
            let word_minX = wordBox.minX
            let line_maxX = lineBox.maxX
            let line_minX = lineBox.minX
            let isNeighbor_left = word_maxX < line_minX + 0.5 * fontSize
            let isNeighbor_right = line_maxX < word_minX + 0.5 * fontSize
            let isNeighbor_left_mask = isNeighbor_left && searchDirection == .left
            let isNeighbor_right_mask = isNeighbor_right && searchDirection == .right
            
            if isNeighbor_left_mask || isNeighbor_right_mask {
                let word_bottomY = wordBox.minY
                let word_topY = wordBox.maxY
                let line_topY = lineBox.maxY
                if word_bottomY < line_topY && line_topY < word_topY + fontSize {
                    neighborLines.append(worditem)
                }
            }
        }
        return neighborLines
    }
    
    enum NeighborLineSearchDirection {
        case top
        case bottom
        case both
    }
    enum NeighborLineSearchDirection_horizontal {
        case left
        case right
    }

}


class Word {
    var wordString: String = ""
    var meaningString: String = ""
    var meaningBlocks: [VNRecognizedTextObservation] = []
    var deletePriority: Int = 0
    var word: VNRecognizedTextObservation?
    var meaning: VNRecognizedTextObservation?
    var meaningCandidate: [VNRecognizedTextObservation] = []
    var meaningCandidates_en: [String] = []
    var wordBlock: [VNRecognizedTextObservation] = []
    var wordBlocks_ja: [VNRecognizedTextObservation] = []
    var exampleSentence_byBlock: [[VNRecognizedTextObservation]] = []
    var exampleSentenceString: String = ""
    init() {
        
    }
}
