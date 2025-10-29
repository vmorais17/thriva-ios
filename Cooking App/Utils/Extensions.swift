//
//  Extensions.swift
//  Cooking App
//
//  Created by Vinicius Morais on 10/29/25.
//

import SwiftUI
import Foundation

// MARK: - Color Extensions
extension Color {
    static let recipeOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let recipeGreen = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let recipeRed = Color(red: 0.9, green: 0.3, blue: 0.3)
}

// MARK: - String Extensions
extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isNotEmpty: Bool {
        !isEmpty
    }
}

// MARK: - Array Extensions
extension Array where Element == String {
    var joinedWithCommas: String {
        joined(separator: ", ")
    }
}

// MARK: - Date Extensions
extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - View Extensions
extension View {
    func recipeCardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    func recipeButtonStyle(isDisabled: Bool = false) -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: isDisabled ? [.gray] : [.recipeOrange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .recipeOrange.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Binding Extensions
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// MARK: - Recipe Extensions
extension Recipe {
    var displayTitle: String {
        title.isEmpty ? "Untitled Recipe" : title
    }
    
    var hasIngredients: Bool {
        !ingredients.isEmpty
    }
    
    var hasInstructions: Bool {
        !instructions.isEmpty
    }
    
    var isComplete: Bool {
        !title.isEmpty && hasIngredients && hasInstructions
    }
    
    var estimatedReadingTime: Int {
        let wordsPerMinute = 200
        let wordCount = generatedText.components(separatedBy: .whitespacesAndNewlines).count
        return max(1, wordCount / wordsPerMinute)
    }
}