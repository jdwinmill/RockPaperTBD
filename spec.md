# Rock Paper [TBD] - Phase 1 Specification

**Version:** 1.1
**Last Updated:** February 12, 2026
**Status:** Phase 1 Complete

---

## Overview

### Goal
Build a playable MVP that validates the core gameplay loop with your kids. Success = they ask to play again.

### Phase 1 Scope
- **Single device, pass-and-play** (simplest multiplayer) - DONE
- **4 gestures** (Rock, Paper, Scissors, Chicken) - DONE
- **Endless mode** (play until players choose to stop) - DONE
- **Visual polish** (animations, colors, sound) - DONE

### Explicitly NOT in Phase 1
- Online multiplayer (GameKit)
- Leveling/progression system
- Multiple gesture options/loadouts
- Skins/cosmetics
- Backend/server
- Analytics

---

## Core Game Flow

### State Machine
```
START
  |
PLAYER_1_SELECT -> (Player 1 chooses gesture)
  |
TRANSITION -> ("Pass to Player 2" screen - hides P1 choice)
  |
PLAYER_2_SELECT -> (Player 2 chooses gesture)
  |
COUNTDOWN -> ("3... 2... 1... THROW!")
  |
REVEAL -> (Show both gestures, winner, score update)
  |
[Next Round -> PLAYER_1_SELECT]
```

### Round-by-Round Flow

#### 1. Start Screen - DONE
- Title with animated gradient text
- "TAP TO PLAY" prompt
- Dark purple gradient background

#### 2. Player 1 Selection Screen - DONE
**UI Elements:**
- Large title: "Player 1's Turn"
- 4 gesture buttons in 2x2 grid (Rock, Paper, Scissors, Chicken)
- Current score display (P1: X - P2: Y)
- Current round number

