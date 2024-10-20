//
//  CachedAsyncImageView.swift
//  Diddly
//
//  Created by Adrian Martushev on 6/24/24.
//

import Foundation
import UIKit
import SwiftUI
import Combine

class ImageCache {
    static let shared = NSCache<NSString, UIImage>()

    static func getImage(forKey key: String) -> UIImage? {
        return shared.object(forKey: key as NSString)
    }

    static func setImage(_ image: UIImage, forKey key: String) {
        shared.setObject(image, forKey: key as NSString)
    }
}

class CachedImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var urlString: String
    private var cancellable: AnyCancellable?

    init(urlString: String) {
        self.urlString = urlString
    }

    func load() {
        if let cachedImage = ImageCache.getImage(forKey: urlString) {
            image = cachedImage
            return
        }

        guard let url = URL(string: urlString) else {
            return
        }

        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if let image = $0 {
                    ImageCache.setImage(image, forKey: self?.urlString ?? "")
                    self?.image = image
                }
            }
    }

    func cancel() {
        cancellable?.cancel()
    }
}

struct CachedAsyncImageView: View {
    @StateObject private var loader: CachedImageLoader
    init(urlString: String) {
        _loader = StateObject(wrappedValue: CachedImageLoader(urlString: urlString))
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: loader.load)
        .onDisappear(perform: loader.cancel)
    }
}



struct ProfilePhotoOrInitials : View {
    
    let profileImage : String
    let fullName : String
    let radius : CGFloat
    let fontSize : CGFloat
    
    var body: some View {
        

        if ( profileImage.isEmpty ) {
            
            if fullName != "" && fullName != " " {
                Text(getInitials(fullName: fullName))
                    .font(.system(size: fontSize))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(hex : "#16171D"))
                    .frame(width: radius, height: radius)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(100)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
                
            } else {
                Image("default_profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: radius, height: radius)
                    .cornerRadius(100)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
            }
            
        } else {
            CachedAsyncImageView(urlString: profileImage)
                .scaledToFill()
                .frame(width: radius, height: radius)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }

        }
    }
}

func getInitials(fullName : String) -> String {
    let names = fullName.split(separator: " ")

    switch names.count {
    case 0:
        return ""
    case 1:
        // Only one name provided
        return String(names.first!.prefix(1))
    default:
        // Two or more names provided, get the first and last name initials
        let firstInitial = names.first!.prefix(1)
        let lastInitial = names.last!.prefix(1)
        return "\(firstInitial)\(lastInitial)"
    }
}
