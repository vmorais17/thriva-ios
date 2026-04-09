//
//  RecipeParser.swift
//  Cooking App
//
//  Created by Codex on 11/10/24.
//

import Foundation

struct RecipeParser {

    // MARK: - Text parsing (primary — matches LoRA text-recipe training format)

    /// Parses a free-form text recipe (the format the LoRA was trained on).
    /// Falls back to JSON parsing if the response looks like JSON.
    static func parse(_ text: String, parameters: GenerationParameters? = nil) throws -> Recipe {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") {
            if let r = try? parseRecipeJSON(trimmed, parameters: parameters) { return r }
        }
        return try parseRecipeText(trimmed, parameters: parameters)
    }

    private static func parseRecipeText(_ text: String, parameters: GenerationParameters? = nil) throws -> Recipe {
        let rawLines = text.components(separatedBy: .newlines)
        let lines = rawLines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var title = ""
        var ingredients: [String] = []
        var instructions: [String] = []
        var cookingTime = parameters?.cookingTime ?? 0
        var servings   = parameters?.servings   ?? 4

        enum Section { case none, ingredients, instructions, notes }
        var section: Section = .none

        let introWords = ["here", "sure", "of course", "certainly", "great", "i'll", "i will", "let me"]

        for line in lines {
            let lower = line.lowercased()
            let clean = stripMarkdown(line)
            guard !clean.isEmpty else { continue }

            // Skip intro sentences ("Here's a recipe…")
            if title.isEmpty && introWords.contains(where: { lower.hasPrefix($0) }) { continue }

            // Section headers
            if isSectionHeader(lower, keywords: ["ingredient", "what you'll need", "you'll need"]) {
                section = .ingredients; continue
            }
            if isSectionHeader(lower, keywords: ["instruction", "direction", "step", "method", "how to", "preparation"]) {
                section = .instructions; continue
            }
            if isSectionHeader(lower, keywords: ["note", "tip", "variation"]) {
                section = .notes; continue
            }

            // Metadata — time and servings can appear anywhere
            if cookingTime == 0, let t = extractMinutes(from: lower) { cookingTime = t }
            if let s = extractServings(from: lower) { servings = s }

            // Title: first useful non-header line
            if title.isEmpty {
                title = clean
                continue
            }

            // List items
            let isListItem = isListLine(line)

            switch section {
            case .ingredients:
                if isListItem || !looksLikeHeader(lower) {
                    let item = stripListPrefix(clean)
                    if !item.isEmpty { ingredients.append(item) }
                }
            case .instructions:
                if isListItem || !looksLikeHeader(lower) {
                    let step = stripListPrefix(clean)
                    if !step.isEmpty { instructions.append(step) }
                }
            case .none:
                // Before any section header: list lines are heuristically classified
                if isListItem {
                    let item = stripListPrefix(clean)
                    if !item.isEmpty {
                        // Short items with quantities → ingredient; longer → instruction
                        if item.count < 60 && !item.hasPrefix("Heat") && !item.hasPrefix("Cook") &&
                           !item.hasPrefix("Add") && !item.hasPrefix("Mix") && !item.hasPrefix("Stir") &&
                           !item.hasPrefix("Bake") && !item.hasPrefix("Boil") && !item.hasPrefix("Fry") &&
                           !item.hasPrefix("Season") && !item.hasPrefix("Serve") {
                            ingredients.append(item)
                        } else {
                            instructions.append(item)
                        }
                    }
                }
            case .notes:
                break
            }
        }

        guard !title.isEmpty, !ingredients.isEmpty, !instructions.isEmpty else {
            throw RecipeError.parsingFailed
        }

        return Recipe(
            title: title,
            ingredients: ingredients,
            instructions: instructions,
            cookingTime: max(0, cookingTime),
            servings:    max(1, servings),
            category:    parameters?.category   ?? .main,
            difficulty:  parameters?.difficulty ?? .easy,
            generatedText: text,
            dateCreated: Date()
        )
    }

    // MARK: - JSON parsing (kept as fallback)

    private struct Payload: Decodable {
        let title: String?
        let ingredients: [String]?
        let instructions: [String]?
        let cookingTime: Int?
        let servings: Int?
        let category: String?
        let difficulty: String?
        let notes: String?
    }

    private static func recoverTruncatedJSON(_ raw: String) -> String? {
        guard let start = raw.firstIndex(of: "{"),
              let end   = raw.lastIndex(of: "}")  else { return nil }
        return String(raw[start...end])
    }

    static func parseRecipeJSON(_ json: String, parameters: GenerationParameters? = nil) throws -> Recipe {
        let decoder = JSONDecoder()
        let payload: Payload
        do {
            guard let data = json.data(using: .utf8) else { throw RecipeError.parsingFailed }
            payload = try decoder.decode(Payload.self, from: data)
        } catch {
            guard let recovered = Self.recoverTruncatedJSON(json),
                  let data      = recovered.data(using: .utf8),
                  let p         = try? decoder.decode(Payload.self, from: data) else {
                throw RecipeError.parsingFailed
            }
            payload = p
        }

        let title        = payload.title?.trimmed ?? ""
        let ingredients  = (payload.ingredients  ?? []).map { $0.trimmed }.filter { !$0.isEmpty }
        let instructions = (payload.instructions ?? []).map { $0.trimmed }.filter { !$0.isEmpty }

        guard !title.isEmpty, !ingredients.isEmpty, !instructions.isEmpty else {
            throw RecipeError.parsingFailed
        }

        let category    = RecipeCategory(flexible: payload.category)   ?? parameters?.category   ?? .main
        let difficulty  = RecipeDifficulty(flexible: payload.difficulty) ?? parameters?.difficulty ?? .easy
        let cookingTime = payload.cookingTime ?? parameters?.cookingTime ?? 0
        let servings    = payload.servings    ?? parameters?.servings    ?? 1

        var generatedText = json
        if let notes = payload.notes?.trimmed, !notes.isEmpty {
            generatedText += "\n\nNotes: \(notes)"
        }

        return Recipe(
            title: title,
            ingredients: ingredients,
            instructions: instructions,
            cookingTime: max(0, cookingTime),
            servings:    max(1, servings),
            category:    category,
            difficulty:  difficulty,
            generatedText: generatedText,
            dateCreated: Date()
        )
    }

    // MARK: - Helpers

    private static func stripMarkdown(_ s: String) -> String {
        s.replacingOccurrences(of: "**", with: "")
         .replacingOccurrences(of: "__", with: "")
         .replacingOccurrences(of: "*",  with: "")
         .replacingOccurrences(of: "#",  with: "")
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isSectionHeader(_ lower: String, keywords: [String]) -> Bool {
        keywords.contains(where: { lower.contains($0) }) &&
        (lower.hasSuffix(":") || lower.count < 40)
    }

    private static func looksLikeHeader(_ lower: String) -> Bool {
        lower.hasSuffix(":") && lower.count < 40
    }

    private static func isListLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("-") || t.hasPrefix("•") || t.hasPrefix("*") || t.hasPrefix("·") { return true }
        // Numbered: "1." "1)" "Step 1:"
        if let first = t.first, first.isNumber { return true }
        return false
    }

    private static func stripListPrefix(_ s: String) -> String {
        var r = s
        if r.hasPrefix("-") || r.hasPrefix("•") || r.hasPrefix("*") || r.hasPrefix("·") {
            r = String(r.dropFirst()).trimmingCharacters(in: .whitespaces)
        } else if let dot = r.firstIndex(of: "."), r[r.startIndex].isNumber {
            r = String(r[r.index(after: dot)...]).trimmingCharacters(in: .whitespaces)
        } else if let paren = r.firstIndex(of: ")"), r[r.startIndex].isNumber {
            r = String(r[r.index(after: paren)...]).trimmingCharacters(in: .whitespaces)
        }
        return r
    }

    private static func extractMinutes(from lower: String) -> Int? {
        let pattern = #"(\d+)\s*(?:min(?:ute)?s?|hrs?|hours?)"#
        guard let range = lower.range(of: pattern, options: .regularExpression),
              let numRange = lower.range(of: #"\d+"#, options: .regularExpression, range: range),
              let value = Int(lower[numRange]) else { return nil }
        let isHour = lower[range].contains("h")
        return isHour ? value * 60 : value
    }

    private static func extractServings(from lower: String) -> Int? {
        let pattern = #"(\d+)\s*(?:serving|portion|person|people)"#
        guard let range = lower.range(of: pattern, options: .regularExpression),
              let numRange = lower.range(of: #"\d+"#, options: .regularExpression, range: range) else { return nil }
        return Int(lower[numRange])
    }
}
