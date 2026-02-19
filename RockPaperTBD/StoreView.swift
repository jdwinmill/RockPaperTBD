import SwiftUI
import StoreKit

struct StoreView: View {
    let storeManager: StoreManager
    let characterManager: CharacterManager
    let catalogManager: CatalogManager
    let imageCache: PackImageCache

    @State private var purchasingId: String?
    @Environment(\.dismiss) private var dismiss

    private var visiblePacks: [CharacterPack] {
        catalogManager.storePacks(purchasedIds: characterManager.purchasedPackIds)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Character Packs")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 8)

                        ForEach(visiblePacks) { pack in
                            packCard(pack)
                        }

                        Button {
                            Task { await storeManager.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
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
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await storeManager.loadProducts(for: catalogManager.packs)
            await storeManager.restorePurchases()
            syncPurchases()
        }
    }

    private func packCard(_ pack: CharacterPack) -> some View {
        let owned = characterManager.isPurchased(packId: pack.id)
        let product = storeManager.products.first { $0.id == pack.productId }
        let isPurchasing = purchasingId == pack.productId
        let isCached = imageCache.cachedPacks.contains(pack.id)
        let isDownloading = imageCache.downloadingPacks.contains(pack.id)

        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(pack.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if owned {
                    Text("OWNED")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.winGold))
                }
            }

            HStack(spacing: 12) {
                ForEach(pack.characters) { character in
                    VStack(spacing: 6) {
                        CharacterDisplayView(imageName: character.imageName, emoji: character.emoji, size: 40, packId: character.packId, imageCache: imageCache)
                        Text(character.name)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(character.slot.name)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if owned {
                // Download/delete controls for owned packs
                if isDownloading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Downloading...")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else if isCached {
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.friendGreen)
                            Text("Downloaded")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Button {
                            imageCache.deletePack(pack.id)
                        } label: {
                            Text("Delete")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        let imageNames = pack.characters.compactMap(\.imageName)
                        Task {
                            await imageCache.downloadPack(pack.id, imageNames: imageNames)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download Images")
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    guard let product, purchasingId == nil else { return }
                    purchasingId = pack.productId
                    Task {
                        let success = await storeManager.purchase(product)
                        if success {
                            characterManager.unlockPack(pack.id)
                            // Auto-download images after purchase
                            let imageNames = pack.characters.compactMap(\.imageName)
                            await imageCache.downloadPack(pack.id, imageNames: imageNames)
                        }
                        purchasingId = nil
                    }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text(product?.displayPrice ?? "$1.99")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.white))
                }
                .buttonStyle(.plain)
                .disabled(isPurchasing)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(owned ? Theme.winGold.opacity(0.4) : .white.opacity(0.15), lineWidth: 2)
                )
        )
    }

    private func syncPurchases() {
        for pack in catalogManager.packs {
            if storeManager.isPurchased(pack.productId) {
                characterManager.unlockPack(pack.id)
            }
        }
    }
}
