import SwiftUI

struct LoadoutView: View {
    let characterManager: CharacterManager
    @State private var selectedSlot: Move = .rock
    @State private var showStore = false
    let storeManager: StoreManager

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Current loadout preview
                    currentLoadoutSection
                        .padding(.top, 8)

                    // Slot selector tabs
                    slotTabs

                    // Character grid
                    characterGrid

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 24))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showStore = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bag.fill")
                            Text("Store")
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.2)))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showStore) {
                StoreView(storeManager: storeManager, characterManager: characterManager)
            }
        }
    }

    private var currentLoadoutSection: some View {
        VStack(spacing: 12) {
            Text("Your Loadout")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                ForEach(Move.allCases, id: \.self) { slot in
                    let char = characterManager.character(for: slot)
                    VStack(spacing: 6) {
                        CharacterDisplayView(imageName: char.imageName, emoji: char.emoji, size: 44)
                        Text(char.name)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(slot.name)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    private var slotTabs: some View {
        HStack(spacing: 8) {
            ForEach(Move.allCases, id: \.self) { slot in
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        selectedSlot = slot
                    }
                } label: {
                    Text(slot.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(selectedSlot == slot ? .black : .white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedSlot == slot ? .white : .white.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var characterGrid: some View {
        let available = characterManager.availableCharacters(for: selectedSlot)
        let currentId = characterManager.loadout.characterId(for: selectedSlot)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(available) { character in
                let isSelected = character.id == currentId
                Button {
                    characterManager.selectCharacter(character, for: selectedSlot)
                } label: {
                    VStack(spacing: 8) {
                        CharacterDisplayView(imageName: character.imageName, emoji: character.emoji, size: 44)
                        Text(character.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(character.flavorText)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isSelected ? .white.opacity(0.2) : .white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isSelected ? Theme.winGold : .clear, lineWidth: 3)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
