//
//  Synthesizer.swift
//  L4HPercussion
//
//  Created by Lei Mingyu on 7/4/17.
//  Copyright © 2017 l4h. All rights reserved.
//

import AVFoundation
import Foundation



// The single FM synthesizer instance.
let gFMSynthesizer: Synthesizer = Synthesizer()

class Synthesizer {
    // The maximum number of audio buffers in flight. Setting to two allows one
    // buffer to be played while the next is being written.
    var kInFlightAudioBuffers: Int = 2
    
    // The number of audio samples per buffer. A lower value reduces latency for
    // changes but requires more processing but increases the risk of being unable
    // to fill the buffers in time. A setting of 1024 represents about 23ms of
    // samples.
    
    // I set it to 4452 on purpose which is 0.8s
    let kSamplesPerBuffer: AVAudioFrameCount = 35616
    
    // The audio engine manages the sound system.
    let audioEngine: AVAudioEngine = AVAudioEngine()
    
    // The player node schedules the playback of the audio buffers.
    let playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    
    // Use standard non-interleaved PCM audio.
    let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
    
    // A circular queue of audio buffers.
    var audioBuffers: [AVAudioPCMBuffer] = [AVAudioPCMBuffer]()
    
    // The index of the next buffer to fill.
    var bufferIndex: Int = 0
    
    // The dispatch queue to render audio samples.
    let audioQueue: DispatchQueue = DispatchQueue(label: "FMSynthesizerQueue", attributes: [])
    
    // A semaphore to gate the number of buffers processed.
    let audioSemaphore: DispatchSemaphore
    
    class func sharedSynth() -> Synthesizer {
        return gFMSynthesizer
    }
    
    public init() {
        // init the semaphore
        audioSemaphore = DispatchSemaphore(value: kInFlightAudioBuffers)
        
        // Create a pool of audio buffers.
        audioBuffers = [AVAudioPCMBuffer](repeating: AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(kSamplesPerBuffer)), count: 2)
        
        // Attach and connect the player node.
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine didn't start")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(Synthesizer.audioEngineConfigurationChange(_:)), name: NSNotification.Name.AVAudioEngineConfigurationChange, object: audioEngine)
    }
    
    func play(carrierFrequency: Float32, modulatorFrequency: Float32, modulatorAmplitude: Float32, force: Int) {
        let unitVelocity = Float32(2.0 * Double.pi / audioFormat.sampleRate)
        let carrierVelocity = carrierFrequency * unitVelocity
        let modulatorVelocity = modulatorFrequency * unitVelocity
        audioQueue.async() {
            var sampleTime: Float32 = 0
            
            
            // Wait for a buffer to become available.
            let _ = self.audioSemaphore.wait(timeout: DispatchTime.distantFuture)
            
            // Fill the buffer with new samples.
            let audioBuffer = self.audioBuffers[self.bufferIndex]
            let leftChannel = audioBuffer.floatChannelData?[0]
            let rightChannel = audioBuffer.floatChannelData?[1]
            for sampleIndex in 0 ..< Int(self.kSamplesPerBuffer) {
                let amplitude = self.adsr(sampleIndex: sampleIndex)
                let sample = amplitude * sin(carrierVelocity * sampleTime + modulatorAmplitude * sin(modulatorVelocity * sampleTime)) * min(1, Float32(force * force * force) * 0.02)
                leftChannel?[sampleIndex] = sample
                rightChannel?[sampleIndex] = sample
                sampleTime += 1
            }
            audioBuffer.frameLength = self.kSamplesPerBuffer
            
            // Schedule the buffer for playback and release it for reuse after
            // playback has finished.
            self.playerNode.scheduleBuffer(audioBuffer) {
                self.audioSemaphore.signal()
                return
            }
            
            self.bufferIndex = (self.bufferIndex + 1) % self.audioBuffers.count
        }
        
        playerNode.pan = 0.8
        playerNode.play()
        
    }
    
    func adsr(sampleIndex: Int) -> Float32{
        // hack hack hack
        let release: Int = Int(Float(self.kSamplesPerBuffer) * 0.9)
        var envelope: Float = 0
        if sampleIndex < release {
            let relativeIndex = Float(release - sampleIndex)
            envelope = relativeIndex / Float(release)
        } else {
            envelope = 0.0
        }
        return envelope
    }
    
    @objc  func audioEngineConfigurationChange(_ notification: Notification) -> Void {
        NSLog("Audio engine configuration change: \(notification)")
    }
}

