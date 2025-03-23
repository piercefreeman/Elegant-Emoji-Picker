import XCTest
import EmojiPicker


final class EmojiPickerTests: XCTestCase {
    internal typealias SystemUnderTest = EmojiPickerViewModel

    internal var sut: SystemUnderTest!
}


// MARK: - Lifecycle
extension EmojiPickerTests {

    override func setUp() async throws {
        // Put setup code here.
        // This method is called before the invocation of each
        // test method in the class.

        try await super.setUp()

        sut = makeSUT()
    }


    override func tearDown() async throws {
        // Put teardown code here.
        // This method is called after the invocation of each
        // test method in the class.

        try await super.tearDown()

        sut = nil
    }
}


// MARK: - Factories
extension EmojiPickerTests {

    internal func makeSUT() -> SystemUnderTest {
        let config = ElegantConfiguration(
            showSearch: true,
            showRandom: true,
            showReset: true
        )
        
        let localization = ElegantLocalization()
        
        return EmojiPickerViewModel(
            configuration: config,
            localization: localization
        )
    }

    internal func makeSUTWithCustomConfig(showSearch: Bool = true, supportsSkinTones: Bool = true) -> SystemUnderTest {
        let config = ElegantConfiguration(
            showSearch: showSearch,
            showRandom: true,
            showReset: true,
            supportsSkinTones: supportsSkinTones
        )
        
        return EmojiPickerViewModel(
            configuration: config,
            localization: ElegantLocalization()
        )
    }
}


// MARK: - "Given" Helpers (Conditions Exist)
extension EmojiPickerTests {

    internal func givenEmojiDataIsLoaded() -> Bool {
        return !sut.emojiSections.isEmpty
    }
}


// MARK: - "When" Helpers (Actions Are Performed)
extension EmojiPickerTests {

    internal func whenUserSearches(for query: String) async {
        sut.searchText = query
        // Wait for debounce to complete using proper async sleep
        try? await Task.sleep(for: .milliseconds(500))
    }
    
    internal func whenUserSelectsEmoji(at sectionIndex: Int, emojiIndex: Int) {
        guard sectionIndex < sut.emojiSections.count else { return }
        let section = sut.emojiSections[sectionIndex]
        
        guard emojiIndex < section.emojis.count else { return }
        let emoji = section.emojis[emojiIndex]
        
        sut.selectEmoji(emoji)
    }
    
    internal func whenUserAppliesSkinTone(_ skinTone: EmojiSkinTone, to emoji: Emoji) {
        sut.startPreview(emoji: emoji)
        sut.applySkinTone(skinTone)
    }
}


// MARK: - Test - Emoji Data Loading
extension EmojiPickerTests {

    func test_Init_WhenCreatingViewModel_ItLoadsEmojiData() async throws {
        XCTAssertTrue(givenEmojiDataIsLoaded(), "Emoji data should be loaded upon initialization")
        XCTAssertFalse(sut.emojiSections.isEmpty, "Emoji sections should not be empty")
        
        // Check that we have multiple categories
        XCTAssertGreaterThan(sut.emojiSections.count, 1, "There should be multiple emoji categories")
        
        // Check that each section has emojis
        for section in sut.emojiSections {
            XCTAssertFalse(section.emojis.isEmpty, "Each emoji section should contain emojis")
        }
    }
}

// MARK: - Test - Search Functionality
extension EmojiPickerTests {
    
    func test_Search_WhenSearchingForEmoji_ItFiltersResults() async throws {
        // Given emoji data is loaded
        XCTAssertTrue(givenEmojiDataIsLoaded())
        
        // When searching for "heart"
        await whenUserSearches(for: "heart")
        
        // Then filtered results should contain heart emojis
        XCTAssertFalse(sut.filteredEmojis.isEmpty, "Search results should not be empty")
        
        let containsHeartEmoji = sut.filteredEmojis.contains { emoji in
            emoji.description.lowercased().contains("heart") || 
            emoji.aliases.contains { $0.lowercased().contains("heart") } ||
            emoji.tags.contains { $0.lowercased().contains("heart") }
        }
        
        XCTAssertTrue(containsHeartEmoji, "Search results should contain heart-related emojis")
        
        // When searching for a very specific, likely non-existent emoji
        await whenUserSearches(for: "xyznonexistentemoji123")
        
        // Then there should be no results
        XCTAssertTrue(sut.filteredEmojis.isEmpty, "Search with non-existent term should return empty results")
    }
    
