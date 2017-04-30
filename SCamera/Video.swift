// Copyright (c) 2017 Philip M. Hubbard
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
// associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
// NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// http://opensource.org/licenses/MIT

import AVFoundation

// A protocol and class to simplify the use of AVFoundation code to capture video from a device's
// cameras.

// A protocol for the receiver of the video frames.

public protocol VideoDelegate {
    func captureOutput(sampleBuffer: CMSampleBuffer!)
    func droppedFrame(sampleBuffer: CMSampleBuffer!)
}

// A class for managing the video cameras.

public class Video: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public init(delegate: VideoDelegate, sessionPreset: String = AVCaptureSessionPresetMedium) {
        self.delegate = delegate
        self.sessionPreset = sessionPreset
        queue = DispatchQueue(label: "com.philiphubbard.scamera.video")
        super.init()
    }
    
    public var position: AVCaptureDevicePosition = AVCaptureDevicePosition.front {
        didSet(oldPosition) {
            if oldPosition != position {
                queue.async {
                    self.setupInput()
                    self.setupOrientation()
                }
            }
        }
    }
    
    public var orientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait {
        didSet(oldOrientation) {
            if oldOrientation != orientation {
                queue.async{
                    self.setupOrientation()
                }
            }
        }
    }
    
    public func start() {
        queue.async {
            if self.captureSession == nil {
                self.setupSession()
                self.setupInput()
                self.setupOrientation()
            }
            if let session = self.captureSession {
                session.startRunning()
            }
        }
    }
  
    public func stop() {
        queue.async {
            if let session = self.captureSession {
                if session.isRunning {
                    session.stopRunning()
                }
            }
        }
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        delegate.captureOutput(sampleBuffer: sampleBuffer)
    }

    public func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        delegate.droppedFrame(sampleBuffer: sampleBuffer)
    }
    
    public class func cgImage(fromSampleBuffer sampleBuffer: CMSampleBuffer!) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("CMSampleBufferGetImageBuffer() failed")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bitsPerComponent = 8
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("CGContext initializer failed")
            return nil
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return context.makeImage()
    }

    private func setupSession() {
        let session = AVCaptureSession()
        session.sessionPreset = sessionPreset
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]
        guard session.canAddOutput(output) else {
            print("SCamera.Video.setupSession() failed: cannot add output")
            return
        }
        
        session.beginConfiguration()
        session.addOutput(output)
        session.commitConfiguration()
        
        captureSession = session
    }
    
    private func setupInput() {
        guard let session = captureSession else {
            return
        }
        
        guard let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: position) else {
            print("SCamera.Video.setupInput() failed: no AVCaptureDevice")
            return
        }
        
        let input = try? AVCaptureDeviceInput(device: device)
        guard input != nil else {
            print("SCamera.Video.setupInput() failed: cannot create input")
            return
        }
        
        if let oldInput = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(oldInput)
        }
       
        guard session.canAddInput(input) else {
            print("SCamera.Video.setupInput() failed: cannot add input")
            return
        }
        
        session.beginConfiguration()
        session.addInput(input)
        session.commitConfiguration()
    }
    
    private func setupOrientation() {
        guard let session = captureSession else {
            return
        }

        guard let output = session.outputs.first as? AVCaptureVideoDataOutput else {
            return
        }
        
        let videoConnection = output.connection(withMediaType: AVMediaTypeVideo)
        guard let connection = videoConnection else {
            print("SCamera.Video.setupSession() failed: no AVMediaTypeVideo connection")
            return
        }
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
    }
    
    private let delegate: VideoDelegate
    private let sessionPreset: String
    private let queue: DispatchQueue
    private var captureSession: AVCaptureSession?
}
