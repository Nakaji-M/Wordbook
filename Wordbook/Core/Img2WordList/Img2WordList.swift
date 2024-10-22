//
//  Img2WordList.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/21.
//

import PhotosUI
import Vision
import CoreML
import NaturalLanguage

class Img2WordList{
    private let uiImage: UIImage
    private let scanIdiom: Bool
    init(uiImage: UIImage, scanIdiom: Bool){
        self.uiImage = uiImage
        self.scanIdiom = scanIdiom
    }
    func recognize() async throws -> [WordStoreItem] {
        do{
            let ocr = OCR(uiImage: uiImage)
            let recognizedTexts = try await ocr.recognize()
            let tableStructureDetector = try TableStructureDetector(uiImage: uiImage)
            let tableStructures = try tableStructureDetector.detect()
            let wordListGenerator = WordListGenerator(uiImage: uiImage, recognizedTexts: recognizedTexts, tableStructures: tableStructures, scanIdiom: self.scanIdiom)
            let (wordListRows, row_list, column_list, column_word) = try wordListGenerator.generateWordList()
            let meaningDetector = MeaningDetector(uiImage: uiImage, wordListRows: wordListRows, row_list: row_list, column_list: column_list, column_word: column_word)
            let wordListRows2 = try meaningDetector.detect()
            let wordStoreItemGenerator = WordListRow2WordStoreItemConverter(wordListRows: wordListRows2)
            let wordStoreItems = wordStoreItemGenerator.GenerateWordStoreItem()
            return wordStoreItems
            //return drawDetected(recognizedTexts: recognizedTexts, tableStructures: tableStructures)
        }
        catch let error{
            throw error
        }
    }
    
    func drawDetected(recognizedTexts: [RecognizedTextItem], tableStructures: [TableStructureItem]) -> UIImage{
        let imageSize = uiImage.size
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        uiImage.draw(at: CGPoint.zero)
        let ctx = UIGraphicsGetCurrentContext()
        for table in tableStructures{
            let box = VNImageRectForNormalizedRect(table.box, Int(imageSize.width), Int(imageSize.height))
            ctx?.addRect(box)
            ctx?.setLineWidth(9.0)
            ctx?.strokePath()
        }
        for recognizedText in recognizedTexts{
            let box = VNImageRectForNormalizedRect(recognizedText.box, Int(imageSize.width), Int(imageSize.height))
            ctx?.addRect(box)
            ctx?.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 0.5))
            ctx?.setLineWidth(9.0)
            ctx?.strokePath()
        }
        guard let drawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
            fatalError()
        }
        return drawnImage
    }
}

class OCR {
    private let uiImage: UIImage
    private var recognizedTexts: [RecognizedTextItem] = []
    private let customWords: [String] = []

    
    init(uiImage: UIImage){
        self.uiImage = uiImage
    }
    
    func recognize() async throws -> [RecognizedTextItem]{
        try recognizeText()
        removeOnlyNumbers()
        return recognizedTexts
    }
        
    //テキストの認識を行う
    private func recognizeText() throws -> Void{
        guard let cgImage = uiImage.cgImage else {
            throw Img2WordListError.OCRError
        }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(uiImage.imageOrientation))
        let request = VNRecognizeTextRequest(completionHandler: {[weak self] request, error in
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            self?.recognizedTexts = results.map{ RecognizedTextItem(text: $0.topCandidates(1).first!.string, box: self!.convertRect(rect: $0.boundingBox), rawClass: $0) }
        })
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLanguages = ["ja", "en"]
        request.customWords = customWords
        do{
            try requestHandler.perform([request])
        } catch {
            throw Img2WordListError.OCRError
        }
    }
    
    private func removeOnlyNumbers() {
        recognizedTexts.removeAll(where: { Int($0.text ) != nil})
    }
    
    private func convertRect(rect: CGRect) -> CGRect {
        // 左上原点の座標系に変換する
        // 座標系変換のため、 Y 軸方向に反転する
        return CGRect(x: rect.minX, y: (1.0 - rect.maxY), width: rect.width, height: rect.height)
    }
}

class TableStructureDetector{
    private let uiImage: UIImage
    var classes:[String] = []
    var yoloRequest:VNCoreMLRequest?
    
