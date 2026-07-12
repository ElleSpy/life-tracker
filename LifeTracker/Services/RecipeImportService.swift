import Foundation

/// A recipe parsed from a web page, before the user reviews and saves it.
struct ParsedRecipe {
    var name: String
    var summary: String
    var servings: Int
    /// Ingredient lines exactly as written on the page ("2 cups flour").
    var ingredients: [String]
    var steps: [String]
}

enum RecipeImportError: LocalizedError {
    case badURL
    case network
    case notFound

    var errorDescription: String? {
        switch self {
        case .badURL: return "That doesn't look like a valid link."
        case .network: return "Couldn't load that page. Check the link and your connection."
        case .notFound: return "Couldn't find a recipe on that page. Try a different link."
        }
    }
}

/// Imports a recipe from a URL by reading schema.org/Recipe JSON-LD, which the
/// large majority of recipe sites embed.
protocol RecipeImportService {
    func importRecipe(from urlString: String) async throws -> ParsedRecipe
}

final class WebRecipeImportService: RecipeImportService {
    func importRecipe(from urlString: String) async throws -> ParsedRecipe {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalised = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: normalised), url.host != nil else {
            throw RecipeImportError.badURL
        }

        let html: String
        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (compatible; LifeTracker/1.0)", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            html = String(data: data, encoding: .utf8)
                ?? String(decoding: data, as: UTF8.self)
        } catch {
            throw RecipeImportError.network
        }

        for object in Self.jsonLDObjects(in: html) {
            if let recipe = Self.findRecipe(in: object) {
                return Self.parse(recipe)
            }
        }
        throw RecipeImportError.notFound
    }

    // MARK: - JSON-LD extraction

    /// Parse every `<script type="application/ld+json">` block into JSON objects.
    private static func jsonLDObjects(in html: String) -> [Any] {
        let pattern = "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>(.*?)</script>"
        guard let regex = try? NSRegularExpression(
            pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { return [] }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        var results: [Any] = []
        for match in regex.matches(in: html, range: range) {
            guard match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: html) else { continue }
            let json = String(html[r]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = json.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data) {
                results.append(object)
            }
        }
        return results
    }

    /// Recursively search a JSON-LD value for an object typed as a Recipe.
    private static func findRecipe(in value: Any) -> [String: Any]? {
        if let dict = value as? [String: Any] {
            if typeContainsRecipe(dict["@type"]) { return dict }
            for nested in dict.values {
                if let found = findRecipe(in: nested) { return found }
            }
        } else if let array = value as? [Any] {
            for element in array {
                if let found = findRecipe(in: element) { return found }
            }
        }
        return nil
    }

    private static func typeContainsRecipe(_ type: Any?) -> Bool {
        if let string = type as? String { return string.caseInsensitiveCompare("Recipe") == .orderedSame }
        if let array = type as? [String] { return array.contains { $0.caseInsensitiveCompare("Recipe") == .orderedSame } }
        return false
    }

    // MARK: - Mapping

    private static func parse(_ recipe: [String: Any]) -> ParsedRecipe {
        ParsedRecipe(
            name: (recipe["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Imported recipe",
            summary: (recipe["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            servings: servings(from: recipe["recipeYield"]),
            ingredients: stringList(recipe["recipeIngredient"] ?? recipe["ingredients"]),
            steps: instructions(from: recipe["recipeInstructions"])
        )
    }

    private static func servings(from value: Any?) -> Int {
        if let n = value as? Int { return max(1, n) }
        if let n = value as? Double { return max(1, Int(n)) }
        if let s = value as? String, let n = Int(s.prefix { $0.isNumber }) { return max(1, n) }
        if let arr = value as? [Any] { return servings(from: arr.first) }
        return 2
    }

    private static func stringList(_ value: Any?) -> [String] {
        if let s = value as? String { return [s] }
        if let arr = value as? [Any] {
            return arr.compactMap { $0 as? String }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return []
    }

    /// recipeInstructions can be a string, an array of strings, an array of
    /// HowToStep objects, or HowToSection objects containing steps.
    private static func instructions(from value: Any?) -> [String] {
        if let s = value as? String {
            return s.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        guard let array = value as? [Any] else { return [] }
        var steps: [String] = []
        for element in array {
            if let s = element as? String {
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { steps.append(t) }
            } else if let dict = element as? [String: Any] {
                if let text = (dict["text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !text.isEmpty {
                    steps.append(text)
                } else if let nested = dict["itemListElement"] {
                    steps.append(contentsOf: instructions(from: nested))
                }
            }
        }
        return steps
    }
}

/// Preview/demo import that returns a fixed sample.
final class MockRecipeImportService: RecipeImportService {
    func importRecipe(from urlString: String) async throws -> ParsedRecipe {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return ParsedRecipe(
            name: "Imported: Tomato pasta",
            summary: "A quick weeknight pasta from the web.",
            servings: 4,
            ingredients: ["400 g pasta", "2 tbsp olive oil", "1 tin chopped tomatoes", "2 cloves garlic"],
            steps: ["Boil the pasta.", "Fry garlic in oil, add tomatoes, simmer.", "Toss together and serve."]
        )
    }
}
