//
//  TableStructureDetector.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import PhotosUI
import CoreML
import Vision

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
