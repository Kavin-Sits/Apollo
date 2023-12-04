//
//  SoundEffectManager.swift
//  Apollo
//
//  Created by Nandini Bhardwaj on 12/3/23.
//

import Foundation
import SwiftUI

class SoundEffectManager: ObservableObject {
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }

    init() {
        if let storedSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool {
            self.soundEnabled = storedSoundEnabled
        } else {
            // (first launch)
            self.soundEnabled = true
            UserDefaults.standard.set(true, forKey: "soundEnabled")
        }
    }
}
