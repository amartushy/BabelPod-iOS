//
//  Extensions.swift
//  Diddly
//
//  Created by Adrian Martushev on 6/20/24.
//


import Foundation
import SwiftUI
import UIKit



extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}




extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}


extension View {
    func outerShadow(applyShadow: Bool = true) -> some View {
        Group {
            if applyShadow {
                self
                    .shadow(color : .white, radius: 5, x : -2, y : -2)
                    .shadow(color : .black.opacity(0.3), radius: 3, x : 2, y : 2)
            } else {
                self
            }
        }
    }
}


//Modals and Top/Bottom sheets

//Center growing modal for errors and other views
struct CenterGrowingModalModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPresented ? 1 : 0.5)
            .opacity(isPresented ? 1 : 0)
            .animation(.easeInOut, value: isPresented)
    }
}

// Extension to use the modifier easily
extension View {
    func centerGrowingModal(isPresented: Bool) -> some View {
        self.modifier(CenterGrowingModalModifier(isPresented: isPresented))
    }
}


// Top down sheet, used for the calendar
struct TopDownSheetModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: isPresented ? 0 : -UIScreen.main.bounds.height)
            .animation(.easeInOut(duration: 0.3), value: isPresented)

    }
}

// Extension to use the modifier easily
extension View {
    func topDownSheet(isPresented: Bool) -> some View {
        self.modifier(TopDownSheetModifier(isPresented: isPresented))
    }
}


// Bottom up sheet, used for the calendar

struct BottomUpSheetModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: isPresented ? 0 : UIScreen.main.bounds.height)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// Extension to use the modifier easily
extension View {
    func bottomUpSheet(isPresented: Bool) -> some View {
        self.modifier(BottomUpSheetModifier(isPresented: isPresented))
    }
}


struct LeadingEdgeSheetModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: isPresented ? 0 : -UIScreen.main.bounds.width)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// Extension to use the modifier easily
extension View {
    func leadingEdgeSheet(isPresented: Bool) -> some View {
        self.modifier(LeadingEdgeSheetModifier(isPresented: isPresented))
    }
}



struct TrailingEdgeSheetModifier: ViewModifier {
    let isPresented: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: isPresented ? 0 : UIScreen.main.bounds.width)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// Extension to use the modifier easily
extension View {
    func trailingEdgeSheet(isPresented: Bool) -> some View {
        self.modifier(TrailingEdgeSheetModifier(isPresented: isPresented))
    }
}





#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif


extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}


extension View {
    func placeholder(
        _ text: String,
        when shouldShow: Bool,
        alignment: Alignment = .leading) -> some View {
            
            placeholder(when: shouldShow, alignment: alignment) { Text(text).foregroundColor(.gray.opacity(0.5)) }
    }
}




extension Date {
    func toCustomStringFormat() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM" // Month in full name format
        
        let day = Calendar.current.component(.day, from: self)
        let daySuffix = day.ordinalSuffix()
        
        dateFormatter.dateFormat = "yyyy" // Year in four digits
        let year = dateFormatter.string(from: self)
        
        let month = dateFormatter.monthSymbols[Calendar.current.component(.month, from: self) - 1] // Get full month name
        
        return "\(month) \(day)\(daySuffix), \(year)"
    }
}

extension Int {
    func ordinalSuffix() -> String {
        let ones: Int = self % 10
        let tens: Int = (self / 10) % 10
        if tens == 1 {
            return "th"
        } else {
            switch ones {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
}
