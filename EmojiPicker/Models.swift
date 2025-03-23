import Foundation
import SwiftUI

/// Struct representing a single emoji
public struct Emoji: Decodable, Equatable, Identifiable {
    public var id: String { emoji }
    public let emoji: String
    public let description: String
    public let category: EmojiCategory
    public let aliases: [String]
    public let tags: [String]
    public let supportsSkinTones: Bool
    public let iOSVersion: String
    
    /// Get a string representation of this emoji with another skin tone
    /// - Parameter withSkinTone: new skin tone to use
    /// - Returns: a string of the new emoji with the applied skin tone
    public func emoji(_ withSkinTone: EmojiSkinTone?) -> String? {
        // Applying skin tones with Dan Wood's code: https://github.com/Remotionco/Emoji-Library-and-Utilities
        
        if !supportsSkinTones { return nil }
        // If skin tone is nil, return the default yellow emoji
        guard let withSkinTone = withSkinTone else {
            if let unicode = emoji.unicodeScalars.first { return String(unicode) }
            else { return emoji }
        }
        
        var wasToneInserted = false
        guard let toneScalar = Unicode.Scalar(withSkinTone.rawValue) else { return nil }

        var scalars = [UnicodeScalar]()
        // Either replace first found Fully Qualified 0xFE0F, or add to the end or before the first ZWJ, 0x200D.
        for scalar in emoji.unicodeScalars {
            if !wasToneInserted {
                switch scalar.value {
                case 0xFE0F:
                    scalars.append(toneScalar) // tone scalar goes in place of the FE0F.
                    wasToneInserted = true
                case 0x200D:
                    scalars.append(toneScalar) // Insert the tone selector
                    scalars.append(scalar) // and then the ZWJ afterwards.
                    wasToneInserted = true
                default:
                    scalars.append(scalar)
                }
            } else { // already handled tone, just append the other selectors it finds.
                scalars.append(scalar)
            }
        }

        if !wasToneInserted {
            scalars.append(toneScalar) // Append at the end if needed.
        }
        
        var string = ""
        scalars.forEach({ string.append($0.description) })
        return string
    }
    
    enum CodingKeys: CodingKey {
        case emoji
        case description
        case category
        case aliases
        case tags
        case skin_tones
        case ios_version
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.description = try container.decode(String.self, forKey: .description)
        self.category = try container.decode(EmojiCategory.self, forKey: .category)
        self.aliases = try container.decode([String].self, forKey: .aliases)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.supportsSkinTones = try container.decodeIfPresent(Bool.self, forKey: .skin_tones) ?? false
        self.iOSVersion = try container.decode(String.self, forKey: .ios_version)
    }
    
    /// Create an instance of an emoji
    /// - Parameters:
    ///    - emoji: string representation of this emoji
    ///    - description: unicode textual description
    ///    - category: unicode category of this emoji
    ///    - aliases: similar names for this emoji
    ///    - tags: this emojis tags used for search
    ///    - supportsSkinTones: weather this emoji supports skin tones
    ///    - iOSVersion: the earliest iOS which supports this emoji
    public init(emoji: String, description: String, category: EmojiCategory, aliases: [String], tags: [String], supportsSkinTones: Bool, iOSVersion: String) {
        self.emoji = emoji
        self.description = description
        self.category = category
        self.aliases = aliases
        self.tags = tags
        self.supportsSkinTones = supportsSkinTones
        self.iOSVersion = iOSVersion
    }
    
    /// Create a duplicate of this emoji with another skin tone
    /// - Parameter withSkinTone: new skin tone to use. If nil, creates a standard yellow emoji
    /// - Returns: new Emoji with the applied skin tone
    public func duplicate(_ withSkinTone: EmojiSkinTone?) -> Emoji {
        return Emoji(emoji: self.emoji(withSkinTone) ?? emoji, description: description, category: category, aliases: aliases, tags: tags, supportsSkinTones: supportsSkinTones, iOSVersion: iOSVersion)
    }
}

/// Struct describing section of emojis
public struct EmojiSection: Identifiable {
    public var id: String { title }
    public let title: String
    public let icon: String
    public var emojis: [Emoji]
    
