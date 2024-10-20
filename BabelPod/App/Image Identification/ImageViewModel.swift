//
//  ImageViewModel.swift
//  BabelPod
//
//  Created by Adrian Martushev on 10/19/24.
//

import SwiftUI
import OpenAI
import FirebaseStorage


struct MenuModel : Identifiable {
    var id : String
    var sourceURL : String
    var menuItems : [MenuItem]
}

struct MenuItem : Hashable {
    var itemName: String
    var price: String
    var translatedItemName: String
    var type: String
}

class ImageViewModel : ObservableObject {
    
    @Published var showErrorMessage : Bool = false
    @Published var errorMessage : String = ""
    @Published var isAnalyzingImage = false
    @Published var selectedImage: Image?
    @Published var sourceURL : String?
    @Published var menuItems : [MenuItem] = []
    
    
    let openAI = OpenAI(apiToken: "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")
        
    
    // MARK: Landmark Identification
    func uploadImageToFirebaseStorage(image : UIImage, completion: @escaping (String?) -> Void) {

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            displayError("Failed to encode image.")
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("menu_images/\(UUID().uuidString).jpg")

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.displayError("Failed to upload image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    self.displayError("Failed to get download URL: \(error.localizedDescription)")
                    completion(nil)
                } else if let downloadURL = url {
                    self.sourceURL = downloadURL.absoluteString
                    completion(downloadURL.absoluteString)
                }
            }
        }
    }
    
    func captureImageAndTranslateMenu(image: UIImage, targetLocale : String) {
        isAnalyzingImage = true
        
        uploadImageToFirebaseStorage(image: image) { downloadURL in
            guard let downloadURL = downloadURL else {
                self.displayError("Failed to upload image.")
                return
            }

            guard let url = URL(string: "https://babelpod-e350d49a7a4c.herokuapp.com/analyze_menu_url") else {
                self.displayError("Invalid server URL.")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let requestBody: [String: String] = ["image_url": downloadURL, "target_lang" : targetLocale]
            print("Request body: \(requestBody)")
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                request.httpBody = jsonData
            } catch {
                self.displayError("Failed to create JSON body: \(error.localizedDescription)")
                return
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.displayError("Failed to send request: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    self.displayError("No data received from server.")
                    return
                }
                
                do {
                    // Print the raw data for debugging
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("Raw response from server: \(dataString)")
                    }

                    // Attempt to parse the JSON
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let menuItemsWrapper = json["menuItems"] as? [String: Any],
                       let menuItemsArray = menuItemsWrapper["items"] as? [[String: Any]] { // Access the nested 'items' array
                        print(menuItemsArray) // Print the menu items array for debugging
                        DispatchQueue.main.async {
                            print("Response contains menu items, count : \(menuItemsArray.count)")
                            self.menuItems = self.parseMenuItems(response: menuItemsArray)
                            self.isAnalyzingImage = false
                        }
                    } else {
                        self.displayError("Failed to find menuItems in response.")
                    }
                } catch {
                    self.displayError("Failed to parse response: \(error.localizedDescription)")
                }

                
            }.resume()
        }
    }
    
    func fetchLandmarkDetails(landmark : String, location : String) {
        self.isAnalyzingImage = false

    }
        
    // Helper function to display errors
    private func displayError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showErrorMessage = true
            self.isAnalyzingImage = false
        }
    }
    
    func parseMenuItems(response: [[String: Any]]) -> [MenuItem] {
        var menuItems = [MenuItem]()

        for item in response {
            let itemName = item["itemName"] as? String ?? "Unknown Item"
            let price = item["price"] as? String ?? "N/A"
            let translatedItemName = item["translatedItemName"] as? String ?? "No Translation"
            let type = item["type"] as? String ?? "Unknown Type"

            let menuItem = MenuItem(itemName: itemName, price: price, translatedItemName: translatedItemName, type: type)
            menuItems.append(menuItem)
        }

        print(menuItems)
        return menuItems
    }
}
