//
//  HomeView.swift
//  BabelPod
//
//  Created by Adrian Martushev on 10/19/24.
//

import SwiftUI
import AVKit


struct HomeView: View {
    @EnvironmentObject var imageVM: ImageViewModel
    @EnvironmentObject var translationVM: TranslationViewModel

    var screenWidth = UIScreen.main.bounds.width
    
    @State var showCameraPicker : Bool = false
    @State var selectedImage : UIImage?
    @State var navigate = false
    
    var body: some View {
        VStack(alignment : .leading) {
            HStack {
                CircularIcon(icon: "line.3.horizontal")
                
                Spacer()
                
                Button {
                    
                } label: {
                    CircularIcon(icon: "gear")
                }
            }
            
            VStack (alignment: .leading) {
                Text("Hi Adrian,")
                    .foregroundStyle(.white.opacity(0.8))
                
                Text("Let's get started")
                    .font(.custom("Raleway-Bold", size: 24))
            }
            .font(.custom("Raleway-SemiBold", size: 16))
            .foregroundStyle(.white)
            .padding(.top, 60)
            .padding(.bottom, 30)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Translator")
                        .font(.custom("Raleway-SemiBold", size: 14))
                        .foregroundStyle(.white.opacity(0.8))

                    CircularIcon(icon: "microphone", background : .white.opacity(0.4))
                    Spacer()
                    
                    Text("Start a new translation session")
                        .font(.custom("Raleway-SemiBold", size: 24))

                    Spacer()
                    
                    NavigationLink {
                        TranscriptionView()
                    } label: {
                        Text("Start Recording")
                            .font(.custom("Raleway-SemiBold", size: 14))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(.white)
                            .cornerRadius(100)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
                .frame(maxWidth : .infinity)
                .background(.indigo)
                .cornerRadius(10)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
                
                VStack {
                    NavigationLink {
                        ListeningView(showBackButton : true)
                    } label: {
                        VStack (alignment : .leading) {
                            CircularIcon(icon: "message")
                            Spacer()
                            HStack {
                                Text("Start New Chat")
                                    .font(.custom("Raleway-SemiBold", size: 14))

                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(.jetBlack)
                        .cornerRadius(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }
                    }
                    
                    Button {
                        showCameraPicker = true
                    } label: {
                        VStack (alignment : .leading) {
                            CircularIcon(icon: "photo")
                            Spacer()
                            HStack {
                                Text("Translate Menu")
                                    .font(.custom("Raleway-SemiBold", size: 14))
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(.jetBlack)
                        .cornerRadius(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }
                    }
                    .sheet(isPresented: $showCameraPicker) {
                        CameraPicker(image : $selectedImage)
                    }
                    .onChange(of: selectedImage) { _, newImage in
                        if let image = newImage {
                            imageVM.captureImageAndTranslateMenu(image: image, targetLocale : translationVM.targetLanguage.locale)
                        }
                    }
                }
                .frame(width : screenWidth * 0.4)
            }
            .frame(height : 280)
            
            Spacer()
        }
        .padding()
        .background(Color.background)
        .overlay {
            AnalyzingLoadingStateView()
        }
        .navigationDestination(isPresented: $navigate) {
            TranslatedMenuView()
        }
        .onChange(of: imageVM.menuItems) { _, _ in
            if !imageVM.menuItems.isEmpty {
                navigate = true
            }
        }
        .alert(isPresented: $imageVM.showErrorMessage) {
            Alert(
                title: Text("Error"),
                message: Text(imageVM.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct AnalyzingLoadingStateView : View {
    @EnvironmentObject var imageVM : ImageViewModel
    
    var body: some View {
        ZStack {
            if imageVM.isAnalyzingImage {
                Color(.black.opacity(0.7))
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ProgressView()
                    Text("Analyzing menu..")
                        .foregroundStyle(.white)
                        .font(.custom("Raleway", size: 18))
                }
            }
        }
    }
}


struct CircularIcon : View {
    var icon : String
    var background : Color = Color.onyx
    var diameter : CGFloat = 40

    var body: some View {
        Image(systemName: icon)
            .foregroundStyle(.white)
            .frame(width : diameter, height : diameter)
            .background(background)
            .cornerRadius(100)
    }
}


struct PlayerView: UIViewRepresentable {
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
    }

    func makeUIView(context: Context) -> UIView {
        return LoopingPlayerUIView(frame: .zero)
    }
}

class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        let fileUrl = Bundle.main.url(forResource: "Waveform", withExtension: "mov")!
        let asset = AVAsset(url: fileUrl)
        let item = AVPlayerItem(asset: asset)

        let player = AVQueuePlayer()
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        playerLooper = AVPlayerLooper(player: player, templateItem: item)

        player.play()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}


#Preview {
    HomeView()
}
