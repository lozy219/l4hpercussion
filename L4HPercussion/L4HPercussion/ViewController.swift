//
//  ViewController.swift
//  L4HPercussion
//
//  Created by Lei Mingyu on 7/4/17.
//  Copyright © 2017 l4h. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    let motionManager = CMMotionManager()
    var tempMaxAcceleration = 0
    var accelerationFlag = false
    var playingFlag = false
    let majorInterval = [0, 2, 4, 7, 9]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        motionManager.startDeviceMotionUpdates()
        
        let _ = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
    }
    
    func update() {
        if let deviceMotion = motionManager.deviceMotion {
            if !self.playingFlag {
                let currentAcceleration = Int(deviceMotion.userAcceleration.x)
                if currentAcceleration > 0 {
                    accelerationFlag = true
                    tempMaxAcceleration = max(tempMaxAcceleration, currentAcceleration)
                } else if accelerationFlag {
                    // hitting end
                    print(tempMaxAcceleration)
                    accelerationFlag = false
                    self.playingFlag = true
                    
                    let baseMidiNote = 96
                    
                    let midiNote = majorInterval[Int(abs(deviceMotion.attitude.quaternion.x) * 5)] + baseMidiNote
                    let frequency = frequencyOf(midiNote: midiNote)
                    
                    Synthesizer.sharedSynth().play(carrierFrequency: frequency, modulatorFrequency: 0.0, modulatorAmplitude: 0.0, force: tempMaxAcceleration)
                    tempMaxAcceleration = 0
                    
                    Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: {
                        t in
                        
                        self.playingFlag = false
                    })
                }
            }
        }
    }
    
    private func frequencyOf(midiNote: Int) -> Float32 {
        let a: Float32 = 440.0
        return a / 32.0 * Float32(pow(2.0, (Double(midiNote) - 9.0) / 12.0))
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
