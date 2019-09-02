//
//  ViewController.swift
//  AVCaptureAudioDataOutputSampleBufferTesting
//
//  Created by Daisuke T on 2019/09/02.
//  Copyright © 2019 DaisukeT. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
  
  @IBOutlet weak var button: UIButton!
  
  private let session = AVCaptureSession()
  private let microphone = AVCaptureDevice.default(for: .audio)
  private let queue = DispatchQueue(label: "com.daisuke.AVCaptureAudioDataOutputSampleBufferTesting")

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let output = AVCaptureAudioDataOutput()
    output.setSampleBufferDelegate(self, queue: queue)
    session.beginConfiguration()
    session.automaticallyConfiguresApplicationAudioSession = false
    session.addOutput(output)
    session.commitConfiguration()
    
    button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
  }
  
}


// MARK: UIControl
extension ViewController {
  
  @objc func buttonAction(_ sender: AnyObject) {
    if session.isRunning {
      button.setTitle("START", for: .normal)
      stop()
    } else {
      button.setTitle("STOP", for: .normal)
      start()
    }
  }
  
}


// MARK: Operation
extension ViewController {

  func start() {
    AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
      guard granted else {
        return
      }
      
      guard let microphone = self.microphone else {
        return
      }
      
      guard let input = try? AVCaptureDeviceInput(device: microphone) else {
        return
      }
      
      if self.session.canAddInput(input) {
        self.session.beginConfiguration()
        self.session.addInput(input)
        self.session.commitConfiguration()
      }
      
      
      try! AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                       mode: .measurement,
                                                       options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
      try! AVAudioSession.sharedInstance().setActive(true)
      
      self.session.startRunning()
   })
  }
  
  func stop() {
    self.session.stopRunning()
    
    try! AVAudioSession.sharedInstance().setActive(false)
  }
  
}


// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate
extension ViewController: AVCaptureAudioDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection) {
    
    var blockBuffer: CMBlockBuffer?
    let audioBufferList = AudioBufferList.allocate(maximumBuffers: 1)
    defer {
      free(audioBufferList.unsafeMutablePointer)
    }
    
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
      sampleBuffer,
      bufferListSizeNeededOut: nil,
      bufferListOut: audioBufferList.unsafeMutablePointer,
      bufferListSize: MemoryLayout<AudioBufferList>.size,
      blockBufferAllocator: nil,
      blockBufferMemoryAllocator: nil,
      flags: UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
      blockBufferOut: &blockBuffer
    )
    
    guard blockBuffer != nil, let audioBuffer = audioBufferList.first else { return }
    let audioSampleBuffer = UnsafeBufferPointer<Int16>(audioBuffer)
    guard audioSampleBuffer.count > 0 else { return }
    
    print("captureOutput dataSize=\(audioBuffer.mDataByteSize)")
    for _ in audioSampleBuffer {
      // ENAMRATE SAMPLE DATA...
    }
    
  }
}