    init(uiImage: UIImage) throws{
        self.uiImage = uiImage
        self.yoloRequest = try initYoloRequest()
    }
    
    private func initYoloRequest() throws -> VNCoreMLRequest {
        do {
            let model = try yolov8s_custom_structure_all_best().model
            guard let classes = model.modelDescription.classLabels as? [String] else {
                throw Img2WordListError.TableStructureDetectorError
            }
            self.classes = classes
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch let error {
            throw Img2WordListError.TableStructureDetectorError
        }
    }

    func detect() throws -> [TableStructureItem] {
        guard let buffer = uiImage.convertToBuffer() else {
            throw Img2WordListError.TableStructureDetectorError
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer)
        try handler.perform([yoloRequest!])
        guard let results = yoloRequest?.results as? [VNRecognizedObjectObservation] else {
            throw Img2WordListError.TableStructureDetectorError
        }
        var detections:[TableStructureItem] = []
        for result in results {
            let box = CGRect(x: result.boundingBox.minX, y: 1 - result.boundingBox.maxY, width: result.boundingBox.width, height: result.boundingBox.height)
            guard let label = result.labels.first?.identifier as? String
            else {
                throw Img2WordListError.TableStructureDetectorError
            }
            let detection = TableStructureItem(box: box, confidence: result.confidence, label: label)
            detections.append(detection)
        }
        return detections
    }
}

class WordListGenerator{
    private let uiImage: UIImage
    private let recognizedTexts: [RecognizedTextItem]
    private let tableStructures: [TableStructureItem]
    private let scanIdiom: Bool
    private var wordListRows: [WordListRow] = []
    
    init(uiImage: UIImage, recognizedTexts: [RecognizedTextItem], tableStructures: [TableStructureItem], scanIdiom: Bool){
        self.uiImage = uiImage
        self.recognizedTexts = recognizedTexts
        self.tableStructures = tableStructures
        self.scanIdiom = scanIdiom
    }
    
    func generateWordList() throws -> ([WordListRow], [TableStructureItem], [TableStructureItem], TableStructureItem){
        let wordCandidates = try self.recognizeWordsFromPosition()
        let (row_list, column_list, column_word) = makeWordListRow(wordCandidates: wordCandidates)
        detectJapanese()
        return (wordListRows, row_list, column_list, column_word)
    }
    
    //認識した各テキストの位置から単語を認識する
    private func recognizeWordsFromPosition() throws -> [RecognizedTextItem] {
        if recognizedTexts.count == 0 {
            throw Img2WordListError.WordListGeneratorError
        }
        
        //見出し後のフォントサイズは上位4/5と考えられる
        //フォントサイズの大きい順にソートする
        var wordCandidates = self.recognizedTexts.sorted { (first, second) -> Bool in
            return first.box.height > second.box.height
        }[0 ..< (recognizedTexts.count - 1) * 4/5]
        
        //見出し語は英語
        if self.scanIdiom {
            wordCandidates = wordCandidates.filter { $0.text.matches( of: /^[a-zA-Z\s-]+$/).count != 0 }
        }else{
            wordCandidates = wordCandidates.filter { $0.text.matches( of: /^[a-zA-Z]+$/).count != 0 }
        }
        
        if wordCandidates.count == 0 {
            throw Img2WordListError.WordListGeneratorError
        }
        //位置が左寄りな順にソートする
        wordCandidates.sort { (first, second) -> Bool in
            return first.box.minX < second.box.minX
        }
        //x座標の第一四分位数を求める
        let X_1stQuater = wordCandidates[(wordCandidates.count - 1) / 4].box.minX
            wordCandidates = wordCandidates.filter {
                let this_X = $0.box.minX
                return (X_1stQuater - 0.05 < this_X) && (this_X < X_1stQuater + 0.05)
            }
        return Array(wordCandidates)
    }
    
