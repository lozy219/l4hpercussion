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
                    tempMaxAcceleration = 0
                    accelerationFlag = false
                    self.playingFlag = true
                    
                    Synthesizer.sharedSynth().play(carrierFrequency: Float32((deviceMotion.gravity.z + 1) / 2 * 440 + 440.0), modulatorFrequency: 0.0, modulatorAmplitude: 0.0)
                    
                    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false, block: {
                        t in
                        
                        self.playingFlag = false
                    })
                }
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
