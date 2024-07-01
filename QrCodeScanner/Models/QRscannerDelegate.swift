import Foundation
import AVKit
import SwiftUI


class QRscannerDelegate: NSObject,ObservableObject,AVCaptureMetadataOutputObjectsDelegate {
    
    @Published var scannedCode: String?
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        if let metaObject = metadataObjects.first{
            guard let reliableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let code = reliableObject.stringValue else { return }
            print(code)
            scannedCode = code
            
                    
        }
    }
}
