//
//  OpenAIViewModel.swift
//  AssistAid
//
//  Created by Adrian Martushev on 6/14/24.
//

import SwiftUI
import Speech
import AVFoundation
import OpenAI



enum InputSelectionType {
    case voice, text, none
}


class OpenAIViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var inputPreference: InputSelectionType = .none
    
    let openAI = OpenAI(apiToken: "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")
    @Published var query = ""
    @Published var messages: [ChatMessage] = []
    @Published var voices = Voice.allCases
    
    @Published var selectedVoice: Voice {
        didSet {
            saveVoiceSelection()
        }
    }
    
    
    var audioPlayer: AVAudioPlayer?
    @Published var isAudioPlaying: Bool = false
    @Published var isResponding = false
    @Published var responsePending = false
    @Published var presetInstructionsAvailable = false

    override init() {
        selectedVoice = UserDefaults.standard.string(forKey: UserDefaults.selectedVoiceKey)
            .flatMap { Voice(rawValue: $0) } ?? .alloy
                
        super.init()
        
        loadInputPreference()
    }
    
    func updateInputPreference(_ input : InputSelectionType) {
        UserDefaults.standard.set(input == .voice ? "voice" : "text", forKey: "inputPreference")
        loadInputPreference()
    }
    
    private func loadInputPreference() {
        let preference = UserDefaults.standard.string(forKey: "inputPreference") ?? "voice"
        inputPreference = (preference == "voice") ? .voice : .text
        print("New input preference is: \(inputPreference)")
    }
    

    private func saveVoiceSelection() {
        UserDefaults.standard.set(selectedVoice.rawValue, forKey: UserDefaults.selectedVoiceKey)
    }
    
    
    func sendQuery(playAudio : Bool, appManager : AppManager) async {
        print("Sending query : \(query)")
        DispatchQueue.main.async {
            self.responsePending = true
        }
        let userMessage = ChatMessage(role: .user, content: query)
        
        DispatchQueue.main.async {
            self.messages.append(userMessage)
        }
        
        var systemMessage : ChatQuery.ChatCompletionMessageParam = .init(role: .assistant, content: "You are a translation assistant. Please respond with helpful and accurate translations")!

        let chatQuery = ChatQuery(
            messages: [systemMessage, .init(role: .user, content: query)!],
            model: .gpt3_5Turbo
        )
        
        DispatchQueue.main.async {
            self.query = ""
        }
        
        do {
            // Execute the query
            let result = try await openAI.chats(query: chatQuery)
            DispatchQueue.main.async { // Ensure UI updates are on the main thread
                if let firstChoice = result.choices.first,
                   case let .string(responseContent) = firstChoice.message.content {
                    let assistantMessage = ChatMessage(role: .assistant, content: responseContent)
                    self.messages.append(assistantMessage)
                    if playAudio {
                        Task {
                            await self.synthesizeResponse(from: responseContent)
                        
                        }
                    } else {
                        self.responsePending = false
                    }
                    
                    
                    self.query = ""

                } else {
                    print("Received content is not a string or is empty")
                }
            }
        } catch {
            print("Failed to get response from OpenAI: \(error.localizedDescription)")
            self.responsePending = false

        }
    }

    
    
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
            }
        }
    }
    
    /// Prepares and manages the audio session for playback
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    /// Plays audio from given data.
    func playAudio(from data: Data) {
        setupAudioSession()
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self // Set delegate to self to detect when audio finishes playing
            audioPlayer?.play()
            DispatchQueue.main.async {
                self.responsePending = false
                self.isResponding = true
                self.isAudioPlaying = true
            }
        } catch {
            print("Failed to play audio: \(error)")
            DispatchQueue.main.async {
                self.isResponding = false
                self.isAudioPlaying = false
            }
        }
    }

    /// Called when audio playback finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isResponding = false
            self.isAudioPlaying = false

        }
    }
    
    func stopAudio() {
        if audioPlayer?.isPlaying ?? false {
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            self.isResponding = false
        }
    }
}
