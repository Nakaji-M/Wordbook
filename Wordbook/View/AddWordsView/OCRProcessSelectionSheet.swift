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
    @ObservedObject var manualProcessSelectionViewModel: ManualProcessSelectionViewModel

    var body: some View {
        NavigationStack{
            VStack(alignment: .leading){
                Form{
                    Section{
                        //例文をLLMで生成するかのチェックボックス
                        Toggle(isOn: $ocrSelectionSheetViewModel.isGenerateExample) {
                            Text("例文をLLMで生成する")
                        }
                        
                        //意味を写真から読み込むか内蔵辞書から読み込むかのチェックボックス
                        Toggle(isOn: $ocrSelectionSheetViewModel.isMeaningFromDictionary) {
                            Text("意味を写真から読み込まずにアプリ内蔵辞書の意味を使用する")
                        }
                    }header: {
                        Text("以下をカスタマイズした後、「自動」もしくは「手動」を押してください")
                    }
                }.scrollDisabled(true)
                    
                Spacer()
                
                Text("手動読み取りは単語と意味の位置関係などを手動で指定した後読み込む方式です。手動読み取りを選択し、意味の位置だけを指定するのがおすすめです。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.horizontal)
                
                HStack{
                    Button {
                        ocrSelectionSheetViewModel.ocrProcessSelection = .auto
                        isPresented = false
                    } label: {
                        Text("自動読み取り")
                            .padding()
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                    
                    NavigationLink(destination: ManualProcessSelectionView(isPresented: $isPresented, ocrSelectionSheetViewModel: ocrSelectionSheetViewModel, manualProcessSelectionViewModel: manualProcessSelectionViewModel)){
                        Text("手動読み取り")
                            .padding()
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
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
            .onAppear() {
                ocrSelectionSheetViewModel.ocrProcessSelection = .dismiss
            }
        }
    }
}


struct ManualProcessSelectionView: View {
    @Binding var isPresented: Bool
    @ObservedObject var ocrSelectionSheetViewModel: AddWordsViewModel
    @ObservedObject var manualProcessSelectionViewModel: ManualProcessSelectionViewModel
    
    var body: some View {
        VStack(alignment: .leading){
            Form{
                Section{
                    Text("意味の位置")
                    
                    Picker("", selection: $manualProcessSelectionViewModel.whereIsMeaning) {
                        Text("単語の右").tag(MeaningPosition.right)
                        Text("単語の上").tag(MeaningPosition.top)
                        Text("単語の下").tag(MeaningPosition.below)
                    }
                    .pickerStyle(.segmented)
                }.listRowSeparator(.hidden)
                
                Section{
                    Toggle("1ページあたりの単語数を手動で指定する", isOn: $manualProcessSelectionViewModel.isManualWordsPerPage)
                        .toggleStyle(CheckBoxToggleStyle())
                    
                    TextField("単語数", text: $manualProcessSelectionViewModel.wordsPerPageString)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .padding(.leading, 20)
                }.listRowSeparator(.hidden)
            }
            .scrollDisabled(true)
            Spacer()
            
            Button {
                ocrSelectionSheetViewModel.ocrProcessSelection = .manual
                isPresented = false
            } label: {
                Text("完了")
                    .padding()
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
            }
            .disabled((manualProcessSelectionViewModel.wordsPerPage <= 0) && manualProcessSelectionViewModel.isManualWordsPerPage)
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
        .navigationTitle("手動設定")
    }
}
