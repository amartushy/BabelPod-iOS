//
//  Functions.swift
//  Diddly
//
//  Created by Adrian Martushev on 6/20/24.
//

import Foundation
import UIKit
import MapKit

func generateHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare()
    generator.impactOccurred()
    
}

// Function to generate a random 8-character alphanumeric ID
func generateRandomID(length: Int = 8) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).compactMap{ _ in letters.randomElement() })
}


extension Int {
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}

func formatDate(_ date: Date) -> String {
    let calendar = Calendar.current
    
    // Get the day of the month and make it ordinal
    let day = calendar.component(.day, from: date)
    let formatter = NumberFormatter()
    formatter.numberStyle = .ordinal
    let dayOrdinal = formatter.string(from: NSNumber(value: day)) ?? "\(day)"
    
    // Date formatter for the full date except the day part
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE, MMMM"
    let fullDate = dateFormatter.string(from: date)
    
    // Date formatter for the time part
    dateFormatter.dateFormat = "h:mma"
    dateFormatter.amSymbol = "am"
    dateFormatter.pmSymbol = "pm"
    let time = dateFormatter.string(from: date)
    
    return "\(fullDate) \(dayOrdinal) \(time)"
}

func formatTravelDates(start: Date, end: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM d"
    
    let startString = dateFormatter.string(from: start)
    let endString: String
    
    // Check if the start and end dates are in the same month
    if Calendar.current.isDate(start, equalTo: end, toGranularity: .month) {
        dateFormatter.dateFormat = "d"
        endString = dateFormatter.string(from: end)
    } else {
        endString = dateFormatter.string(from: end)
    }
    
    dateFormatter.dateFormat = "yyyy"
    let yearString = dateFormatter.string(from: end)
    
    return "\(ordinalSuffix(for: startString))-\(ordinalSuffix(for: endString)), \(yearString)"
}

private func ordinalSuffix(for dayString: String) -> String {
    guard let dayInt = Int(dayString) else { return dayString }
    
    let suffixes = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"]
    let index = dayInt % 10
    let century = dayInt % 100
    if century >= 11 && century <= 13 {
        return "\(dayInt)th"
    }
    
    return "\(dayInt)\(suffixes[index])"
}

func formattedDate(from date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM d"
    
    let calendar = Calendar.current
    let day = calendar.component(.day, from: date)
    
    let daySuffix: String
    switch day {
    case 1, 21, 31: daySuffix = "st"
    case 2, 22: daySuffix = "nd"
    case 3, 23: daySuffix = "rd"
    default: daySuffix = "th"
    }
    
    dateFormatter.dateFormat = "MMMM d'\(daySuffix)', yyyy"
    return dateFormatter.string(from: date)
}



func generateRandomString(length: Int) -> String {
    let lettersAndDigits = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).compactMap{ _ in lettersAndDigits.randomElement() })
}

let loremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