    /// Create an instance of an emoji section.
    /// - Parameters:
    ///   - title: Displayed section title
    ///   - icon: Displayed section icon name (SF Symbol name)
    ///   - emojis: Emojis contained in this section 
    public init(title: String, icon: String, emojis: [Emoji]) {
        self.title = title
        self.icon = icon
        self.emojis = emojis
    }
}

public enum EmojiSkinTone: String, CaseIterable {
    case Light = "🏻"
    case MediumLight = "🏼"
    case Medium = "🏽"
    case MediumDark = "🏾"
    case Dark = "🏿"
    
    public var displayName: String {
        switch self {
        case .Light: return "Light"
        case .MediumLight: return "Medium Light"
        case .Medium: return "Medium"
        case .MediumDark: return "Medium Dark"
        case .Dark: return "Dark"
        }
    }
}

public enum EmojiCategory: String, CaseIterable, Decodable {
    case SmileysAndEmotion = "Smileys & Emotion"
    case PeopleAndBody = "People & Body"
    case AnimalsAndNature = "Animals & Nature"
    case FoodAndDrink = "Food & Drink"
    case TravelAndPlaces = "Travel & Places"
    case Activities = "Activities"
    case Objects = "Objects"
    case Symbols = "Symbols"
    case Flags = "Flags"
    
    public var icon: String {
        switch self {
        case .SmileysAndEmotion: return "face.smiling"
        case .PeopleAndBody: return "person"
        case .AnimalsAndNature: return "leaf"
        case .FoodAndDrink: return "fork.knife"
        case .TravelAndPlaces: return "car"
        case .Activities: return "basketball"
        case .Objects: return "lightbulb"
        case .Symbols: return "heart"
        case .Flags: return "flag"
        }
    }
}

/// Configuration for the emoji picker
public struct ElegantConfiguration {
    public let showSearch: Bool
    public let showRandom: Bool
    public let showReset: Bool
    public let showClose: Bool
    public let supportsPreview: Bool
    public let categories: [EmojiCategory]
    public let supportsSkinTones: Bool
    public let persistSkinTones: Bool
    public let defaultSkinTone: EmojiSkinTone?
    
    public init(
        showSearch: Bool = true,
        showRandom: Bool = true,
        showReset: Bool = true,
        showClose: Bool = true,
        supportsPreview: Bool = true,
        categories: [EmojiCategory] = EmojiCategory.allCases,
        supportsSkinTones: Bool = true,
        persistSkinTones: Bool = true,
        defaultSkinTone: EmojiSkinTone? = nil
    ) {
        self.showSearch = showSearch
        self.showRandom = showRandom
        self.showReset = showReset
        self.showClose = showClose
        self.supportsPreview = supportsPreview
        self.categories = categories
        self.supportsSkinTones = supportsSkinTones
        self.persistSkinTones = persistSkinTones
        self.defaultSkinTone = defaultSkinTone
    }
}

/// Localization for the emoji picker
public struct ElegantLocalization {
    public let searchFieldPlaceholder: String
    public let searchResultsTitle: String
    public let searchResultsEmptyTitle: String
    public let searchingText: String
    public let randomButtonTitle: String
    public let resetButtonTitle: String
    public let closeButtonTitle: String
    public let emojiCategoryTitles: [EmojiCategory: String]
    
    public init(
        searchFieldPlaceholder: String = "Search",
        searchResultsTitle: String = "Search results",
        searchResultsEmptyTitle: String = "No results",
        searchingText: String = "Searching...",
        randomButtonTitle: String = "Random",
        resetButtonTitle: String = "Reset",
        closeButtonTitle: String = "Close",
        emojiCategoryTitles: [EmojiCategory: String] = [:]
    ) {
        self.searchFieldPlaceholder = searchFieldPlaceholder
        self.searchResultsTitle = searchResultsTitle
        self.searchResultsEmptyTitle = searchResultsEmptyTitle
        self.searchingText = searchingText
        self.randomButtonTitle = randomButtonTitle
        self.resetButtonTitle = resetButtonTitle
        self.closeButtonTitle = closeButtonTitle
        self.emojiCategoryTitles = emojiCategoryTitles
    }
    
    public func categoryTitle(for category: EmojiCategory) -> String {
        return emojiCategoryTitles[category] ?? category.rawValue
    }
} 