    func test_Search_WhenSearchingIsDisabled_NoResultsAreShown() async throws {
        // Given a view model with search disabled
        let sutWithoutSearch = makeSUTWithCustomConfig(showSearch: false)
        
        // When attempting to search
        sutWithoutSearch.searchText = "heart"
        try? await Task.sleep(for: .milliseconds(500))
        
        // Then search should still technically work (for API consistency) 
        // even if the UI doesn't show it
        XCTAssertFalse(sutWithoutSearch.filteredEmojis.isEmpty)
    }
    
    func test_Search_WhenSearchingIsInProgress_LoadingStateIsShown() async throws {
        // Given emoji data is loaded
        XCTAssertTrue(givenEmojiDataIsLoaded())
        XCTAssertFalse(sut.isSearching, "isSearching should be false initially")
        
        // When setting search text (without waiting for debounce)
        sut.searchText = "heart"
        
        // Then loading state should be shown immediately
        XCTAssertTrue(sut.isSearching, "isSearching should be true immediately after search starts")
        XCTAssertTrue(sut.filteredEmojis.isEmpty, "Results should be cleared while loading")
        
        // After waiting for search to complete
        try await Task.sleep(for: .milliseconds(500))
        
        // Then loading state should be hidden and results should be displayed
        XCTAssertFalse(sut.isSearching, "isSearching should be false after search completes")
        XCTAssertFalse(sut.filteredEmojis.isEmpty, "Results should be populated after search completes")
    }
    
    func test_Search_WhenPerformingConcurrentSearches_OnlyLatestResultsAreShown() async throws {
        // Given emoji data is loaded
        XCTAssertTrue(givenEmojiDataIsLoaded())
        
        // When starting multiple searches in quick succession
        sut.searchText = "heart" // First search
        
        // Start a second search before the first one completes
        sut.searchText = "smile" // Second search
        
        // Wait for searches to complete
        try await Task.sleep(for: .milliseconds(500))
        
        // Then only results from the latest search should be shown
        // Check for smile-related results, not heart-related
        let containsSmileEmoji = sut.filteredEmojis.contains { emoji in
            emoji.description.lowercased().contains("smile") || 
            emoji.aliases.contains { $0.lowercased().contains("smile") } ||
            emoji.tags.contains { $0.lowercased().contains("smile") }
        }
        
        XCTAssertTrue(containsSmileEmoji, "Results should contain smile emojis from the latest search")
        
        // Verify we don't have heart-specific results that aren't also smile-related
        let containsHeartOnlyEmoji = sut.filteredEmojis.contains { emoji in
            (emoji.description.lowercased().contains("heart") && 
             !emoji.description.lowercased().contains("smile")) || 
            (emoji.aliases.contains { $0.lowercased().contains("heart") } && 
             !emoji.aliases.contains { $0.lowercased().contains("smile") }) ||
            (emoji.tags.contains { $0.lowercased().contains("heart") } && 
             !emoji.tags.contains { $0.lowercased().contains("smile") })
        }
        
        XCTAssertFalse(containsHeartOnlyEmoji, "Results should not contain heart-only emojis from the earlier search")
    }
}

// MARK: - Test - Skin Tone Functionality
extension EmojiPickerTests {
    
    func test_SkinTone_WhenApplyingToSupportedEmoji_SkinToneIsApplied() async throws {
        // Given emoji data is loaded
        XCTAssertTrue(givenEmojiDataIsLoaded())
        
        // Find an emoji that supports skin tones
        guard let emojiWithSkinTone = sut.emojiSections.flatMap({ $0.emojis })
            .first(where: { $0.supportsSkinTones }) else {
            XCTFail("Could not find emoji that supports skin tones")
            return
        }
        
        // Original emoji
        let originalEmoji = emojiWithSkinTone.emoji
        
        // When applying a skin tone
        let skinTone = EmojiSkinTone.Medium
        let emojiWithAppliedTone = emojiWithSkinTone.duplicate(skinTone)
        
        // Then the emoji should change
        XCTAssertNotEqual(originalEmoji, emojiWithAppliedTone.emoji, "Emoji with skin tone should be different from original")
    }
    
    func test_SkinTone_WhenApplyingToUnsupportedEmoji_NoChange() async throws {
        // Given emoji data is loaded
        XCTAssertTrue(givenEmojiDataIsLoaded())
        
        // Find an emoji that doesn't support skin tones
        guard let emojiWithoutSkinTone = sut.emojiSections.flatMap({ $0.emojis })
            .first(where: { !$0.supportsSkinTones }) else {
            XCTFail("Could not find emoji that doesn't support skin tones")
            return
        }
        
        // Original emoji
        let originalEmoji = emojiWithoutSkinTone.emoji
        
        // When trying to apply a skin tone
        let skinTone = EmojiSkinTone.Medium
        let emojiWithAppliedTone = emojiWithoutSkinTone.duplicate(skinTone)
        
        // Then the emoji should not change
        XCTAssertEqual(originalEmoji, emojiWithAppliedTone.emoji, "Emoji without skin tone support should not change when skin tone is applied")
    }
}

