import Foundation
import SwiftUI
import Combine

public class EmojiPickerViewModel: ObservableObject {
    // Configuration and localization
    public let configuration: ElegantConfiguration
    public let localization: ElegantLocalization
    
    // Data
    @Published private(set) var emojiSections: [EmojiSection] = []
    @Published private(set) var filteredEmojis: [Emoji] = []
    @Published private(set) var selectedEmoji: Emoji?
    @Published private(set) var previewingEmoji: Emoji?
    @Published var currentSkinTone: EmojiSkinTone?
    @Published var searchText: String = ""
    @Published var showingSkinToneSelector: Bool = false
    @Published var selectedSectionIndex: Int = 0
    @Published var highlightedEmoji: Emoji?
    @Published var isSearching: Bool = false
    
    // User defaults for storing skin tone preferences if enabled
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // Track the latest search ID to handle concurrent searches
    private var latestSearchID = 0
    
    public init(
        configuration: ElegantConfiguration = ElegantConfiguration(),
        localization: ElegantLocalization = ElegantLocalization(),
        customSections: [EmojiSection]? = nil,
        delegate: ((Emoji?) -> Void)? = nil
    ) {
        self.configuration = configuration
        self.localization = localization
        self.currentSkinTone = configuration.defaultSkinTone
        self.onEmojiSelected = delegate
        
        // Initialize with either custom sections or default emoji sections
        if let customSections = customSections {
            self.emojiSections = customSections
        } else {
            self.emojiSections = Self.getDefaultEmojiSections(config: configuration, localization: localization)
        }
        
        // Set up direct text change monitoring to immediately show loading state
        $searchText
            .sink { [weak self] text in
                if !text.isEmpty {
                    self?.isSearching = true
                    self?.filteredEmojis = [] // Clear results while searching
                } else {
                    self?.isSearching = false
                    self?.filteredEmojis = []
                }
            }
            .store(in: &cancellables)
        
        // Set up debounced search functionality
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(query: searchText)
            }
            .store(in: &cancellables)
    }
    
    // Callback for when an emoji is selected
    public var onEmojiSelected: ((Emoji?) -> Void)?
    
    // MARK: - User Interactions
    
    public func selectEmoji(_ emoji: Emoji) {
        selectedEmoji = emoji
        onEmojiSelected?(emoji)
    }
    
    public func resetEmoji() {
        selectedEmoji = nil
        onEmojiSelected?(nil)
    }
    
    public func selectRandomEmoji() {
        // Flatten all emojis into a single array
        let allEmojis = emojiSections.flatMap { $0.emojis }
        guard let randomEmoji = allEmojis.randomElement() else { return }
        
        selectedEmoji = randomEmoji
        onEmojiSelected?(randomEmoji)
    }
    
    public func startPreview(emoji: Emoji) {
        previewingEmoji = emoji
        
        if emoji.supportsSkinTones && configuration.supportsSkinTones {
            showingSkinToneSelector = true
        }
    }
    
    public func endPreview() {
        previewingEmoji = nil
        showingSkinToneSelector = false
    }
    
    public func applySkinTone(_ skinTone: EmojiSkinTone?) {
        currentSkinTone = skinTone
        
        if configuration.persistSkinTones, let emoji = previewingEmoji, emoji.supportsSkinTones {
            saveSkinTonePreference(for: emoji, skinTone: skinTone)
        }
        
        if let previewingEmoji = previewingEmoji {
            let emojiWithSkinTone = previewingEmoji.duplicate(skinTone)
            self.previewingEmoji = emojiWithSkinTone
        }
    }
    
    // MARK: - Private Methods
    
    private func performSearch(query: String) {
        if query.isEmpty {
            isSearching = false
            filteredEmojis = []
            return
        }
        
        // Generate a unique ID for this search operation to prevent race conditions
        let currentSearchID = latestSearchID + 1
        latestSearchID = currentSearchID
        
        // Perform the search
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let searchTerms = query.lowercased().split(separator: " ").map(String.init)
            
            let results = self.emojiSections.flatMap { $0.emojis }.filter { emoji in
                let descriptionMatch = emoji.description.lowercased().contains(query.lowercased())
                let aliasMatch = emoji.aliases.contains { alias in
                    searchTerms.contains { term in
                        alias.lowercased().contains(term)
                    }
                }
                let tagMatch = emoji.tags.contains { tag in
                    searchTerms.contains { term in
                        tag.lowercased().contains(term)
                    }
                }
                
                return descriptionMatch || aliasMatch || tagMatch
            }
            
            // Only update UI if this is still the latest search operation
            if currentSearchID == self.latestSearchID {
                self.filteredEmojis = results
                self.isSearching = false
            }
        }
    }
    
    private func saveSkinTonePreference(for emoji: Emoji, skinTone: EmojiSkinTone?) {
        if let skinTone = skinTone {
            userDefaults.set(skinTone.rawValue, forKey: "emoji_skintone_\(emoji.emoji)")
        } else {
            userDefaults.removeObject(forKey: "emoji_skintone_\(emoji.emoji)")
        }
    }
    
    private func getSkinTonePreference(for emoji: Emoji) -> EmojiSkinTone? {
        guard let rawValue = userDefaults.string(forKey: "emoji_skintone_\(emoji.emoji)") else {
            return configuration.defaultSkinTone
        }
        
        return EmojiSkinTone.allCases.first { $0.rawValue == rawValue }
    }
    
    // MARK: - Static Methods for Emoji Data
    
    /// Get all emoji as one big array
    public static func getAllEmoji() -> [Emoji] {
        // Debug: List all available resources in the module bundle
        #if DEBUG
        print("Bundle.module resourcePath: \(Bundle.module.resourcePath ?? "nil")")
        
        if let resourcePath = Bundle.module.resourcePath {
            do {
                let fileManager = FileManager.default
                let items = try fileManager.contentsOfDirectory(atPath: resourcePath)
                print("Resources in bundle: \(items)")
            } catch {
                print("Failed to list resources: \(error)")
            }
        }
        #endif
        
        guard let url = Bundle.module.url(forResource: "Emoji Unicode 15.0", withExtension: "json") else {
            print("Failed to find emoji data file")
            
            // Try an alternative approach by searching all bundles
            #if DEBUG
            let allBundles = Bundle.allBundles
            print("Searching in \(allBundles.count) bundles")
            
            for (index, bundle) in allBundles.enumerated() {
                print("Bundle \(index): \(bundle.bundlePath)")
                
                if let resourcePath = bundle.resourcePath {
                    do {
                        let fileManager = FileManager.default
                        let items = try fileManager.contentsOfDirectory(atPath: resourcePath)
                        if !items.isEmpty {
                            print("Resources in bundle \(index): \(items)")
                        }
                        
                        // Check if there's a Resources directory
                        if items.contains("Resources") {
                            let resourcesPath = resourcePath + "/Resources"
                            let resourcesItems = try fileManager.contentsOfDirectory(atPath: resourcesPath)
                            print("Items in Resources directory: \(resourcesItems)")
                            
                            if resourcesItems.contains("Emoji Unicode 15.0.json") {
                                print("Found emoji file in bundle \(index)")
                            }
                        }
                    } catch {
                        print("Failed to list resources for bundle \(index): \(error)")
                    }
                }
                
                if let url = bundle.url(forResource: "Emoji Unicode 15.0", withExtension: "json") {
                    print("Found emoji file in bundle \(index) at path: \(url.path)")
                } else if let url = bundle.url(forResource: "Emoji Unicode 15.0", withExtension: "json", subdirectory: "Resources") {
                    print("Found emoji file with subdirectory in bundle \(index) at path: \(url.path)")
                }
            }
            #endif
            
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let emojis = try JSONDecoder().decode([Emoji].self, from: data)
            return emojis
        } catch {
            print("Failed to decode emoji data: \(error)")
            return []
        }
    }
    
    /// Get default emoji sections based on configuration
    public static func getDefaultEmojiSections(config: ElegantConfiguration, localization: ElegantLocalization) -> [EmojiSection] {
        let allEmojis = getAllEmoji()
        var sections: [EmojiSection] = []
        
        for category in config.categories {
            let categoryEmojis = allEmojis.filter { $0.category == category }
            let sectionIcon = category.icon
            let sectionTitle = localization.categoryTitle(for: category)
            
            sections.append(EmojiSection(title: sectionTitle, icon: sectionIcon, emojis: categoryEmojis))
        }
        
        return sections
    }
} 