    private func makeWordListRow(wordCandidates: [RecognizedTextItem]) -> ([TableStructureItem], [TableStructureItem], TableStructureItem) {
        func filterPointInsideBox(boxes: [CGRect], point: CGPoint) -> [CGRect]{
            let filtered = boxes.filter{
                $0.contains(point)
            }
            return filtered
        }
        
        self.wordListRows = wordCandidates.map{ word in
            let boxesBelongedTo = self.tableStructures.filter{ table in
                let mid_point = midPoint(bounds: word.box)
                return table.box.contains(mid_point)
            }
            return WordListRow(word: word, wordCellRowBoxes: boxesBelongedTo.filter{$0.isRow()},wordCellRowBoxes_noConflictToOtherWords: [] , wordCellColumnBoxes: boxesBelongedTo.filter{$0.isColumn()}, wordCellRowBox: CGRect.infinite, items: [], items_jp: [], meanings: [])
        }
        
        //単語の列を特定し、その列に含まれない単語を除外する
        let column_list = self.tableStructures.filter{$0.isColumn()}
        let column_word = column_list.max{ (col1, col2) in
            let count1 = self.wordListRows.map{ word in
                word.wordCellColumnBoxes.contains(col1) ? 1 : 0
            }.reduce(0, +)
            let count2 = self.wordListRows.map{ word in
                word.wordCellColumnBoxes.contains(col2) ? 1 : 0
            }.reduce(0, +)
            return count1 < count2
        } ?? TableStructureItem(box: .infinite, confidence: 0, label: nil)
        self.wordListRows = self.wordListRows.filter{ word in
            word.wordCellColumnBoxes.contains(column_word)
        }
        
        let row_list = self.tableStructures.filter{$0.isRow()}
        //各行と出現回数をタプル形式で保存
        let row_count_list = row_list.map{ row in
            let count = self.wordListRows.map{ word in
                word.wordCellRowBoxes.contains(row) ? 1 : 0
            }.reduce(0, +)
            return (row, count)
        }
        //wordCellRowBoxesから他の単語と重複している行を取り除いたものをwordCellRowBoxes_noConflictToOtherWordsとする
        for i in 0..<self.wordListRows.count{
            self.wordListRows[i].wordCellRowBoxes_noConflictToOtherWords = row_count_list.filter{ row_count in
                let row = row_count.0
                let count = row_count.1
                return count == 1 && self.wordListRows[i].wordCellRowBoxes.contains(row)
            }.map(\.0)
        }
        
        //上から順にソート
        self.wordListRows.sort {
            $0.word.box.minY < $1.word.box.minY
        }
        
        //wordListRowsのwordCellRowBoxを決定
        for i in 0..<self.wordListRows.count{
            //wordCellRowBoxの上限を決定
            var row_minY: CGFloat = 0
            if self.wordListRows[i].wordCellRowBoxes_noConflictToOtherWords.isEmpty {
                row_minY = self.wordListRows[i].word.box.minY
            }
            else {
                row_minY = self.wordListRows[i].wordCellRowBoxes_noConflictToOtherWords.min{$0.box.minY < $1.box.minY}!.box.minY
            }
            //wordCellRowBoxの下限を決定
            var row_maxY: CGFloat = 0
            if i == self.wordListRows.count-1 {
                row_maxY = row_list.max{ $0.box.maxY < $1.box.maxY }?.box.maxY ?? 1
            }
            else if self.wordListRows[i+1].wordCellRowBoxes_noConflictToOtherWords.isEmpty {
                row_maxY = self.wordListRows[i+1].word.box.minY
            }
            else {
                row_maxY = self.wordListRows[i+1].wordCellRowBoxes_noConflictToOtherWords.min{$0.box.minY < $1.box.minY}!.box.minY
            }
            self.wordListRows[i].wordCellRowBox = CGRect(x: 0, y: row_minY, width: 1, height: row_maxY-row_minY)
            //wordCellRowBoxに含まれるrecognizedTextsの要素を取り出す
            self.wordListRows[i].items = recognizedTexts.filter{self.wordListRows[i].wordCellRowBox.contains(midPoint(bounds: $0.box))}
        }
        return (row_list, column_list, column_word)
    }
    
    func detectJapanese(){
        let recognizer = NLLanguageRecognizer()
        for i in 0..<wordListRows.count{
            self.wordListRows[i].items_jp = self.wordListRows[i].items.filter{ isJapanese(text: $0.text, recognizer: recognizer) }
        }
    }
    
