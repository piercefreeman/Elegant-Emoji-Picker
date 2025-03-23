import SwiftUI

public struct EmojiPicker: View {
    @StateObject private var viewModel: EmojiPickerViewModel
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var previewOffset: CGPoint = .zero
    @State private var selectorOffset: CGPoint = .zero
    
    public init(
        configuration: ElegantConfiguration = ElegantConfiguration(),
        localization: ElegantLocalization = ElegantLocalization(),
        customSections: [EmojiSection]? = nil,
        onEmojiSelected: ((Emoji?) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: EmojiPickerViewModel(
            configuration: configuration,
            localization: localization,
            customSections: customSections,
            delegate: onEmojiSelected
        ))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top bar with search, random, reset options
            topBar
            
            // Main emoji grid content
            if viewModel.searchText.isEmpty {
                mainContent
            } else {
                searchResultsView
            }
            
            // Bottom category toolbar
            if viewModel.configuration.categories.count > 1 {
                Divider()
                CategoryToolbar(
                    sections: viewModel.emojiSections,
                    selectedSectionIndex: $viewModel.selectedSectionIndex
                )
            }
        }
        .frame(idealWidth: 500, idealHeight: 400)
        .frame(minWidth: 400, minHeight: 300)
        .padding(.vertical)
        .background(Color(.windowBackgroundColor))
        .overlay(emojiPreviewOverlay)
        .overlay(skinToneSelectorOverlay)
    }
    
    // MARK: - Views
    
    private var topBar: some View {
        HStack(spacing: 16) {
            if viewModel.configuration.showSearch {
                searchField
            }
            
            Spacer()
            
            if viewModel.configuration.showRandom {
                Button(viewModel.localization.randomButtonTitle) {
                    viewModel.selectRandomEmoji()
                }
                .help("Select a random emoji")
            }
            
            if viewModel.configuration.showReset {
                Button(viewModel.localization.resetButtonTitle) {
                    viewModel.resetEmoji()
                }
                .help("Reset emoji selection")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(viewModel.localization.searchFieldPlaceholder, text: $viewModel.searchText)
                .textFieldStyle(.plain)
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.textBackgroundColor))
        )
        .frame(width: 200)
    }
    
    private var mainContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(Array(viewModel.emojiSections.enumerated()), id: \.element.id) { index, section in
                        Section(header: SectionHeader(title: section.title)) {
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 10), count: 8), spacing: 10) {
                                ForEach(section.emojis) { emoji in
                                    EmojiCell(
                                        emoji: emoji,
                                        isHighlighted: viewModel.highlightedEmoji?.id == emoji.id,
                                        action: {
                                            viewModel.selectEmoji(emoji)
                                        },
                                        longPressAction: {
                                            if viewModel.configuration.supportsPreview {
                                                viewModel.startPreview(emoji: emoji)
                                            }
                                        }
                                    )
                                    .id("\(section.id)_\(emoji.id)")
                                    .onHover { isHovered in
                                        if isHovered {
                                            viewModel.highlightedEmoji = emoji
                                        } else if viewModel.highlightedEmoji?.id == emoji.id {
                                            viewModel.highlightedEmoji = nil
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 20)
                        }
                        .id(section.id)
                    }
                }
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: viewModel.selectedSectionIndex) { newIndex in
                withAnimation {
                    let sectionId = viewModel.emojiSections[newIndex].id
                    scrollProxy?.scrollTo(sectionId, anchor: .top)
                }
            }
        }
    }
    
    private var searchResultsView: some View {
        VStack {
            if viewModel.filteredEmojis.isEmpty {
                Text(viewModel.localization.searchResultsEmptyTitle)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: viewModel.localization.searchResultsTitle)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 10), count: 8), spacing: 10) {
                            ForEach(viewModel.filteredEmojis) { emoji in
                                EmojiCell(
                                    emoji: emoji,
                                    isHighlighted: viewModel.highlightedEmoji?.id == emoji.id,
                                    action: {
                                        viewModel.selectEmoji(emoji)
                                    },
                                    longPressAction: {
                                        if viewModel.configuration.supportsPreview {
                                            viewModel.startPreview(emoji: emoji)
                                        }
                                    }
                                )
                                .onHover { isHovered in
                                    if isHovered {
                                        viewModel.highlightedEmoji = emoji
                                    } else if viewModel.highlightedEmoji?.id == emoji.id {
                                        viewModel.highlightedEmoji = nil
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    private var emojiPreviewOverlay: some View {
        ZStack {
            if let emoji = viewModel.previewingEmoji {
                EmojiPreview(emoji: emoji)
                    .position(previewOffset)
                    .transition(.opacity)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                previewOffset = value.location
                            }
                    )
                    .onAppear {
                        previewOffset = CGPoint(x: 250, y: 200)
                    }
                    .onTapGesture {
                        viewModel.endPreview()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.previewingEmoji != nil)
    }
    
    private var skinToneSelectorOverlay: some View {
        ZStack {
            if viewModel.showingSkinToneSelector, let emoji = viewModel.previewingEmoji, emoji.supportsSkinTones {
                SkinToneSelector(
                    onSkinToneSelected: { skinTone in
                        viewModel.applySkinTone(skinTone)
                    },
                    currentSkinTone: viewModel.currentSkinTone
                )
                .position(selectorOffset)
                .onAppear {
                    selectorOffset = CGPoint(x: 250, y: 350)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showingSkinToneSelector)
    }
}

// MARK: - Standalone usage

/// Present an emoji picker in a popover or sheet
public struct EmojiPickerButton<Label: View>: View {
    @State private var isPresented = false
    private let label: Label
    private let configuration: ElegantConfiguration
    private let localization: ElegantLocalization
    private let customSections: [EmojiSection]?
    private let onEmojiSelected: (Emoji?) -> Void
    
    public init(
        configuration: ElegantConfiguration = ElegantConfiguration(),
        localization: ElegantLocalization = ElegantLocalization(),
        customSections: [EmojiSection]? = nil,
        onEmojiSelected: @escaping (Emoji?) -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.configuration = configuration
        self.localization = localization
        self.customSections = customSections
        self.onEmojiSelected = onEmojiSelected
        self.label = label()
    }
    
    public var body: some View {
        Button {
            isPresented = true
        } label: {
            label
        }
        .popover(isPresented: $isPresented) {
            EmojiPicker(
                configuration: configuration,
                localization: localization,
                customSections: customSections,
                onEmojiSelected: { emoji in
                    onEmojiSelected(emoji)
                    isPresented = false
                }
            )
            .frame(width: 500, height: 400)
        }
    }
} 