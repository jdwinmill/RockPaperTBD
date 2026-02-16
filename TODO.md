# RockPaperTBD — App Store Launch Checklist

## Critical Path

### 1. Choose a final app name
> **Status:** Not started
> **Blocks:** Logo (#2), Bundle/IAP IDs (#4), App Store listing (#5)

Everything cascades from this decision — bundle ID, IAP product IDs, marketing, icon design.

**Possible names:**

| Vibe | Name | Why |
|------|------|-----|
| Action | **Throwdown** | Evokes the competitive "throw" of RPS |
| Action | **Flinch** | Snap-decision energy, ties into tap battles |
| Action | **ClashPalm** | Palm-based combat, playful |
| Action | **ThrowHands** | Slang for fighting, fits the gesture theme |
| Clever | **Roshambo** | Classic alternate name for RPS, recognizable |
| Clever | **Best of Three** | Describes the core loop |
| Clever | **Paper Trail** | Fun wordplay |
| Character | **Skin Deep** | Cosmetics + competition |
| Character | **Suited Up** | Loadout/character dressing |
| Brandable | **Toss** | Simple, gesture-based |
| Brandable | **Huck** | To throw something |
| Brandable | **Volley** | Back-and-forth exchange |
| Brandable | **Salvo** | A burst/round of action |

---

### 2. Design and create app logo/icon
> **Status:** Not started
> **Blocked by:** Name (#1)

- Create final icon reflecting chosen name and game identity
- Dark-mode aesthetic, competitive RPS with character cosmetics
- Full asset set for all required iOS sizes
- Currently placeholder in Assets.xcassets

---

### 3. Finalize official character loadouts for IAP
> **Status:** Not started
> **Blocks:** App Store listing (#5)

Current packs in code — confirm, revise, or replace:

| Pack | Rock Slot | Paper Slot | Scissors Slot |
|------|-----------|------------|---------------|
| Samurai | ⚔️ Katana | 🛡️ Shield | 🏹 Arrow |
| Space | 🌙 Asteroid | 🛸 UFO | ⚡ Laser |
| Animals | 🐻 Bear | 🦅 Eagle | 🐍 Snake |

Decisions needed:
- Are these the right 3 themes?
- Final character names, emojis/art, and flavor text
- Pricing per pack
- Register IAP products in App Store Connect once name is locked

---

## Code Changes

### 4. Update bundle ID and IAP product IDs to match new name
> **Status:** Not started
> **Blocked by:** Name (#1)

Update in code and Xcode project:
- Bundle identifier (currently `Outpost-AI-Labs.RockPaperTBD`)
- StoreKit product IDs (currently `com.outpostai.rockpapertbd.pack.{samurai,space,animals}`)
- All references in CharacterCatalog, StoreManager, etc.
- Xcode project settings (PRODUCT_NAME, target name)
- Hardcoded title text in UI (ContentView shows "Rock Paper" + "[TBD]")

---

## App Store Admin

### 5. Create App Store Connect listing
> **Status:** Not started
> **Blocked by:** Name (#1), Logo (#2), Loadouts (#3), IDs (#4), Privacy Policy (#6)

- App description and subtitle
- Keywords and category (Games > Casual or Games > Board)
- Age rating questionnaire
- Screenshots for required device sizes
- Privacy policy URL
- Register IAP products with final product IDs and pricing
- Set up sandbox testing

---

### 6. Create and host a privacy policy
> **Status:** Not started
> **Can start now**

Apple requires a privacy policy URL. The app uses Firebase RTDB, so cover:
- What data is collected (device UUID, display name, game data)
- How it's used (matchmaking, friends, gameplay)
- No personal info sold
- Host on GitHub Pages or similar

---

## Testing

### Testing Toggle: IAP Paywall Bypass
> **Status:** ACTIVE — all packs unlocked for testing

A single flag in `CharacterManager.swift` bypasses the paywall:

```swift
static let unlockAllPacks = true  // line 8
```

**To re-enable the paywall for release:** set `unlockAllPacks = false`. No other changes needed — all StoreKit code is intact.

---

### 7. Real device testing
> **Status:** Not started
> **Blocked by:** IDs updated (#4)

- StoreKit sandbox purchases (buy, restore, verify unlock)
- Online multiplayer (create room, join room, play full match)
- Tap battle over network (tap count sync)
- Friends system (add friend, send invite, accept)
- Character loadout persistence across app restarts
- All game modes (VS Computer, pass-and-play, online)
- Edge cases (backgrounding mid-game, network loss)

---

## Parallel Work

These can be done right now without waiting on the name:
- **#3** — Finalize character loadouts
- **#6** — Write and host privacy policy
