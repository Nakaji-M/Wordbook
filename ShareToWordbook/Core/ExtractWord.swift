//
//  ExtractWord.swift
//  ShareToWordbook
//
//  Created by Masanori on 2024/09/01.
//

import Foundation

func extractWord(url_string: String, title: String, keywords: String) -> String{
    var word = ""
    if let url = URL(string: url_string) {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true){
            //Queryとtitleに共通して含まれる文字列を抽出
            if let queries = urlComponents.queryItems{
                let wordCandidates = queries.map({
                    let value = $0.value!
                    return value.contains("+") ? value.replacingOccurrences(of: "+", with: " ") : value
                })
                    .filter({title.lowercased().contains($0.lowercased())})
                word = wordCandidates.first ?? ""
            }
            
            if word == "" {
                //Pathとtitleに共通して含まれる文字列を抽出
                let pathComponents = urlComponents.path.components(separatedBy: "/")
                let wordCandidates = pathComponents.map({
                    let value = $0
                    return value.contains("+") ? value.replacingOccurrences(of: "+", with: " ") : value
                })
                    .filter({title.lowercased().contains($0.lowercased())})
                word = wordCandidates.last ?? ""
            }
            
            if word == "" {
                //keywordsとtitleに共通して含まれる文字列を抽出
                let keywordCandidates = keywords.components(separatedBy: ",")
                    .map({$0.trimmingCharacters(in: .whitespacesAndNewlines)})
                    .filter({
                        let contain = title.lowercased().contains($0.lowercased())
                        let isHalfWidth = $0.range(of: "[^ -~]", options: .regularExpression) == nil
                        return contain && isHalfWidth
                    })
                word = keywordCandidates.first ?? ""
            }
        }
    }
    if word == "" {
        word = title
    }
    return word
}
