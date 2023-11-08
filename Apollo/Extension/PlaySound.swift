//
//  PlaySound.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/7/23.
//

import AVFoundation

var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        }
        catch {
            print("ERROR: could not play the sound file!")
        }
    }
}