**Visual Design:**
- Blue gradient background (#3B82F6 -> #8B5CF6)
- Large emoji-based gesture buttons
- Tap haptic + sound on selection

#### 3. Transition Screen - DONE
**UI Elements:**
- "Pass to Player 2" text
- "I'M READY" button (prevents accidental reveals)

**Visual Design:**
- Purple gradient background
- Simple, clear instructions

#### 4. Player 2 Selection Screen - DONE
- Same component as Player 1, parameterized
- Red/Orange gradient (#F59E0B -> #EF4444)
- Immediately triggers countdown on selection

#### 5. Countdown Screen (CENTERPIECE MOMENT) - DONE
**UI Elements:**
- Massive countdown number: "3" -> "2" -> "1" -> "THROW!"
- Pulsing concentric circles behind the number
- Escalating beep on each number
- Shake/scale effect on each beat
- Tension-building background gradient shift

**Sound Design:**
- Beat 1 (3): 400Hz sine, 0.1s
- Beat 2 (2): 500Hz sine, 0.1s
- Beat 3 (1): 600Hz sine, 0.1s
- THROW!: 800Hz sine, 0.3s

**Animation Sequence (per beat):**
1. Number appears at scale 0.8
2. Scale to 1.2 over 0.1s (with shake rotation)
3. Scale back to 1.0 over 0.2s
4. Hold for 0.7s
5. Next number

#### 6. Reveal Screen - DONE
**UI Elements:**
- Both gestures displayed with emojis
- Winner declaration: "Player X Wins!" or "It's a Tie!"
- Flavor text (e.g. "Rock crushes Scissors!")
- Updated score display
- "Next Round" and "New Game" buttons
- Confetti overlay for wins (Canvas + TimelineView)
- Chicken squeal sound when Chicken loses

---

## Game Rules

### Win Conditions
- **Rock** beats **Scissors** (crushes) and **Chicken** (scares)
- **Paper** beats **Rock** (covers)
- **Scissors** beats **Paper** (cuts) and **Chicken** (chases)
- **Chicken** only beats **Paper** (pecks)
- Same gesture = **Tie** (no points, round replays)

### Scoring System
- Win = +1 point
- Loss = 0 points
- Tie = 0 points (round number does not increment)

### Game Length
- **Endless mode** - play until players choose to stop
- "Best of X" mode deferred to future phase

---

## Visual Polish - DONE

### Animations
1. **Countdown sequence** - pulsing circles, number scale + shake, gradient shift
2. **Gesture reveal** - scale + opacity transitions
3. **Winner celebration** - confetti via Canvas + TimelineView
4. **Button interactions** - scale on tap
5. **Screen transitions** - spring animations (.spring(response: 0.4, dampingFraction: 0.85))

### Color Scheme (Theme.swift)
- **Player 1:** Blue gradient (#3B82F6 -> #8B5CF6)
- **Player 2:** Red/Orange gradient (#F59E0B -> #EF4444)
- **Countdown:** Orange -> Red -> Purple progression
- **Winner:** Gold (#FCD34D), player-colored backgrounds
- **Tie:** Purple (#7C3AED -> #6D28D9)
- **Start:** Dark indigo (#1E1B4B -> #312E81 -> #4C1D95)

### Sound Effects - DONE
- Button tap (1000Hz sine, 0.05s)
- Countdown beep (escalating 400 -> 500 -> 600 -> 800Hz)
- Win sound (880 -> 1100 -> 1320Hz arpeggio)
- Tie sound (440 -> 380Hz descending)
- Chicken squeal (1200 -> 600Hz warble with square wave mix)
- All synthesized via single persistent AVAudioEngine with pre-generated PCM buffers

### Haptic Feedback - DONE
- Light impact on button tap
- Medium impact on countdown 3, 2
- Heavy impact on countdown 1 and THROW
- Notification success on win
- Notification error on chicken squeal
- Notification warning on tie

---

## Technical Architecture (Pure SwiftUI) - IMPLEMENTED

### Project Structure
```
RockPaperTBD/
  RockPaperTBDApp.swift    # App entry, dark mode, status bar hidden
  AppDelegate.swift        # Portrait lock
  ContentView.swift        # Main router with animated transitions
  Gesture.swift            # Move enum, RoundResult, GameState
  GameViewModel.swift      # @Observable state machine, scoring, game logic
  PlayerSelectView.swift   # Gesture selection (parameterized for P1/P2)
  CountdownView.swift      # 3-2-1-THROW animation + Color(hex:) extension
  RevealView.swift         # Results display + ConfettiOverlay (Canvas)
  TransitionView.swift     # Pass device screen + StartView (title screen)
  SoundManager.swift       # AVAudioEngine tone generation + UIKit haptics
  Theme.swift              # Cached Color(hex:) static constants
  Assets.xcassets/         # App icons (light/dark/tinted)
```

### State Management
```swift
enum GameState: Equatable {
    case start
    case player1Select
    case transition
    case player2Select
    case countdown
    case reveal
}
```

### Key Classes
**GameViewModel (@Observable):**
- Drives state machine transitions
- Stores player choices, scores, round count
- Determines winner with flavor text
- Owns SoundManager instance

**ContentView:**
- ZStack-based router switching on GameState
- Spring animations between states
- Passes closures down to child views

**SoundManager (@Observable):**
- Single persistent AVAudioEngine + AVAudioPlayerNode
- Pre-generated PCM buffers at init
- Haptic feedback via UIKit generators (light/medium/heavy impact + notification)

---

## Development Checklist

### Setup - DONE
- [x] Create SwiftUI iOS project (pure SwiftUI, no SpriteKit)
- [x] Set up project structure with fileSystemSynchronizedGroups
- [x] Configure Theme.swift with cached Color constants
- [x] Portrait lock via AppDelegate
- [x] Dark mode + status bar hidden

### Core Gameplay - DONE
- [x] Implement state machine (GameState enum with .start state)
- [x] Build start screen with title
- [x] Build Player 1 selection screen (2x2 grid, 4 gestures)
- [x] Build countdown timer (3-2-1-THROW) with pulsing circles, sound, gradient
- [x] Build transition screen ("Pass to Player 2")
- [x] Build Player 2 selection screen (same component, different colors)
- [x] Implement win/loss logic (4-gesture matrix with Chicken)
- [x] Display reveal screen with flavor text
- [x] Score tracking (endless mode, ties don't increment round)
- [x] "Next Round" flow

### Visual Polish - DONE
- [x] Gesture button animations (scale on tap)
- [x] Countdown pulse effect (concentric circles)
- [x] Reveal animation (scale + opacity transitions)
- [x] Winner celebration (confetti via Canvas + TimelineView)
- [x] Color gradients for each state (Theme.swift)
- [x] Smooth transitions between screens (spring animations)

### Audio & Haptics - DONE
- [x] Sound effects (AVAudioEngine with synthesized tones)
- [x] Haptic feedback (UIImpactFeedbackGenerator + UINotificationFeedbackGenerator)
- [x] Chicken squeal on Chicken loss (synthesized warble)
- [x] Win arpeggio, tie descend, tap click

### Testing
- [ ] Play 5 rounds without bugs
- [ ] Test with kids (primary validation)
- [ ] Fix any confusion points
- [ ] Add any "missing juice" they mention

---

## Resolved Decisions

| Question | Decision |
|----------|----------|
| Fourth gesture? | Removed in Phase 2. Classic 3 (Rock, Paper, Scissors) is the foundation. |
| Game length? | Best of X (3, 5, 7) or Endless |
| Sound? | Implemented in Phase 1 (AVAudioEngine synthesis) |
| Transition screen? | Yes, included for device hand-off |
| Device orientation? | Portrait only |
| Framework? | Pure SwiftUI (not SpriteKit) |

---

## Future Phases

### Phase 2 — Tighten the Core
- [x] Reduce pass-and-play friction (faster transitions, tap-to-continue)
- [x] Drop to 3 gestures (classic Rock, Paper, Scissors)
- [x] Best of X mode (3, 5, 7, or Endless)
- [ ] Player name customization

### Phase 3 — Character Loadouts
- 3 mechanical **slots** (the RPS cycle), characters are cosmetic skins per slot
- Each player independently picks their loadout before a match
- Characters have unique emoji/image, name, flavor text
- Balance is guaranteed — game logic only sees slots, not characters

### Phase 4 — Tap Battles & Powers
- Slot matchup determines **advantage**, not instant win
- After reveal, a tapping minigame decides the round
- Advantaged player gets a head start / multiplier
- Disadvantaged player can still win with faster tapping
- **Powers** are the character differentiator (e.g., bigger head start, tap multiplier, slow opponent)

### Phase 5+ (Ideas)
- Online multiplayer (GameKit)
- Unlockable characters / progression
- Match history
- Analytics