    private func isJapanese(text: String, recognizer: NLLanguageRecognizer) -> Bool{
        recognizer.reset()
        recognizer.processString(text)
        recognizer.languageConstraints = [.japanese, .english]
        let japaneseWordCount = text.matches( of: /[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}]/).count //平仮名、カタカナ、漢字の個数を検知
        return (recognizer.dominantLanguage == NLLanguage.japanese || japaneseWordCount >= 3)
    }
}

class MeaningDetector{
    private let uiImage: UIImage
    private var wordListRows: [WordListRow]
    private let row_list: [TableStructureItem]
    private let column_list: [TableStructureItem]
    private let column_word: TableStructureItem
    
    init(uiImage: UIImage, wordListRows: [WordListRow], row_list: [TableStructureItem], column_list: [TableStructureItem], column_word: TableStructureItem)
    {
        self.uiImage = uiImage
        self.wordListRows = wordListRows
        self.row_list = row_list
        self.column_list = column_list
        self.column_word = column_word
    }
    
    func detect() throws -> [WordListRow]{
        let meaning_position = try detectMeaningPosition()
        print(meaning_position)
        if meaning_position == .below{
            try detectBelow()
        }
        else if meaning_position == .right{
            try detectRight()
        }
        return wordListRows
    }
    
    private func detectMeaningPosition() throws -> MeaningPosition {
        //belowとなる条件は以下を満たすwordListRowがwordListRowsの2/3を超えることである
        //単語よりも下にtable rowがあり、
        //そのtable rowおいて単語の下に文字列長4文字以上かつ右端まで突っ切っていない日本語文字列がある
        var belowItemCount:Int = 0
        for row in wordListRows{
            //column_wordと位置が重なる日本語のtextを抽出
            let items_inside_jp = row.items_jp.filter{ item_jp in
                return column_word.box.contains(item_jp.box) //列方向ではは完全に包含されている必要がある(右端まで突っ切っていないことの確認)
            }
            let isItemLength4 = items_inside_jp.contains{$0.text.count >= 4} //文字列長4文字以上
            if items_inside_jp.count > 0 && isItemLength4 && midPoint(bounds: items_inside_jp.last!.box).y > midPoint(bounds: row.word.box).y{
                belowItemCount += 1
            }
        }
        if belowItemCount > Int(Double(wordListRows.count) * 0.67){
            return .below
        }else{
            return .right
        }
    }
    
    
    private func detectRight() throws {
        let column_meaning = column_list.sorted{ midPoint(bounds: $0.box).x < midPoint(bounds: $1.box).x }
            .first{
                midPoint(bounds: $0.box).x > midPoint(bounds: column_word.box).x
            } ?? TableStructureItem(box: CGRect(x: column_word.box.maxX, y: 0, width: 1-column_word.box.maxX, height: 1), confidence: 0, label: nil)
        for i in 0 ..< self.wordListRows.count {
            self.wordListRows[i].items_jp.sort(by: { $0.box.minY < $1.box.minY })
            self.wordListRows[i].meanings = self.wordListRows[i].items_jp.filter{ column_meaning.box.intersects($0.box) }
        }
    }
    
    private func detectBelow() throws {
        for i in 0 ..< self.wordListRows.count {
            //wordCellRowBoxに含まれるrowを抽出
            let rows_inside = row_list.filter{ wordListRows[i].wordCellRowBox.contains(midPoint(bounds: $0.box)) }
            let rows_below = rows_inside.sorted(by: { $0.box.minY < $1.box.minY })
                .filter{
                    midPoint(bounds: $0.box).y > wordListRows[i].word.box.maxY
                }
            wordListRows[i].items_jp.sort(by: { $0.box.minY < $1.box.minY })
            //rows_below,column_wordと位置が重なる日本語のtextを抽出
            let items_inside_jp = wordListRows[i].items_jp.filter{ item_jp in
                let isInsideRows = rows_below.contains{ row_below in
                    row_below.box.contains(midPoint(bounds: item_jp.box))
                }
                let isInsideColumn = column_word.box.containsPartially(rect: item_jp.box, rate: 0.85) //完全に包含されている
                return isInsideRows && isInsideColumn
            }
            if items_inside_jp.count > 0 {
                wordListRows[i].meanings = items_inside_jp
            } else{
                //column_wordと位置が重なる日本語のtextを抽出
                let items_inside_jp = wordListRows[i].items_jp.filter{ item_jp in
                    let isInsideColumn = column_word.box.contains(midPoint(bounds: item_jp.box)) //中心だけ包含されている
                    return isInsideColumn
                }
                if items_inside_jp.count > 0 {
                    wordListRows[i].meanings = items_inside_jp
                } else{
                    wordListRows[i].meanings = wordListRows[i].items_jp
                }
            }
        }
    }
    
