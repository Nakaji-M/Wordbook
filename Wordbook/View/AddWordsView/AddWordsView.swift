//
//  AddWordsView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/07.
//

import SwiftUI
import PhotosUI

enum Path: Hashable, Equatable {
    case textRecognitionResult([UIImage], AddWordsViewModel)
    case tagSelection(Binding<Tag?>)
    case addFromText
    case addFromTap([UIImage])
    case addFromTapMeanings([TapItem], [UIImage])
    case tapResult([TapItem])
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
    
    static func == (lhs: Path, rhs: Path) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    private var rawValue: Int {
        switch self {
            case .textRecognitionResult:
                return 0
            case .tagSelection:
                return 1
            case .addFromText:
                return 2
            case .addFromTap:
                return 3
            case .addFromTapMeanings:
                return 4
            case .tapResult:
                return 5
        }
    }
}

struct AddWordsView: View {
    @State private var uiImages: [UIImage] = []
    @State private var uiImage_camera: UIImage?
    @State private var path = [Path]()
    @State var showPicker: Bool = false
    @State var showSinglePicker: Bool = false
    @State private var showCamera: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedSingleItem: PhotosPickerItem?
    @State var isAlbumOCRSelectionSheetPresented: Bool = false
    @State var isCameraSheetPresented: Bool = false
    @State var popoverVisible = false
    @ObservedObject var ocrSelectionSheetViewModel: AddWordsViewModel = AddWordsViewModel()
    
    var body: some View {
        NavigationStack (path: $path){
            //3つのボタンを縦に並べて表示
            ScrollView{
                RandomWordView(path: $path)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.all)
                HStack{
                    Button {
                        isCameraSheetPresented = true
                    } label: {
                        VStack{
                            Image(systemName: "camera")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                            Text("カメラから追加")
                        }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .sheet(isPresented: $isCameraSheetPresented) {
                        OCRProcessSelectionSheet(isPresented: $isCameraSheetPresented, ocrSelectionSheetViewModel: ocrSelectionSheetViewModel)
                            .presentationDragIndicator(.visible)
                            .presentationDetents([.medium])
                            .onDisappear(){
                                print(ocrSelectionSheetViewModel.ocrProcessSelection)
                                if(ocrSelectionSheetViewModel.ocrProcessSelection != .dismiss){
                                    showCamera = true
                                }
                                
                            }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.all)
                    .frame(maxWidth: .infinity)

                    Button {
                        isAlbumOCRSelectionSheetPresented = true
                    } label: {
                            VStack{
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                Text("アルバムから追加")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .sheet(isPresented: $isAlbumOCRSelectionSheetPresented) {
                        OCRProcessSelectionSheet(isPresented: $isAlbumOCRSelectionSheetPresented, ocrSelectionSheetViewModel: ocrSelectionSheetViewModel)
                            .presentationDragIndicator(.visible)
                            .presentationDetents([.medium])
                            .onDisappear(){
                                print(ocrSelectionSheetViewModel.ocrProcessSelection)
                                if(ocrSelectionSheetViewModel.ocrProcessSelection != .dismiss){
                                    showPicker = true
                                }
                            }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.all)
                    .frame(maxWidth: .infinity)

                }
                
                Button {
                    showSinglePicker = true
                } label: {
                    Label("単語をタップして追加", systemImage: "photo")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical)

                Button{
                    //ページの遷移は行わずにポップアップでブラウザから追加する方法を表示
                    popoverVisible = true
                }
                label:{
                    Label("ブラウザから追加", systemImage: "safari")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical)
                .popover(isPresented: $popoverVisible, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                    PopoverContainer {
                        Text("Safariなどのブラウザで辞書サイトを開き、共有ボタンからWordbookを選択してください。英単語と意味に当たる部分を自動的に抜き出して単語帳に追加されます。また、テキストを選択してから共有ボタンを押すと、そのテキストを意味とみなして追加されます。")
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                    }
                    .presentationCompactAdaptation(.none)
                }
                    

                Button{
                    path.append(.addFromText)
                }
                label:{
                    Label("入力して追加", systemImage: "keyboard")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical)
            }
            .photosPicker(isPresented: $showPicker, selection: $selectedItems, matching: .images)
            .onChange(of: selectedItems) {
                Task {
                    uiImages = await convertToUIImage(selectedItems: selectedItems)
                    selectedItems.removeAll()
                    if uiImages.count > 0 {
                        path.append(Path.textRecognitionResult(uiImages, ocrSelectionSheetViewModel))
                    }
                }
            }
            .photosPicker(isPresented: $showSinglePicker, selection: $selectedSingleItem, matching: .images)
            .onChange(of: selectedSingleItem) {
                Task {
                    uiImages.removeAll()
                    if let selectedSingleItem = selectedSingleItem {
                        if let data = try? await selectedSingleItem.loadTransferable(type: Data.self) {
                            self.selectedSingleItem = nil
                            if let uiImage = UIImage(data: data){
                                path.append(Path.addFromTap([uiImage]))
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $uiImage_camera).ignoresSafeArea()
            }
            .onChange(of: uiImage_camera) {
                Task {
                    uiImages.removeAll()
                    if uiImage_camera != nil {
                        uiImages.append(uiImage_camera!)
                        path.append(Path.textRecognitionResult(uiImages, ocrSelectionSheetViewModel))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.listBackground))
            .navigationTitle("単語の追加")
            .navigationDestination(for: Path.self) {
                switch $0 {
                    case .textRecognitionResult(let uiImage_, let ocrSelectionSheetViewModel_):
                        // 遷移先にpath配列の参照や必要な情報を渡す
                        TextRecognitionResultView(path: $path, uiImages: uiImage_, ocrSelectionSheetViewModel: ocrSelectionSheetViewModel_)
                    case .addFromText:
                        AddWordsFromTextView(path: $path)
                    case .tagSelection(let tag_):
                        CommonTagSelectionView(selectedTag: tag_)
                    case .addFromTap(let uiImage_):
                        AddWordsFromTapView(path: $path, uiImage: uiImage_)
                    case .addFromTapMeanings(let tapItem_, let uiImage_):
                        AddMeaningsFromTapView(path: $path, tapItem: tapItem_, uiImage: uiImage_)
                    case .tapResult(let tapItem_):
                        TextTapResultView(path: $path, tapItem: tapItem_)
                }
            }
        }
    }
    
    private func convertToUIImage(selectedItems: [PhotosPickerItem]) async -> [UIImage] {
        var uiImages: [UIImage] = []
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data){
                    uiImages.append(uiImage)
                }
            }
        }
        return uiImages
    }
}
