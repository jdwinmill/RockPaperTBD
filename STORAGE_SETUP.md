# Storage Setup — Remote Character Packs

The app code is ready. These manual steps need to be completed before remote character packs will work. Until then, the app runs fine with emoji-only defaults.

---

## 1. Update the Firebase Storage bucket name

In `PackImageCache.swift`, replace the placeholder with your actual bucket:

```swift
enum StorageBucketConfig {
    static let bucket = "YOUR_PROJECT.firebasestorage.app"  // ← change this
}
```

Find your bucket name in `GoogleService-Info.plist` → `STORAGE_BUCKET`.

---

## 2. Upload pack images to Firebase Storage

Export the 12 character images as **512x512 PNG** files (SVGs won't work — `UIImage(contentsOfFile:)` doesn't support SVG).

Upload them to Firebase Storage with this folder structure:

```
character-packs/
  samurai/
    samurai_katana.png
    samurai_shield.png
    samurai_arrow.png
  space/
    space_asteroid.png
    space_ufo.png
    space_laser.png
  animals/
    animals_bear.png
    animals_eagle.png
    animals_snake.png
  mythical/
    mythical_kraken.png
    mythical_phoenix.png
    mythical_basilisk.png
```

### Storage security rules

Allow public read access for the `character-packs/` path:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /character-packs/{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

---

## 3. Populate the RTDB catalog

Add pack definitions to `/catalog/` in Firebase Realtime Database. Each pack needs: `name`, `description`, `productId`, `active`, and a `characters` object keyed by slot (`rock`, `paper`, `scissors`).

### Full JSON to import

Go to Firebase Console → Realtime Database → Import JSON (or set manually):

```json
{
  "catalog": {
    "samurai": {
      "name": "Samurai",
      "description": "Ancient warriors of honor",
      "productId": "com.outpostai.rockpapertbd.pack.samurai",
      "active": true,
      "characters": {
        "rock": {
          "id": "samurai.rock",
          "name": "Katana",
          "emoji": "⚔️",
          "flavorText": "Slices through the competition",
          "imageName": "samurai_katana"
        },
        "paper": {
          "id": "samurai.paper",
          "name": "Shield",
          "emoji": "🛡️",
          "flavorText": "An impenetrable defense",
          "imageName": "samurai_shield"
        },
        "scissors": {
          "id": "samurai.scissors",
          "name": "Arrow",
          "emoji": "🏹",
          "flavorText": "Strikes from afar",
          "imageName": "samurai_arrow"
        }
      }
    },
    "space": {
      "name": "Space",
      "description": "Intergalactic combat awaits",
      "productId": "com.outpostai.rockpapertbd.pack.space",
      "active": true,
      "characters": {
        "rock": {
          "id": "space.rock",
          "name": "Asteroid",
          "emoji": "🌑",
          "flavorText": "Hurtling through the cosmos",
          "imageName": "space_asteroid"
        },
        "paper": {
          "id": "space.paper",
          "name": "UFO",
          "emoji": "🛸",
          "flavorText": "Take me to your leader",
          "imageName": "space_ufo"
        },
        "scissors": {
          "id": "space.scissors",
          "name": "Laser",
          "emoji": "⚡",
          "flavorText": "Pew pew pew!",
          "imageName": "space_laser"
        }
      }
    },
    "animals": {
      "name": "Animals",
      "description": "Nature's fiercest fighters",
      "productId": "com.outpostai.rockpapertbd.pack.animals",
      "active": true,
      "characters": {
        "rock": {
          "id": "animals.rock",
          "name": "Bear",
          "emoji": "🐻",
          "flavorText": "Raw unstoppable power",
          "imageName": "animals_bear"
        },
        "paper": {
          "id": "animals.paper",
          "name": "Eagle",
          "emoji": "🦅",
          "flavorText": "Soars above them all",
          "imageName": "animals_eagle"
        },
        "scissors": {
          "id": "animals.scissors",
          "name": "Snake",
          "emoji": "🐍",
          "flavorText": "Quick and venomous",
          "imageName": "animals_snake"
        }
      }
    },
    "mythical": {
      "name": "Mythical",
      "description": "Legendary creatures of myth",
      "productId": "com.outpostai.rockpapertbd.pack.mythical",
      "active": true,
      "characters": {
        "rock": {
          "id": "mythical.rock",
          "name": "Kraken",
          "emoji": "🐙",
          "flavorText": "Dragging ships to the deep",
          "imageName": "mythical_kraken"
        },
        "paper": {
          "id": "mythical.paper",
          "name": "Phoenix",
          "emoji": "🔥",
          "flavorText": "Reborn from the ashes",
          "imageName": "mythical_phoenix"
        },
        "scissors": {
          "id": "mythical.scissors",
          "name": "Basilisk",
          "emoji": "🐍",
          "flavorText": "One glance is all it takes",
          "imageName": "mythical_basilisk"
        }
      }
    }
  }
}
```

### RTDB security rules

Add public read access for `/catalog/`:

```json
{
  "rules": {
    "catalog": {
      ".read": true,
      ".write": false
    }
  }
}
```

(Merge this into your existing rules — don't replace them.)

---

## 4. Store rotation

To rotate a pack out of the store, set `active: false` in the Firebase Console:

```
/catalog/samurai/active → false
```

- Non-owners won't see the pack in the store
- Owners still see it and can download/use their images
- Set `active: true` to bring it back

---

## How it works once set up

1. App launches → `CatalogManager` observes `/catalog/` → packs load from RTDB
2. Store shows active packs (+ any the user already owns)
3. User purchases a pack via StoreKit → images auto-download from Firebase Storage
4. Images cached to `~/Library/Caches/character-packs/{packId}/`
5. `CharacterDisplayView` shows cached image, or emoji if not downloaded yet
6. User can delete cached images from the store and re-download later

If RTDB catalog isn't populated yet or the device is offline, only the 3 default emoji characters appear — the app works fine without any remote data.