    enum MeaningPosition{
        case below
        case right
    }
}

class WordListRow2WordStoreItemConverter{
    let wordListRows: [WordListRow]
    
    init(wordListRows: [WordListRow]) {
        self.wordListRows = wordListRows
    }
    
    func GenerateWordStoreItem() -> [WordStoreItem] {
        func intersectY(rect1: CGRect, rect2: CGRect) -> Bool {
            let bool1 = rect1.minY < midPoint(bounds: rect2).y && midPoint(bounds: rect2).y < rect1.maxY
            let bool2 = rect2.minY < midPoint(bounds: rect1).y && midPoint(bounds: rect1).y < rect2.maxY
            return bool1 && bool2
        }
        
        var wordStoreItems: [WordStoreItem] = []
        for word in wordListRows {
            var word = word
            var meaningString = ""
            for i in 0..<word.meanings.count {
                if i != word.meanings.count - 1 {
                    if intersectY(rect1: word.meanings[i].box, rect2: word.meanings[i+1].box) && word.meanings[i+1].box.minY < word.meanings[i].box.minY {
                        (word.meanings[i], word.meanings[i+1]) = (word.meanings[i+1], word.meanings[i])
                    }
                }
                meaningString = meaningString + "\n" + word.meanings[i].text
            }
            let wordStoreItem = WordStoreItem(word: word.word.text, meaning: meaningString, example: "", note: "", isMemorized: false, isFavorite: false)
            wordStoreItems.append(wordStoreItem)
        }
        return wordStoreItems
    }
}

struct WordListRow{
    let word: RecognizedTextItem
    let wordCellRowBoxes: [TableStructureItem]
    var wordCellRowBoxes_noConflictToOtherWords: [TableStructureItem]
    let wordCellColumnBoxes: [TableStructureItem]
    var wordCellRowBox: CGRect
    var items: [RecognizedTextItem]
    var items_jp: [RecognizedTextItem]
    var meanings: [RecognizedTextItem]
}

struct TableStructureItem: Equatable {
    let box:CGRect
    let confidence:Float
    let label:String?
    
    static func == (lhs: TableStructureItem, rhs: TableStructureItem) -> Bool{
        return lhs.box == rhs.box
    }
    
    func isRow() -> Bool{
        return label == "table row" || label == "table projected row header"
    }
    
    func isColumn() -> Bool{
        return label == "table column" || label == "table column header"
    }
}

struct RecognizedTextItem{
    let text: String
    let box: CGRect
    let rawClass: VNRecognizedTextObservation
}


enum Img2WordListError: Error{
    case OCRError
    case TableStructureDetectorError
    case WordListGeneratorError
}

extension UIImage {
        
    func convertToBuffer() -> CVPixelBuffer? {
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer)
        
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pixelData,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        default:
            self = .up
        }
    }
}

func midPoint(bounds: CGRect) -> CGPoint {
    let midX = bounds.minX + bounds.width / 2
    let midY = bounds.minY + bounds.height / 2
    return CGPoint(x: midX, y: midY)
}

extension CGRect{
    func containsPartially(rect: CGRect, rate: Double) -> Bool {
        let intersect = intersect(a: self, b: rect)
        let area = rect.width * rect.height
        let intersectArea = intersect.width * intersect.height
        return intersectArea / area > rate
    }
}

func intersect(a: CGRect, b: CGRect) -> CGRect {
    let sx = max(a.minX, b.minX);
    let sy = max(a.minY, b.minY);
    let ex = min(a.maxX, b.maxX);
    let ey = min(a.maxY, b.maxY);
    
    let w = ex - sx;
    let h = ey - sy;
    if (w > 0 && h > 0) {
        return CGRect(x: sx, y: sy, width: w, height: h)
    }
    return CGRect.zero // 重なっていない
}

