//
//  RecognizedWordsView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/11.
//

import SwiftUI

//UIImageの配列を受け取り、TextRecognitionを行い、認識結果を表示するView
struct AddWordsFromAutoView : View {
    @Binding var path: [AddWordsPath]
    //UIImageの配列を受け取る変数
    var uiImages: [UIImage]
    @State private var showLoadingAlert = false
    @ObservedObject var ocrOption: OCROption
    //認識結果の文字列を格納する変数
    @State var recognitionResult: [Word] = []
    @State var rowID: UUID?
    @State var alertMessage: String = ""
    @State private var selectedTag: Tag?
    @State var isFirstAppear: Bool = true
    @Environment(\.modelContext) private var context
#if DEBUG
    @State var detectedImg: UIImage?
#endif
        
    var body: some View {
        VStack {
            List {
                Section(header:
                        //Tagを設定するためのページ
                        Button(action: {
                            path.append(.tagSelection(selectedTag: $selectedTag))
                        }) {
                            HStack(spacing: 8) {
                                Label("Tag", systemImage: "tag")
                                Spacer()
                                Text(selectedTag?.name ?? "未設定")
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .opacity(0.5)
                            }
                            .padding(.vertical)
                        }
                )
                {
#if DEBUG
                    if let detectedImg {
                        Image(uiImage: detectedImg)
                            .resizable()
                            .scaledToFill()
                    }
#endif
                    ForEach($recognitionResult) { $rowViewModel in
                        ResultsRow(word: $rowViewModel)
                            .contentShape(Rectangle())
                        // セルにスワイプすると編集ボタンが表示されます
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(action: {
                                    recognitionResult.removeAll { $0.id == rowViewModel.id }
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                                Button(action: {
                                    rowID = rowViewModel.id
                                }) {
                                    Label("Edit", systemImage: "rectangle.and.pencil.and.ellipsis")
                                }
                            }
                            .onTapGesture(perform: {
                                rowID = rowViewModel.id
                            })
                            .sheet(isPresented: Binding<Bool>(
                                get: { rowViewModel.id == rowID },
                                set: { _ in
                                    rowID = nil
                                })
                            ) {
                                EditSheet(word: $rowViewModel)
                                    .presentationDetents([.large])
                            }
                    }.onMove(perform: { indices, newOffset in
                        self.recognitionResult.move(fromOffsets: indices, toOffset: newOffset)
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .overlay(
                ZStack {
                    if showLoadingAlert {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        CommonLoadingAlertView(alertMessage: $alertMessage)
                    }
                }
            )
            .navigationTitle("認識結果")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        alertMessage = "保存中..."
                        showLoadingAlert = true
                        //orderの最大値を取得
                        var maxorder = getMaxOrder(tag: selectedTag?.id, context: context)
                        for word in recognitionResult{
                            word.tag = selectedTag?.id
                            word.order = maxorder + 1
                            maxorder += 1
                            context.insert(word)
                        }
                        showLoadingAlert = false
                        path = []
                    }) {
                        Label("保存", systemImage: "square.and.arrow.down")
                            .labelStyle(TitleOnlyLabelStyle())
                    }
                }
            }
            .task {
                //タグ選択から戻ってきた時には表示しない
                if isFirstAppear {
                    alertMessage = "文字認識中..."
                    showLoadingAlert = true
                    // 画像からテキストを認識する処理を実行
                    for uiImage in uiImages {
                        let settingsStoreService = SettingsStoreService()
                        let scanIdiom = settingsStoreService.loadBoolSetting(settingKey: .scanIdiom)
                        let img2WordList = Img2WordList(uiImage: uiImage, scanIdiom: scanIdiom)
                        do{
#if DEBUG
                            let (recognizedWords, img) = try await img2WordList.recognizeDebug()
                            self.detectedImg = img
#else
                            let recognizedWords = try await img2WordList.recognize()
#endif
                            recognitionResult += recognizedWords
                        } catch{
                            
                        }
                    }
                    if ocrOption.isGenerateExample {
                        alertMessage = "例文生成中..."
                        let llm = await ExampleSentenceGeneration()
                        for i in 0..<recognitionResult.count {
                            recognitionResult[i].example = await llm.generateExampleSentence(word: recognitionResult[i].word)
                        }
                    }
                    if ocrOption.isMeaningFromDictionary {
                        alertMessage = "意味生成中..."
                        let dictionaryService = DictionaryService()
                        for i in 0..<recognitionResult.count {
                            if let meaning = dictionaryService.getItemFromWord_vague(word: recognitionResult[i].word){
                                recognitionResult[i].meaning = meaning.mean
                            } else {
                                recognitionResult[i].meaning = "意味が見つかりませんでした"
                            }
                        }
                    }
                    isFirstAppear = false
                    showLoadingAlert = false
                }
            }
        }
    }
}

struct ResultsRow: View {
    @Binding var word: Word
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8){
                Text(word.word)
                    .font(.headline)
                Label(word.meaning, systemImage: "pencil")
                Label(word.example, systemImage: "text.bubble")
            }
            Spacer()
        }
        .padding(.vertical)

    }
}

// 編集画面
struct EditSheet: View {
    @Binding var word: Word
    @State var showLoadingAlert: Bool = false //実質使用していない
    @State var alertMessage: String = "" //実質使用していない
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 8){
                    CommonWordEditView(word: $word)
                }
                .padding(.all)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitle("単語の編集")
        }
    }
}