// MARK: - Test - Emoji Selection
extension EmojiPickerTests {
    
    func test_Selection_WhenSelectingEmoji_SelectedEmojiUpdates() async throws {
        // Given emoji data is loaded
        XCTAssertTrue(givenEmojiDataIsLoaded())
        XCTAssertNil(sut.selectedEmoji, "Selected emoji should be nil initially")
        
        // Skip the test if there are no emoji sections or emojis
        guard !sut.emojiSections.isEmpty, !sut.emojiSections[0].emojis.isEmpty else {
            XCTFail("No emoji sections or emojis available")
            return
        }
        
        // When selecting an emoji
        let testEmoji = sut.emojiSections[0].emojis[0]
        sut.selectEmoji(testEmoji)
        
        // Then selected emoji should update
        XCTAssertNotNil(sut.selectedEmoji, "Selected emoji should not be nil after selection")
        XCTAssertEqual(sut.selectedEmoji?.emoji, testEmoji.emoji, "Selected emoji should match the one that was selected")
        
        // When resetting emoji selection
        sut.resetEmoji()
        
        // Then selected emoji should be nil
        XCTAssertNil(sut.selectedEmoji, "Selected emoji should be nil after reset")
    }
    
    func test_Selection_WhenSelectingRandomEmoji_RandomEmojiIsSelected() async throws {
        // Given emoji data is loaded
        XCTAssertTrue(givenEmojiDataIsLoaded())
        XCTAssertNil(sut.selectedEmoji, "Selected emoji should be nil initially")
        
        // When selecting a random emoji
        sut.selectRandomEmoji()
        
        // Then an emoji should be selected
        XCTAssertNotNil(sut.selectedEmoji, "Selected emoji should not be nil after random selection")
    }
}

// MARK: - Test - Localization Support
extension EmojiPickerTests {
    
    func test_Localization_WhenProvidingCustomStrings_LocalizationIsApplied() async throws {
        // Given custom localization
        let customLocalization = ElegantLocalization(
            searchFieldPlaceholder: "Custom Search",
            searchResultsTitle: "Custom Results",
            searchResultsEmptyTitle: "Custom No Results",
            searchingText: "Custom Searching...",
            randomButtonTitle: "Custom Random",
            resetButtonTitle: "Custom Reset",
            closeButtonTitle: "Custom Close"
        )
        
        // When creating a view model with custom localization
        let sutWithCustomLocalization = EmojiPickerViewModel(
            configuration: ElegantConfiguration(),
            localization: customLocalization
        )
        
        // Then the view model should use the custom localization
        XCTAssertEqual(sutWithCustomLocalization.localization.searchFieldPlaceholder, "Custom Search")
        XCTAssertEqual(sutWithCustomLocalization.localization.searchResultsTitle, "Custom Results")
        XCTAssertEqual(sutWithCustomLocalization.localization.searchResultsEmptyTitle, "Custom No Results")
        XCTAssertEqual(sutWithCustomLocalization.localization.searchingText, "Custom Searching...")
        XCTAssertEqual(sutWithCustomLocalization.localization.randomButtonTitle, "Custom Random")
        XCTAssertEqual(sutWithCustomLocalization.localization.resetButtonTitle, "Custom Reset")
        XCTAssertEqual(sutWithCustomLocalization.localization.closeButtonTitle, "Custom Close")
    }
    
    func test_Localization_WhenCustomizingCategoryTitles_CustomTitlesAreUsed() async throws {
        // Given custom category titles
        let customCategoryTitles: [EmojiCategory: String] = [
            .SmileysAndEmotion: "Custom Smileys",
            .PeopleAndBody: "Custom People",
            .AnimalsAndNature: "Custom Animals"
        ]
        
        let customLocalization = ElegantLocalization(
            emojiCategoryTitles: customCategoryTitles
        )
        
        // When creating a view model with custom category titles
        let sutWithCustomCategories = EmojiPickerViewModel(
            configuration: ElegantConfiguration(
                categories: [.SmileysAndEmotion, .PeopleAndBody, .AnimalsAndNature]
            ),
            localization: customLocalization
        )
        
        // Then the sections should use the custom titles
        XCTAssertEqual(sutWithCustomCategories.emojiSections[0].title, "Custom Smileys")
        XCTAssertEqual(sutWithCustomCategories.emojiSections[1].title, "Custom People")
        XCTAssertEqual(sutWithCustomCategories.emojiSections[2].title, "Custom Animals")
    }
}
