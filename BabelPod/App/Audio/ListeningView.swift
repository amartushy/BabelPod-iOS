//
//  ListeningView.swift
//  AssistAid
//
//  Created by Adrian Martushev on 6/14/24.
//

import SwiftUI
import AVFoundation
import Speech



struct ListeningView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var openAIVM : OpenAIViewModel
    @EnvironmentObject var appManager : AppManager
    @EnvironmentObject var translationVM : TranslationViewModel
    
    @State private var audioEngine = AVAudioEngine()
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State var isRecording = false
    
    @State private var isAnimating = false
    
    @GestureState private var isDetectingLongPress = false
    @State private var completedLongPress = false

    
    func checkPermissionsAndStartRecording() {
        generateHapticFeedback()
        isRecording = true
        requestAuthorizationAndStartRecording()
        print("Recording started")
    }
    
    var showBackButton = false
    
    var body: some View {
        ZStack {
            
            VStack {
                if showBackButton {
                    HStack {
                        Button {
                            dismiss()
                        } label : {
                            CircularIcon(icon: "arrow.left")
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                
                Spacer()
                    .toolbar(.hidden)
                
                if openAIVM.presetInstructionsAvailable {
                    if openAIVM.isResponding {
                        CirclePatternView(width: 30, height: 50)
                    }
                } else {
                    if openAIVM.isResponding {
                        CirclePatternView(width : 50, height: 100)
                        
                    } else if openAIVM.responsePending {
                        AnimatedCircleView()
                        
                        Text("One moment..")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight : .semibold))
                            .padding(.top, 30)
                        
                    } else {
                        Circle()
                            .fill(.white)
                            .scaleEffect(self.isDetectingLongPress ? 1.1 : (isAnimating ? 1.1 : 1.0))
                            .frame(width: 250, height: 250)
                            .onAppear() {
                                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                    isAnimating = true
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.3){
                                checkPermissionsAndStartRecording()
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded{ _ in
                                        if isRecording {
                                            generateHapticFeedback()
                                            endRecording(isFinal: true)
                                            isRecording = false
                                            print("Recording stopped")
                                        }
                                    }
                                )
                                        
                        Text(isRecording ? "Listening" : "Tap to hold to record")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight : .semibold))
                            .padding(.top, 30)
                    }
                }
            
                
                Spacer()
                
                ZStack {
                    
                    if isRecording {
                        HStack {
                            Image(systemName: "mic.fill")
                            CirclePatternView(width : 10, height: 10)
                        }
                    }
                    
                    
                    HStack {
                        
                        if openAIVM.isResponding {
                            Button(action: {
                                openAIVM.stopAudio()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.1))
                                        .frame(width : 60, height : 60)
                                    
                                    Image(systemName: "stop.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 28))
                                }
                            }
                            
                        } else if isRecording {
                            Button(action: {
                                endRecording(isFinal: true)
                                isRecording = false
                                print("Recording stopped")
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.1))
                                        .frame(width : 60, height : 60)
                                    
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 28))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Spacer()
                        
                        Button(action: {
                            openAIVM.updateInputPreference(.text)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.red)
                                    .frame(width : 60, height : 60)
                                
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 28))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.background)

        }
    }
}


struct AnimatedCircleView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.clear)
            .frame(width: 250, height: 250)
            .overlay(
                Circle()
                    .trim(from: 0, to: 0.2)
                    .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .foregroundColor(.white)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear() {
                self.isAnimating = true
            }
    }
}


extension ListeningView {
    func requestAuthorizationAndStartRecording() {
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    // Request microphone access authorization
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                // Both permissions are granted, start recording
                                try? self.startRecording()
                                print("Microphone granted.")

                            } else {
                                // Handle the microphone access denied case
                                print("Microphone access was not granted.")
                            }
                        }
                    }
                default:
                    // Handle the speech recognition access denied case
                    print("Speech recognition authorization was not granted.")
                }
            }
        }
    }
    
    func startRecording() throws {
        let selectedLocale = Locale(identifier: translationVM.sourceLanguage.locale)
        speechRecognizer = SFSpeechRecognizer(locale: selectedLocale)

        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil

        // Configure audio session for the recording.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create a new recognition request.
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        recognitionRequest.shouldReportPartialResults = true

        // Setup a recognition task for the speech recognizer.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [self] result, error in
            if let result = result, !result.bestTranscription.formattedString.isEmpty {
                // Only update if there's a non-empty transcription
                openAIVM.query = result.bestTranscription.formattedString
                print(openAIVM.query)
                
                if error != nil || result.isFinal  {
                    self.endRecording(isFinal: result.isFinal )
                }
            }

        }

        // Configure the microphone input.
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }

        // Start the audio engine.
        audioEngine.prepare()
        try audioEngine.start()
    }

    func endRecording(isFinal: Bool) {
        isRecording = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        if isFinal {
            Task {
                await openAIVM.sendQuery(playAudio: true, appManager : appManager)
                
            }
        }
    }
}



struct CirclePatternView: View {
    var width: CGFloat
    var height: CGFloat


    @State private var animateFirstBar = false
    @State private var animateSecondBar = false
    @State private var animateThirdBar = false
    @State private var animateFourthBar = false

    var body: some View {
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: width / 2)
                .fill(Color.white)
                .frame(width: width, height: height * (animateFirstBar ? 1.5 : 1.0))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        animateFirstBar.toggle()
                    }
                }
            
            RoundedRectangle(cornerRadius: width / 2)
                .fill(Color.white)
                .frame(width: width, height: height * (animateSecondBar ? 1.2 : 0.8))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        animateSecondBar.toggle()
                    }
                }
            
            RoundedRectangle(cornerRadius: width / 2)
                .fill(Color.white)
                .frame(width: width, height: height * (animateThirdBar ? 1.8 : 1.3))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        animateThirdBar.toggle()
                    }
                }
            
            RoundedRectangle(cornerRadius: width / 2)
                .fill(Color.white)
                .frame(width: width, height: height * (animateFourthBar ? 1.1 : 0.9))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        animateFourthBar.toggle()
                    }
                }
        }
        .frame(height : height * 1.8)
    }
}


#Preview {
    ListeningView()
        .environmentObject(OpenAIViewModel())
        .environmentObject(AppManager())
        .environmentObject(TranslationViewModel())
}
