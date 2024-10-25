//
//  OCR.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import PhotosUI
import Vision

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
