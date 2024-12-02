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
    private var recognizedTexts: [RecognizedTextItem] = []
    private var tableStructures: [TableStructureItem] = []
    
    init(uiImage: UIImage, scanIdiom: Bool){
        self.uiImage = uiImage
        self.scanIdiom = scanIdiom
    }
    func recognizeDebug() async throws -> ([Word], UIImage) {
        return (try await recognize(), drawDetected(recognizedTexts: recognizedTexts, tableStructures: tableStructures))
    }
    func recognize() async throws -> [Word] {
        do{
            let ocr = OCR(uiImage: uiImage)
            recognizedTexts = try await ocr.recognize()
            let tableStructureDetector = try TableStructureDetector(uiImage: uiImage)
            self.tableStructures = try tableStructureDetector.detect()
            let wordListGenerator = WordListGenerator(recognizedTexts: recognizedTexts, tableStructures: tableStructures, scanIdiom: self.scanIdiom)
            var wordListRows: [WordListRow]
            let row_list: [TableStructureItem], column_list: [TableStructureItem], column_word: TableStructureItem
            (wordListRows, self.tableStructures, row_list, column_list, column_word) = try wordListGenerator.generateWordList()
            let meaningDetector = MeaningDetector(wordListRows: wordListRows, row_list: row_list, column_list: column_list, column_word: column_word)
            wordListRows = try meaningDetector.detect()
            let wordGenerator = WordListRow2WordConverter(wordListRows: wordListRows)
            let word = wordGenerator.GenerateWord()
            return word
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
        return label == "table row" || label == "table column header" || label == "table projected row header"
    }
    
    func isColumn() -> Bool{
        return label == "table column"
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

