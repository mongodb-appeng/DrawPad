import UIKit
import AVFoundation

public class PhotoCaptureOverlayView: UIView, AVCapturePhotoCaptureDelegate {
  let drawingLayer = CALayer()
  var originalDrawing: UIImage?
  let photoOutput = AVCapturePhotoOutput()
  let captureSession = AVCaptureSession()
  public typealias CompositePhotoResult = (UIImage?) -> Void
  var waitingCapture: CompositePhotoResult?
  
  public func startCameraPreview(with overlay: UIImage?) {
    if captureSession.isRunning {
      captureSession.stopRunning()
      self.layer.sublayers?.removeAll()
    }
    captureSession.sessionPreset = .medium
    guard let device = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: device),
      captureSession.canAddOutput(photoOutput),
      captureSession.canAddInput(input)
      else {
        print("Failed to create camera session")
        // TODO: figure out what to do here
        return
    }
    
    captureSession.addInput(input)
    captureSession.addOutput(photoOutput)
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.frame = bounds
    previewLayer.videoGravity = .resizeAspect
    previewLayer.connection?.videoOrientation = .landscapeRight
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.captureSession.startRunning()
    }
    
    drawingLayer.contents = overlay?.cgImage
    originalDrawing = overlay
    let squareSide = min(bounds.width, bounds.height)
    let origin = CGPoint(x: bounds.width / 2 - squareSide / 2 , y: bounds.height / 2 - squareSide / 2)
    drawingLayer.frame = CGRect(origin: origin, size: CGSize(width: squareSide, height: squareSide))
    
    layer.addSublayer(previewLayer)
    layer.addSublayer(drawingLayer)
  }
  
  func getCompositeImage(_ callback: @escaping CompositePhotoResult) {
    waitingCapture = callback
    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    photoOutput.capturePhoto(with: settings, delegate: self)
  }
  
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let imageData = photo.fileDataRepresentation()
      else { return }
    
    let image = UIImage(cgImage: (UIImage(data: imageData)?.cgImage)!, scale: 1.0, orientation: .up)
    let size = CGSize(width: bounds.width * 2, height: bounds.height * 2)
    let drawRect = CGRect(origin: .zero, size: size)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    image.draw(in: drawRect)
    let drawingSize = CGSize(width: drawingLayer.frame.width * 2, height: drawingLayer.frame.height * 2)
    let origin = CGPoint(x: size.width / 2 - drawingSize.width / 2 , y: size.height / 2 - drawingSize.height / 2)
    let drawingRect = CGRect(origin: origin, size: drawingSize)
    originalDrawing?.draw(in: drawingRect)
    
    let compositImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    waitingCapture?(compositImage)
  }
}
