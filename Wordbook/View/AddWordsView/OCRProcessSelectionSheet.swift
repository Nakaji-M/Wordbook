//
//  OCRProcessSelectionSheet.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/08.
//

import SwiftUI

struct OCRProcessSelectionSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var ocrSelectionSheetViewModel: AddWordsViewModel

    var body: some View {
        NavigationStack{
            VStack(alignment: .leading){
                Form{
                    Text("ページ上部に例文がまとまって載っている単語帳を読み込む際には、例文を隠して写真を撮るとうまくいきやすいです。")
                    Section{
                        //例文をLLMで生成するかのチェックボックス
                        Toggle(isOn: $ocrSelectionSheetViewModel.isGenerateExample) {
                            Text("例文をLLMで生成する")
                        }
                        
                        //意味を写真から読み込むか内蔵辞書から読み込むかのチェックボックス
                        Toggle(isOn: $ocrSelectionSheetViewModel.isMeaningFromDictionary) {
                            Text("意味を写真から読み込まずにアプリ内蔵辞書の意味を使用する")
                        }
                    }
                }.scrollDisabled(true)
                Button {
                        ocrSelectionSheetViewModel.ocrProcessSelection = .auto
                        isPresented = false
                } label: {
                    Text("読み取り開始")
                        .padding()
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.listBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("カメラ・アルバムからの追加")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear() {
                ocrSelectionSheetViewModel.ocrProcessSelection = .dismiss
            }
        }
    }
}
