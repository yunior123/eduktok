//
//  ForeView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 30/12/24.
//


struct ForeView: View {
    let models: [ListeningModel]
    @ObservedObject var viewModel: GListeningViewModel
    let userModel: UserModel
    let unitNumber: Int
    let lessonId: String

    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedModelId: String?

    var body: some View {
        ScrollView {
            LazyHStack {
                ForEach(models) { model in
                    ZStack(alignment: .topTrailing) {
                        ForeCardView(model: model, viewModel: viewModel)
                            .frame(width: 200, height: 200)
                            .onTapGesture {
                                viewModel.checkMatch(selectedModel: model)
                            }

                        if userModel.role == "admin" {
                            Button(action: {
                                selectedModelId = model.id
                                showImagePicker = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.blue)
                                    .padding(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage,
               let modelId = selectedModelId {
                Task {
                    await handleImageSelection(image: image, modelId: modelId, lessonId: lessonId)
                }
            }
        }
    }