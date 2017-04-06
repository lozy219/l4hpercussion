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
    var tempFlag = true
    
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
            if tempFlag {
                Synthesizer.sharedSynth().play(carrierFrequency: Float32((deviceMotion.gravity.z + 1) / 2 * 440 + 440.0), modulatorFrequency: 0.0, modulatorAmplitude: 0.0)
                tempFlag = false
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
