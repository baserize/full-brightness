import Foundation

enum LocalizedDisplayName {
    static func preferred(from names: [String: String]) -> String? {
        let currentIdentifier = Locale.current.identifier
        let currentLanguage = currentIdentifier.split(separator: "_").first.map(String.init)

        var identifiers = [currentIdentifier]
        if let currentLanguage {
            identifiers.append(currentLanguage)
        }
        identifiers.append(contentsOf: ["en_US", "en"])

        identifiers.append(contentsOf: Locale.preferredLanguages)

        var seenIdentifiers = Set<String>()
        for identifier in identifiers where seenIdentifiers.insert(identifier).inserted {
            if let name = names[identifier], !name.isEmpty {
                return name
            }
        }

        return names.values.first { !$0.isEmpty }
    }
}
