//
//  ContentView.swift
//  EmojiDemo
//
//  Created by Pierce Freeman on 3/22/25.
//

import SwiftUI
import EmojiPicker

struct ContentView: View {
    @State private var selectedEmoji: Emoji?
    @State private var isPickerPresented = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Elegant Emoji Picker Demo")
                .font(.title)
                .fontWeight(.bold)
            
            // Display selected emoji or placeholder
            VStack {
                if let emoji = selectedEmoji {
                    Text(emoji.emoji)
                        .font(.system(size: 80))
                    
                    Text(emoji.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if emoji.supportsSkinTones {
                        Text("Supports skin tones")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary)
                    
                    Text("No emoji selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(Color(.windowBackgroundColor).opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Option 1: Using the built-in EmojiPickerButton
            VStack(alignment: .leading) {
                Text("Option 1: EmojiPickerButton")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                EmojiPickerButton(onEmojiSelected: { emoji in
                    self.selectedEmoji = emoji
                }) {
                    HStack {
                        Image(systemName: "face.smiling.fill")
                        Text("Choose Emoji with Button")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Option 2: Custom implementation with sheet
            VStack(alignment: .leading) {
                Text("Option 2: Custom Sheet Implementation")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Button {
                    isPickerPresented = true
                } label: {
                    HStack {
                        Image(systemName: "square.grid.3x2.fill")
                        Text("Open Emoji Picker in Sheet")
                    }
                    .padding()
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .sheet(isPresented: $isPickerPresented) {
                    VStack {
                        HStack {
                            Text("Select an Emoji")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Done") {
                                isPickerPresented = false
                            }
                        }
                        .padding()
                        
                        EmojiPicker(
                            configuration: ElegantConfiguration(
                                showSearch: true,
                                showRandom: true,
                                showReset: true,
                                supportsSkinTones: true,
                                persistSkinTones: true
                            ),
                            onEmojiSelected: { emoji in
                                if let emoji = emoji {
                                    self.selectedEmoji = emoji
                                    isPickerPresented = false
                                }
                            }
                        )
                    }
                    .padding()
                }
            }
            .padding(.horizontal)
            
            // Reset button
            Button("Reset Selection") {
                selectedEmoji = nil
            }
            .padding()
            .disabled(selectedEmoji == nil)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 500)
    }
}

#Preview {
    ContentView()
}
