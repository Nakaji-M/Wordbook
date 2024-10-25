//
//  WordListGenerator.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import NaturalLanguage

class WordListGenerator{
    private let recognizedTexts: [RecognizedTextItem]
    private var tableStructures: [TableStructureItem]
    private let scanIdiom: Bool
    private var wordListRows: [WordListRow] = []
    
    init(recognizedTexts: [RecognizedTextItem], tableStructures: [TableStructureItem], scanIdiom: Bool){
        self.recognizedTexts = recognizedTexts
        self.tableStructures = tableStructures
        self.scanIdiom = scanIdiom
    }
    
    func generateWordList() throws -> ([WordListRow], [TableStructureItem], [TableStructureItem], [TableStructureItem], TableStructureItem){
        let wordCandidates = try self.recognizeWordsFromPosition()
        self.addColumn(wordCandidates: wordCandidates) //一部の列が検出できなかったとき用
        let (row_list, column_list, column_word) = makeWordListRow(wordCandidates: wordCandidates)
        detectJapanese()
        return (wordListRows, tableStructures, row_list, column_list, column_word)
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
    
    private func addColumn(wordCandidates: [RecognizedTextItem]) {
        var column_list = self.tableStructures.filter{$0.isColumn()}
        //column同士に囲まれた領域もcolumnの可能性がある
        column_list.sort{ $0.box.minX < $1.box.minX }
        var column_list_add: [TableStructureItem] = []
        for i in 0..<column_list.count - 1 {
            if column_list[i+1].box.minX - column_list[i].box.maxX > 0 {
                let cgRect = CGRect(x: column_list[i].box.maxX, y: column_list[i].box.minY, width: column_list[i+1].box.minX - column_list[i].box.maxX, height: column_list[i].box.maxY - column_list[i].box.minY)
                if recognizedTexts.filter({cgRect.contains(midPoint(bounds: $0.box))}).count > (wordCandidates.count * 2/3) {
                    column_list_add.append(TableStructureItem(box: cgRect, confidence: 0, label: "table column"))
                }
            }
        }
        tableStructures = tableStructures + column_list_add
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
                let max_row_max = row_list.max{ $0.box.maxY < $1.box.maxY }?.box.maxY ?? 1
                if max_row_max > wordListRows[i].word.box.maxY {
                    row_maxY = max_row_max
                }else { //最後の単語に対応する行が検知されなかったときの対策
                    row_maxY = 1
                }
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
