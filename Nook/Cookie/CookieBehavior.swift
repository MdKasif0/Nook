import SceneKit
import Foundation

/// Defines an executable behavior for Cookie in the 3D room diorama.
///
/// Enables a clean state-driven architecture where new behaviors can be added
/// without modifying existing room views or diorama builders.
@MainActor
protocol CookieBehavior {
    var name: String { get }
    var targetMood: CookieMood { get }
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController)
}

// MARK: - Standard Concrete Behaviors

/// 1. Idle Observe: Sits calmly, looks softly around the room.
struct IdleObserveBehavior: CookieBehavior {
    let name = "Idle Observe"
    let targetMood: CookieMood = .idle
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.applyPosture(for: .idle, animated: true)
    }
}

/// 2. Stretch: Performs a natural downward cat stretch.
struct StretchBehavior: CookieBehavior {
    let name = "Stretch"
    let targetMood: CookieMood = .idle
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.performStretch {
            character.applyPosture(for: .idle, animated: true)
        }
    }
}

/// 3. Clean Paw: Raises paw to muzzle and licks delicately.
struct CleanPawBehavior: CookieBehavior {
    let name = "Clean Paw"
    let targetMood: CookieMood = .idle
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.performCleanPaw {
            character.applyPosture(for: .idle, animated: true)
        }
    }
}

/// 4. Inspect New Item: Turns head toward the new item on the desk.
struct InspectItemBehavior: CookieBehavior {
    let name = "Inspect Item"
    let targetMood: CookieMood = .curious
    let targetWorldPos: SCNVector3
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.applyPosture(for: .curious, animated: true)
        character.lookToward(worldPosition: targetWorldPos)
    }
}

/// 5. Investigate Desk: Walks from rug closer to the desk when multiple thoughts appear.
struct InvestigateDeskBehavior: CookieBehavior {
    let name = "Investigate Desk"
    let targetMood: CookieMood = .curious
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.applyPosture(for: .curious, animated: true)
        character.walkTo(target: CookieCharacterNode.nearDeskPosition) {
            character.applyPosture(for: .curious, animated: true)
        }
    }
}

/// 6. Return To Rug: Walks back to the cozy circular rug.
struct ReturnToRugBehavior: CookieBehavior {
    let name = "Return To Rug"
    let targetMood: CookieMood = .idle
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.walkTo(target: CookieCharacterNode.homeRugPosition) {
            character.applyPosture(for: .idle, animated: true)
        }
    }
}

/// 7. Happy Purr: Contented reaction when an item is completed or petted.
struct HappyPurrBehavior: CookieBehavior {
    let name = "Happy Purr"
    let targetMood: CookieMood = .happy
    let speechBubbleText: String?
    
    init(bubbleText: String? = "purr...") {
        self.speechBubbleText = bubbleText
    }
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.applyPosture(for: .happy, animated: true)
        if let text = speechBubbleText {
            character.showSpeechBubble(text: text, duration: 2.8)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if character.currentMood == .happy {
                character.applyPosture(for: .idle, animated: true)
            }
        }
    }
}

/// 8. Ponder: Looks thoughtfully toward the window.
struct PonderBehavior: CookieBehavior {
    let name = "Ponder"
    let targetMood: CookieMood = .thinking
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.applyPosture(for: .thinking, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if character.currentMood == .thinking {
                character.applyPosture(for: .idle, animated: true)
            }
        }
    }
}

/// 9. Sleep: Curls up into a cozy sleeping loaf on the rug.
struct SleepBehavior: CookieBehavior {
    let name = "Sleep"
    let targetMood: CookieMood = .resting
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        // If not already on rug, walk back first
        let distToRug = hypot(
            character.position.x - CookieCharacterNode.homeRugPosition.x,
            character.position.z - CookieCharacterNode.homeRugPosition.z
        )
        if distToRug > 0.15 {
            character.walkTo(target: CookieCharacterNode.homeRugPosition) {
                character.performCurlUp()
            }
        } else {
            character.performCurlUp()
        }
    }
}

/// 10. Wake Up: Stretches, blinks slowly, lifts head.
struct WakeUpBehavior: CookieBehavior {
    let name = "Wake Up"
    let targetMood: CookieMood = .idle
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.performWakeUp {
            character.applyPosture(for: .idle, animated: true)
        }
    }
}

/// 11. Delete Reaction: Quick perked ears and curious head tilt.
struct DeleteReactionBehavior: CookieBehavior {
    let name = "Delete Reaction"
    let targetMood: CookieMood = .curious
    
    func execute(on character: CookieCharacterNode, controller: CookieBehaviorController) {
        character.applyPosture(for: .curious, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if character.currentMood == .curious {
                character.applyPosture(for: .idle, animated: true)
            }
        }
    }
}
