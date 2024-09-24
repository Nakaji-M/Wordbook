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

class TextRecognition {
    private var uiImage: UIImage?
    private var existHorizontalLines = true
    private var existVerticalLines = true
    
    private var wordsPerPage = 0
    private var recognizedTexts: [VNRecognizedTextObservation] = []
    private var whereIsMeaning: MeaningPosition = .right
    private var isMeaningRed: Bool = false
    private var words: [VNRecognizedTextObservation] = []
    private var ocrProcessSelection: OCRProcessSelection = .auto
    private var meanings: [VNRecognizedTextObservation] = []
    
    enum MeaningPosition {
        case right
        case below
    }
    
    init(uiImage: UIImage) {
        self.uiImage = uiImage
    }
    
    func recognize() {
        recognizeText()
        removeOnlyNumbers()
        recognizeWordsFromPosition()
        let meaningCandidates = recognizeMeaningFromPosition()
        Task {
            await naturalLanguageProcessing(meaningCandidates: meaningCandidates)
        }
    }
    
    //矩形の検出を行う
    func detectRectangle() {
        guard let cgImage = uiImage?.cgImage else {
            return
        }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNDetectRectanglesRequest(completionHandler: detectRectangleHandler)
        request.minimumSize = 0.01
        request.maximumObservations = 1000
        request.minimumAspectRatio = 0.1
        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error)")
        }
    }
    
    private func detectRectangleHandler(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRectangleObservation] else {
            return
        }
        
        for result in results {
            let topLeft = result.topLeft
            let topRight = result.topRight
            let bottomLeft = result.bottomLeft
            let bottomRight = result.bottomRight
            if existHorizontalLines {
                let topLeftPoint = CGPoint(x: topLeft.x, y: topLeft.y)
                let topRightPoint = CGPoint(x: topRight.x, y: topRight.y)
                let bottomLeftPoint = CGPoint(x: bottomLeft.x, y: bottomLeft.y)
                let bottomRightPoint = CGPoint(x: bottomRight.x, y: bottomRight.y)
                print(topLeftPoint)
                print(topRightPoint)
                print(bottomLeftPoint)
                print(bottomRightPoint)
            }
        }
        //見つけた長方形を元の画像上に全て描画する
        guard let cgImage = uiImage?.cgImage else {
            return
        }
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
            for result in results {
                let topLeft = result.topLeft
                let topRight = result.topRight
                let bottomLeft = result.bottomLeft
                let bottomRight = result.bottomRight
                let path = UIBezierPath()
                path.move(to: CGPoint(x: topLeft.x * imageSize.width, y: topLeft.y * imageSize.height))
                path.addLine(to: CGPoint(x: topRight.x * imageSize.width, y: topRight.y * imageSize.height))
                path.addLine(to: CGPoint(x: bottomRight.x * imageSize.width, y: bottomRight.y * imageSize.height))
                path.addLine(to: CGPoint(x: bottomLeft.x * imageSize.width, y: bottomLeft.y * imageSize.height))
                path.close()
                UIColor.black.setStroke()
                path.lineWidth = 10
                path.stroke()
            }
        }
        //画像をフォトアプリに保存する
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
    }
    
    //紙の文書の範囲を検出する.vndetectdocumentsegmentationrequestを使用する
    func detectDocument() {
        guard let cgImage = uiImage?.cgImage else {
            return
        }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNDetectDocumentSegmentationRequest(completionHandler: detectDocumentHandler)
        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error)")
        }
    }
    
    private func detectDocumentHandler(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRectangleObservation] else {
            return
        }
        
        for result in results {
            let topLeft = result.topLeft
            let topRight = result.topRight
            let bottomLeft = result.bottomLeft
            let bottomRight = result.bottomRight
            if existHorizontalLines {
                let topLeftPoint = CGPoint(x: topLeft.x, y: topLeft.y)
                let topRightPoint = CGPoint(x: topRight.x, y: topRight.y)
                let bottomLeftPoint = CGPoint(x: bottomLeft.x, y: bottomLeft.y)
                let bottomRightPoint = CGPoint(x: bottomRight.x, y: bottomRight.y)
                print(topLeftPoint)
                print(topRightPoint)
                print(bottomLeftPoint)
                print(bottomRightPoint)
            }
        }
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
        /*
         for result in results {
         guard let candidate = result.topCandidates(1).first else {
         continue
         }
         print(candidate.string)
         }
         */
    }
    
    func removeOnlyNumbers() {
        recognizedTexts.removeAll(where: { Int($0.topCandidates(1).first!.string ) != nil})
    }
    
    func convert(boundingBox: CGRect, to bounds: CGRect) -> CGRect {
        let imageWidth = bounds.width
        let imageHeight = bounds.height
        
        // Begin with input rect.
        var rect = boundingBox
        
        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.minX
        rect.origin.y = (1 - rect.maxY) * imageHeight + bounds.minY
        
        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight
        
        return rect
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
    
    //認識したテキストの位置を把握する
    func recognizeWordsFromPosition() {
        let orientation = uiImage!.imageOrientation
        print("orientation", orientation)
        //フォントサイズの大きい順にソートする
        recognizedTexts.sort { (first, second) -> Bool in
            let firstBox = fixBoundingBoxOrientation(bounds: first.boundingBox, orientation: orientation)
            let secondBox = fixBoundingBoxOrientation(bounds: second.boundingBox, orientation: orientation)
            return firstBox.height > secondBox.height
        }
        
        //見出し後のフォントサイズは上位2/3と考えられる
        var wordCandidates = recognizedTexts[0 ..< recognizedTexts.count * 2 / 3]
        //見出し語は英語
        wordCandidates = wordCandidates.filter { $0.topCandidates(1).first!.string.matches( of: /^[a-zA-Z]+$/).count != 0 }
        //位置が左寄りな順にソートする
        wordCandidates.sort { (first, second) -> Bool in
            let firstbox = fixBoundingBoxOrientation(bounds: first.boundingBox, orientation: orientation)
            let secondbox = fixBoundingBoxOrientation(bounds: second.boundingBox, orientation: orientation)
            return firstbox.minX < secondbox.minX
        }
        //第一四分位数を求める
        let boundingbox_1stQuater = wordCandidates[wordCandidates.count / 4].boundingBox
        let X_1stQuater = fixBoundingBoxOrientation(bounds:boundingbox_1stQuater, orientation: orientation).minX
        if(ocrProcessSelection == .auto){
            wordCandidates = wordCandidates.filter {
                let this_X = fixBoundingBoxOrientation(bounds:$0.boundingBox, orientation: orientation).minX
                return (X_1stQuater - 0.05 < this_X) && (this_X < X_1stQuater + 0.05)
            }
        } else {
            //Y座標が四分位数と近い順にwordsPerPage個選ぶ
            wordCandidates.sort{ (first, second) -> Bool in
                let firstbox = fixBoundingBoxOrientation(bounds: first.boundingBox, orientation: orientation)
                let secondbox = fixBoundingBoxOrientation(bounds: second.boundingBox, orientation: orientation)
                return abs(firstbox.minX - X_1stQuater) < abs(secondbox.minX - X_1stQuater)
            }
            wordCandidates = wordCandidates[0 ..< wordsPerPage]
        }
        self.words = Array(wordCandidates)
    }
    
    func recognizeMeaningFromPosition() -> [[VNRecognizedTextObservation]]{
        var wordBlocks = [ [VNRecognizedTextObservation] ]()
        let orientation = uiImage!.imageOrientation
        //位置が上寄りな順にソートする
        self.words.sort{
            let firstbox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
            let secondbox = fixBoundingBoxOrientation(bounds: $1.boundingBox, orientation: orientation)
            return firstbox.minY > secondbox.minY
        }
        //wordBlocksの作成
        for i in 0 ..< self.words.count {
            var previousWord_bottomY = (i > 0) ? fixBoundingBoxOrientation(bounds: self.words[i - 1].boundingBox, orientation: orientation).minY : 1.0
            let word = self.words[i]
            let word_bottomY = fixBoundingBoxOrientation(bounds: word.boundingBox, orientation: orientation).minY
            let word_topY = fixBoundingBoxOrientation(bounds: word.boundingBox, orientation: orientation).maxY
            var nextWord_topY = (i < self.words.count - 1) ? fixBoundingBoxOrientation(bounds: self.words[i + 1].boundingBox, orientation: orientation).maxY : 0.0
            
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
            wordBlocks.append(wordBlock)
        }
        
        var meaningCandidates = [[VNRecognizedTextObservation]]()
        var wordBlocks_ja : [[VNRecognizedTextObservation]] = []
        //日本語のみを取得
        for i in 0 ..< wordBlocks.count {
            wordBlocks_ja.append(wordBlocks[i].filter{
                let recognizer = NLLanguageRecognizer()
                recognizer.processString($0.topCandidates(1).first!.string)
                return recognizer.dominantLanguage == NLLanguage.japanese
            }
            )
        }
        //単語の右側に意味がある場合にwords_max_X、max_Xを用いる
        let words_max_X = words.max{
            fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation).maxX > fixBoundingBoxOrientation(bounds: $1.boundingBox, orientation: orientation).maxX
        }
        let max_X = fixBoundingBoxOrientation(bounds: words_max_X!.boundingBox, orientation: orientation).maxX
        
        for i in 0 ..< wordBlocks_ja.count{
            var meaningCandidate = [VNRecognizedTextObservation]()
            if (ocrProcessSelection == .manual && whereIsMeaning == .right) || ocrProcessSelection == .auto {
                var meaningCandidate_right = wordBlocks_ja[i].filter{
                    let thisBox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    return thisBox.minX > max_X
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
            if (ocrProcessSelection == .manual && whereIsMeaning == .below) || ocrProcessSelection == .auto {
                //単語の下側に意味がある場合
                var meaningCandidate_below = wordBlocks_ja[i].filter{
                    let thisBox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    return thisBox.minY > fixBoundingBoxOrientation(bounds: self.words[i].boundingBox, orientation: orientation).maxY
                }
                meaningCandidate_below.sort{
                    let firstbox = fixBoundingBoxOrientation(bounds: $0.boundingBox, orientation: orientation)
                    let secondbox = fixBoundingBoxOrientation(bounds: $1.boundingBox, orientation: orientation)
                    return firstbox.minY < secondbox.minY
                }
                //意味の候補が2つ以上ある場合は上位3つを取得
                if meaningCandidate_below.count > 0 {
                    let num = min(3, meaningCandidate_below.count)
                    meaningCandidate += Array(meaningCandidate_below[0 ..< num])
                }
                
            }
            meaningCandidates.append(meaningCandidate)
        }
        
        return meaningCandidates
    }
    
    func model(forLanguage: TranslateLanguage) -> TranslateRemoteModel {
      return TranslateRemoteModel.translateRemoteModel(language: forLanguage)
    }
    
    func naturalLanguageProcessing(meaningCandidates: [[VNRecognizedTextObservation]]) async {
        let model = self.model(forLanguage: .japanese)
        let modelManager = ModelManager.modelManager()
        let conditions = ModelDownloadConditions(
            allowsCellularAccess: true,
            allowsBackgroundDownloading: true
        )
        if !modelManager.isModelDownloaded(model) {
            modelManager.download(model, conditions: conditions)
        }

        for word in words {
            let wordString = word.topCandidates(1).first!.string
            print("word", wordString)
        }
        // Create an Japanese-English translator:
        let options = TranslatorOptions(sourceLanguage: .japanese, targetLanguage: .english)
        let japaneseEnglishTranslator = Translator.translator(options: options)
        
        japaneseEnglishTranslator.downloadModelIfNeeded(with: conditions) { error in
            guard error == nil else { return }
            // Model downloaded successfully. Okay to start translating.
            var meaningCandidates_english : [[String]] = []

            for i in 0..<meaningCandidates.count {
                var meaningCandidates_english_i : [String] = []
                for j in 0..<meaningCandidates[i].count {
                    let meaning = meaningCandidates[i][j].topCandidates(1).first!.string
                    print("meaning", meaning)
                    japaneseEnglishTranslator.translate(meaning) { translatedText, error in
                        guard error == nil, let translatedText = translatedText else { return }
                        print("translatedText", translatedText)
                        meaningCandidates_english_i.append(translatedText)
                        print("translatedText", translatedText)
                    }
                }
                meaningCandidates_english.append(meaningCandidates_english_i)
            }
            
            //類似度が高い単語を取得する
            let embedding = NLEmbedding.wordEmbedding(for: .english)
            self.meanings = []
            for i in 0..<self.words.count {
                let word = self.words[i].topCandidates(1).first!.string
                let similar_meaning = meaningCandidates_english[i].max { (first, second) -> Bool in
                    //first, secondを単語ごとに分ける
                    let firsts = first.split(separator: " ")
                    let seconds = second.split(separator: " ")
                    let similarity_first_sum = firsts.reduce(0.0) { (result, item) -> Double in
                        return result + (embedding?.distance(between: word, and: String(item)) ?? 0)
                    }
                    let similarity_second_sum = seconds.reduce(0.0) { (result, item) -> Double in
                        return result + (embedding?.distance(between: word, and: String(item)) ?? 0)
                    }
                    return similarity_first_sum / Double(first.count) > similarity_second_sum / Double(second.count)
                }
                let similar_meaning_idx = meaningCandidates_english[i].firstIndex(of: similar_meaning!)
                self.meanings.append( meaningCandidates[i][similar_meaning_idx!] )
                print("word", word, "meaning", similar_meaning!)
        }
        }
        
    }
}
