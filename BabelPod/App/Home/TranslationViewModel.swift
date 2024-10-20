//
//  TranscriptionViewModel.swift
//  BabelPod
//
//  Created by Adrian Martushev on 10/19/24.
//
import SwiftUI
import Speech
import AVFoundation
import OpenAI


struct ChatMessage: Identifiable {
    var id: UUID = UUID()
    var role: Role
    var content: String
    
    enum Role: String {
        case user = "user"
        case assistant = "assistant"
    }
}

enum Voice: String, CaseIterable, Identifiable {
    case alloy = "alloy"
    case echo = "echo"
    case fable = "fable"
    case onyx = "onyx"
    case nova = "nova"
    case shimmer = "shimmer"

    var id: String { self.rawValue }

    // Convert to API's voice type
    func toAPIVoice() -> AudioSpeechQuery.AudioSpeechVoice {
        return AudioSpeechQuery.AudioSpeechVoice(rawValue: self.rawValue) ?? .alloy
    }
}

struct VoiceOption: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
}

extension UserDefaults {
    static let selectedVoiceKey = "selectedVoice"
}

class TranslationViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    let openAI = OpenAI(apiToken: "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")
    @Published var transcription : String = ""
    @Published var translatedTranscription : String = ""
    @Published var sourceLanguage: LanguageOption = spanishOption
    @Published var targetLanguage: LanguageOption = englishOption
    @Published var voices = Voice.allCases
    
    @Published var selectedVoice: Voice {
        didSet {
            saveVoiceSelection()
        }
    }
    
    private var audioQueue: [String] = []
    var audioPlayer: AVAudioPlayer?
    @Published var isAudioPlaying: Bool = false
    @Published var isResponding = false
    @Published var responsePending = false
    
    
    // MARK: - Synthesize and Queue Audio for Playback
    func queueTranslationForSynthesis(_ text: String) {
        audioQueue.append(text)
        
        if !isAudioPlaying {
            processNextInQueue()
        }
    }

    // MARK: - Process the Next Translation in the Queue
    func processNextInQueue() {
        guard !audioQueue.isEmpty else {
            return
        }
        
        let nextTranslation = audioQueue.removeFirst()
        
        Task {
            await synthesizeResponse(from: nextTranslation)
        }
    }
    
    
    override init() {
        selectedVoice = UserDefaults.standard.string(forKey: UserDefaults.selectedVoiceKey)
            .flatMap { Voice(rawValue: $0) } ?? .alloy
                
        super.init()
    }
    

    private func saveVoiceSelection() {
        UserDefaults.standard.set(selectedVoice.rawValue, forKey: UserDefaults.selectedVoiceKey)
    }
    
    
    func translateTranscription() async {
        // Prepare the request
        guard let url = URL(string: "https://babelpod-e350d49a7a4c.herokuapp.com/translate") else {
            print("Invalid URL")
            return
        }
        
        // Create the request body
        let requestBody: [String: Any] = [
            "text": transcription,
            "source_lang": sourceLanguage.locale,
            "target_lang": targetLanguage.locale
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Failed to serialize request body")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let translatedText = jsonResponse["result"] as? String {
                    
                    print(translatedText)
                    DispatchQueue.main.async {
                        self.translatedTranscription = translatedText
                    }
                    
                } else {
                    print("Failed to parse translation response")
                }
                
            } else {
                print("Failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            }
        } catch {
            print("Failed to send translation request: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Synthesize the Response from the Text
    func synthesizeResponse(from text: String) async {
        let speechQuery = AudioSpeechQuery(
            model: .tts_1,
            input: text,
            voice: selectedVoice.toAPIVoice(),
            responseFormat: .mp3,
            speed: 1.0
        )
        
        do {
            let speechResult = try await openAI.audioCreateSpeech(query: speechQuery)
            DispatchQueue.main.async {
                self.playAudio(from: speechResult.audio)
            }
        } catch {
            DispatchQueue.main.async {
                print("Error synthesizing speech: \(error)")
                self.processNextInQueue()
            }
        }
    }
    
    // MARK: - Play Audio from Data
    func playAudio(from data: Data) {
        setupAudioSession()
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            // Update state
            DispatchQueue.main.async {
                self.isAudioPlaying = true
                self.isResponding = true
                self.responsePending = false
            }
        } catch {
            print("Failed to play audio: \(error)")
            DispatchQueue.main.async {
                self.isAudioPlaying = false
                self.isResponding = false
            }
            
            processNextInQueue()
        }
    }
    
    // MARK: - Audio Session Setup
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - AVAudioPlayerDelegate Method
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isAudioPlaying = false
            self.isResponding = false
            
            // After audio finishes, process the next item in the queue
            self.processNextInQueue()
        }
    }
    
    // MARK: - Stop Audio Playback
    func stopAudio() {
        if audioPlayer?.isPlaying ?? false {
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            self.isResponding = false
        }
    }
}

