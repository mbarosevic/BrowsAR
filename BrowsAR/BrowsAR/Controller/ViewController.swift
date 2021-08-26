//
//  ViewController.swift
//  BrowsAR
//
//  Created by mbarosevic on 26.08.2021..
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet private var sceneView: ARSCNView!
    
    private var webViewArray : [WebView] = []
    private let dispatchQueueML = DispatchQueue(label: "BrowsAR.dispatchQueueML")
    private var visionRequests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpScene()
        setUpModel()
        setUpGestureRecognizer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.setUpNewTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

//MARK:- SetUps

extension ViewController {
    func setUpGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap) )
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    func setUpScene() {
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.session.delegate = self
    }
    
    func setUpModel() {
        guard let selectedModel = try? VNCoreMLModel(for: BrowsARModel().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project. Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
    }
}



extension ViewController {
  
  @objc func didTap(sender : UITapGestureRecognizer) {
    // Grabbing the camera current Transform
    guard let cameraCurrentTransform = self.sceneView.session.currentFrame?.camera.transform else { return }
    
    let node = WebViewNode()
    
    var translation = matrix_identity_float4x4
    translation.columns.3 = simd_float4(x: 0, y: 0, z: -1, w: translation.columns.3.w)
    
    // Assegning the result to the node's simdTransform
    node.simdTransform = matrix_multiply(cameraCurrentTransform, translation)
    
    // Adding the object to the scene
    sceneView.scene.rootNode.addChildNode(node)
    
    // Adding the web view to the sceneView
    let webView = WebView(node: node)
    view.addSubview(webView)
    
    // Appending the view to the array
    webViewArray.append(webView)
    print("New webview")
  }
  
  @objc func didTapRefresh() {
    webViewArray.removeAll()
    
    view.subviews.filter{$0 is WebView}.forEach { $0.removeFromSuperview() }
    
    self.sceneView.scene.rootNode.enumerateChildNodes { (node, _ ) in
      node.removeFromParentNode()
    }
  }
}

extension ViewController {
    // MARK: - MACHINE LEARNING
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        dispatchQueueML.async {
            // 1. Run Update.
                self.updateCoreML()
            // 2. Loop this function.
                self.loopCoreMLUpdate()
        }
    }
    
    func updateCoreML() {
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Run Vision Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...1] // top 3 results
            .compactMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:" : %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        // Render Classifications
        DispatchQueue.main.async { [self] in
            // Print Classifications
                // print(classifications)
                // print("-------------")
            
            // Display Debug Text on screen
            //self.debugTextView.text = "TOP 3 PROBABILITIES: \n" + classifications
            //print("TOP 5 PROBABILITIES: \n" + classifications)
            
            // Display Top Symbol
            //var symbol = "❎"
            let topPrediction = classifications.components(separatedBy: "\n")[0]
            let topPredictionName = topPrediction.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
            // Only display a prediction if confidence is above 1%
            let topPredictionScore:Float? = Float(topPrediction.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces))
            if (topPredictionScore != nil && topPredictionScore! > 0.01) {
                
                if (topPredictionName == "fist-UB-RHand") {
                    //symbol = "👊"
                    print("Going back")
                    if WebView.webView.canGoBack {
                        WebView.webView.goBack()
                    }
                }
                
                if (topPredictionName == "thumb-down") {
                    //symbol = "🖐"
                    print("thumb-down")
                    /*
                    if WebView.webView.canGoForward {
                        WebView.webView.goForward()
                    }
                    */
                }
                
                if (topPredictionName == "piece") {
                    //symbol = "🖐"
                    print("piece")
                    /*
                    if WebView.webView.canGoForward {
                        WebView.webView.goForward()
                    }
                    */
                }
                
                if topPredictionName == "thumb-up" {
                    /*
                    print("No hand -- scrolling")
                    var scrollPoint2 = self.view.convert(CGPoint(x: WebView.webView.scrollView.contentSize.width, y: WebView.webView.scrollView.contentSize.height), to: WebView.webView.scrollView)
                    scrollPoint2 = CGPoint(x: 0, y: WebView.webView.frame.size.height - WebView.webView.scrollView.contentSize.height)
                    WebView.webView.scrollView.setContentOffset(scrollPoint2, animated: true)
                    */
                    print("thumb-up")
                    /*
                     SCROLL DOWN
                    var scrollPoint = self.view.convert(CGPoint(x: 0, y: 0), to: WebView.webView.scrollView)
                    scrollPoint = CGPoint(x: scrollPoint.x, y: WebView.webView.scrollView.contentSize.height - WebView.webView.frame.size.height)
                    WebView.webView.scrollView.setContentOffset(scrollPoint, animated: true)
                    */
                }
                
                /*
                switch topPredictionName {
                case "no-hand":
                    print("No hand")
                case "piece-sign":
                    print("Piece sign")
                case "shaka-sign":
                    print("Shaka sign")
                case "thumb-down-sign":
                    print("Thumb down sign")
                case "thumb-up-sign":
                    print("Thumb up sign")
                case "thumb-down":
                    print("Thumb down")
                    var scrollPoint = self.view.convert(CGPoint(x: 0, y: 0), to: WebView.webView.scrollView)
                    scrollPoint = CGPoint(x: scrollPoint.x, y: WebView.webView.scrollView.contentSize.height - WebView.webView.frame.size.height)
                    WebView.webView.scrollView.setContentOffset(scrollPoint, animated: true)
                case "thumb-up":
                    print("Thumb up222")
                    var scrollPoint2 = self.view.convert(CGPoint(x: WebView.webView.scrollView.contentSize.width, y: WebView.webView.scrollView.contentSize.height), to: WebView.webView.scrollView)
                    scrollPoint2 = CGPoint(x: 0, y: WebView.webView.frame.size.height - WebView.webView.scrollView.contentSize.height)
                    WebView.webView.scrollView.setContentOffset(scrollPoint2, animated: true)
                    
                default:
                    print("ERROR")
                }
                */
            }
            
            //self.textOverlay.text = symbol
            //print(symbol)
            
        }
    }
}

extension ViewController: ARSessionDelegate {
  // Update webView size and orientation at every update of ARKit
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    for view in webViewArray {
      let projectedPosition = self.sceneView.projectPoint(view.webViewNode.worldPosition)
      
      let size = view.frame.size
      let x = CGFloat(projectedPosition.x) - size.width/2
      let y = CGFloat(projectedPosition.y) - size.height/2
      
      view.frame.origin = CGPoint(x: x, y: y)
    }
  }
}
