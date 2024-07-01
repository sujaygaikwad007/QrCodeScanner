import SwiftUI
import AVKit

struct ScannerView: View {
    
    ///Qr code scanner properties
    @State private var isScanning = false
    @State private var session : AVCaptureSession = .init()
    @State private var qrOutputType : AVCaptureMetadataOutput = .init()
    
    @State private var permission: Permission = .idle
    
    //Error properties
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.openURL) private var openURL
    
    @StateObject private var qrDelegate = QRscannerDelegate()
    
    @State private var scannedCode = ""

    
    var body: some View {
        
        if #available(iOS 15.0, *) {
            VStack(spacing:8){
                Button {
                    
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(Color.blue)
                }
                .frame(maxWidth:.infinity,alignment: .leading)
                
                Text("Placce the QR code inside the area")
                    .font(.title3)
                    .foregroundColor(.black.opacity(0.8))
                
                Text("Scanning will start autimatically")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                Spacer(minLength: 0)
                
                ///Scanner
                GeometryReader{
                    let size = $0.size
                    
                    if #available(iOS 15.0, *) {
                        ZStack{
                            
                            CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
                                .scaleEffect(0.97)
                            
                            ForEach(0...4,id:\.self){ index in
                                
                                let rotation = Double(index) * 90
                                
                                RoundedRectangle(cornerRadius: 2, style: .circular)
                                    .trim(from: 0.61, to: 0.64)
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                                    .rotationEffect(.init(degrees: rotation))
                                
                            }
                            
                        }
                        ///Square shape
                        .frame(width: size.width, height: size.width)
                        ///scanner animation
                        .overlay(alignment: .top, content: {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height:2.5)
                                .shadow(color: Color.black.opacity(0.8), radius: 8, x: 0, y: isScanning ? 15: -15)
                                .offset(y:isScanning ? size.width : 0)
                            
                            
                        })
                        
                        
                        /// to make scanner center
                        .frame(maxWidth:.infinity,maxHeight:.infinity)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                .padding(.horizontal,45)
                
                
                Spacer(minLength: 15)
                
                Button {
                    
                    if !session.isRunning && permission == .approved{
                        reactiveCamera()
                        activateScannerAnimation()
                    }
                    
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    
                }
                Spacer(minLength: 45)
                
                
            }
            .padding(15)
            .onAppear(perform: cameraPermission)
            .alert(errorMessage, isPresented: $showError) {
                
                if permission  == .denied{
                    Button("Setting"){
                        let setting = UIApplication.openSettingsURLString
                        if let settingUrl = URL(string:setting){
                            openURL(settingUrl)
                        }
                        
                        
                    }
                    
                    Button("Cancel",role:.cancel){
                        
                    }

                }
                
            }
            .onChange(of: qrDelegate.scannedCode) { newValue in
                if let code = newValue {
                    scannedCode = code
                    session.startRunning()
                    deActivateScannerAnimation()
                    
                    qrDelegate.scannedCode = nil
                }
            }

        } else {
            // Fallback on earlier versions
        }
        
    }
    
    
    
    //Reactive Camera
    
    func reactiveCamera(){
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    
    //Activate scanner
    func activateScannerAnimation(){
        
        withAnimation(.easeOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)){
            isScanning = true
        }
    }
    
    
    //DeActivate scanner
    func deActivateScannerAnimation(){
        
        withAnimation(.easeOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)){
            isScanning = false
        }
    }
    
    func cameraPermission(){
        if #available(iOS 15.0, *) {
            Task{
                switch AVCaptureDevice.authorizationStatus(for: .video){
                    
                case .notDetermined:
                    //Req camera access
                    
                    if await AVCaptureDevice.requestAccess(for: .video){
                        permission = .approved
                        setUpCamera()
                        
                        
                    }else{
                        permission = .denied
                        presentError(message: "Please prpvide camera access")
                    }
                    
                case .denied , .restricted:
                    permission = .denied
                    presentError(message: "Please prpvide camera access")
                case .authorized:
                    permission = .approved
                    
                    if session.inputs.isEmpty{
                        setUpCamera()
                    }
                    else{
                        session.startRunning()
                    }
                 default: break
                    
                }
                
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func presentError(message:String){
        errorMessage = message
        showError.toggle()
        
    }
    
    
    func setUpCamera(){
        
        do {
            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .back).devices.first else {
                presentError(message: "Unknown Device Error")
                return
            }
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input),session.canAddOutput(qrOutputType) else {
                presentError(message: "Unknown input/output Error")
                return
            }
            
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(qrOutputType)
            
            qrOutputType.metadataObjectTypes = [.qr]
            qrOutputType.setMetadataObjectsDelegate(qrDelegate, queue: .main)
            session.commitConfiguration()
            
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            
           
            
        } catch  {
            presentError(message: error.localizedDescription)
        }
        
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
