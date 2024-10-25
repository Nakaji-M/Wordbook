//
//  MeaningDetector.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import Foundation

class MeaningDetector{
    private var wordListRows: [WordListRow]
    private let row_list: [TableStructureItem]
    private let column_list: [TableStructureItem]
    private let column_word: TableStructureItem
    
    init(wordListRows: [WordListRow], row_list: [TableStructureItem], column_list: [TableStructureItem], column_word: TableStructureItem)
    {
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
                return column_word.box.containsPartially(rect: item_jp.box, rate: 0.80) //列方向ではは完全に包含されている必要がある(右端まで突っ切っていないことの確認)
            }
            let isItemLength4 = items_inside_jp.contains{$0.text.count >= 4} //文字列長4文字以上
            if items_inside_jp.count > 0 && isItemLength4 && midPoint(bounds: items_inside_jp.last!.box).y > midPoint(bounds: row.word.box).y{
                belowItemCount += 1
            }
        }
        if belowItemCount > wordListRows.count * 3/5 {
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
                let isInsideColumn = column_word.box.containsPartially(rect: item_jp.box, rate: 0.80) //完全に包含されている
                return isInsideRows && isInsideColumn
            }
            if items_inside_jp.count > 0 && items_inside_jp.contains(where: {$0.text.count >= 2}) {
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
