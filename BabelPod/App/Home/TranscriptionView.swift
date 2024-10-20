//
//  TranscriptionView.swift
//  BabelPod
//
//  Created by Adrian Martushev on 10/19/24.
//

import SwiftUI
import AVFoundation
import Speech
import Lottie

struct TranscriptionView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var translationVM : TranslationViewModel
    
    @State private var audioEngine = AVAudioEngine()
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State var isRecording = false
    
    @State private var debounceTimer: Timer?
    
    func checkPermissionsAndStartRecording() {
        if isRecording {
            endRecording(isFinal: true)
        } else {
            generateHapticFeedback()
            isRecording = true
            requestAuthorizationAndStartRecording()
        }
    }
    
    @State var showLanguageSheet : Bool = false
        
    var body: some View {
        VStack(alignment : .leading) {
            HStack {
                Button {
                    generateHapticFeedback()
                    dismiss()
                } label: {
                    CircularIcon(icon: "arrow.left")
                }

                Spacer()
            }
            .toolbar(.hidden)
            
            Spacer()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment : .leading) {
                        Spacer()
                        Text(translationVM.transcription)
                            .font(.custom("Raleway-SemiBold", size: 32))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(10)
                            .padding(.horizontal, 40)
                            .id("Bottom")
                    }
                }
                .onAppear {
                     withAnimation {
                         proxy.scrollTo("Bottom", anchor: .bottom)
                     }
                 }
                 .onChange(of: translationVM.transcription) { _, _ in
                     withAnimation {
                         proxy.scrollTo("Bottom", anchor: .bottom)
                     }
                 }
            }
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment : .leading) {
                        Spacer()
                        Text(translationVM.translatedTranscription)
                            .font(.custom("Raleway-SemiBold", size: 32))
                            .foregroundColor(.indigo)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(10)
                            .padding(.horizontal, 40)
                            .id("Bottom")
                    }
                }
                .onAppear {
                     withAnimation {
                         proxy.scrollTo("Bottom", anchor: .bottom)
                     }
                 }
                 .onChange(of: translationVM.translatedTranscription) { _, _ in
                     withAnimation {
                         proxy.scrollTo("Bottom", anchor: .bottom)
                     }
                 }
            }
                        
            HStack {
                Button {
                    generateHapticFeedback()
                    showLanguageSheet = true
                } label: {
                    CircularIcon(icon: "translate", background : .onyx, diameter: 60)
                }
                .sheet(isPresented: $showLanguageSheet) {
                    LanguageSelectionSheet()
                }

                Spacer()
                Button {
                    checkPermissionsAndStartRecording()
                } label: {
                    if isRecording {
                        ZStack {
                            LottieView(animation: .named("recording"))
                              .playing()
                              .looping()
                              .resizable()
                              .scaledToFit()
                              .frame(width : 30, height : 20)
                        }
                        .foregroundStyle(.white)
                        .frame(width : 80, height : 80)
                        .background(.onyx.opacity(0.5))
                        .cornerRadius(100)
                        .shadow(radius: 10)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        }
                        
                    } else {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.white)
                            .frame(width : 80, height : 80)
                            .background(.onyx.opacity(0.5))
                            .cornerRadius(100)
                            .shadow(radius: 10)
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            }
                    }
                }
                
                Spacer()
                
                Button {
                    generateHapticFeedback()
                    endRecording(isFinal: true)
                } label: {
                    CircularIcon(icon: "xmark", background : .onyx, diameter: 60)
                }
            }
        }
        .padding()
        .background(Color.background)
    }
}


extension TranscriptionView {
    func requestAuthorizationAndStartRecording() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                try? self.startRecording()
                            } else {
                                print("Microphone access was not granted.")
                            }
                        }
                    }
                default:
                    print("Speech recognition authorization was not granted.")
                }
            }
        }
    }
    
    func startRecording() throws {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "\(translationVM.sourceLanguage.locale)"))

        recognitionTask?.cancel()
        self.recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        recognitionRequest.shouldReportPartialResults = true

        // Setup a recognition task for the speech recognizer.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [self] result, error in
            if let result = result, !result.bestTranscription.formattedString.isEmpty {
                let currentTranscription = result.bestTranscription.formattedString

                if result.isFinal || isSufficientlyDifferent(currentTranscription, comparedTo: translationVM.transcription) {
                    translationVM.transcription = currentTranscription
                    
                    debounceTranslation()
                }
            }
        }

        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }

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

    }
    
    func isSufficientlyDifferent(_ current: String, comparedTo previous: String) -> Bool {
        let currentLength = current.count
        let previousLength = previous.count
        
        let lengthDifference = abs(currentLength - previousLength)

        return lengthDifference >= 3 || current != previous
    }
    
    func debounceTranslation() {
        debounceTimer?.invalidate()

        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            Task {
                await translationVM.translateTranscription()
            }
        }
    }
}


#Preview {
    TranscriptionView()
        .environmentObject(TranslationViewModel())
}
