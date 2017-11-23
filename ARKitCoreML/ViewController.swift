//
//  ViewController.swift
//  ARKitCoreML
//
//  Created by duoxiaoxiang on 2017/11/22.
//  Copyright © 2017年 duoxiaoxiang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    //模型变量
    var resentModel = Resnet50()
    
    var hitTestResult:ARHitTestResult!
    
    var visionRequests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene() //named: "art.scnassets/ship.scn"
        
        // Set the scene to the view
        sceneView.scene = scene
        registerGestureRecohnizers()
    }
    
    func registerGestureRecohnizers(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(gesture:)))
        self.sceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func tapped(gesture:UIGestureRecognizer) {
        let sceneView = gesture.view as! ARSCNView//当前页面sceneView的截图
        let touchLocation = self.sceneView.center
        guard let currentFrame = sceneView.session.currentFrame else {return}//判断当前是否有像素
        let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)//识别物件特征点
        if hitTestResults.isEmpty {return}
        guard let hitTestResult = hitTestResults.first else {return}
        self.hitTestResult = hitTestResult
        let pixelBuffer = currentFrame.capturedImage
        
        performVisionRequest(pixelBuffer: pixelBuffer)
    }
    
    
    //展示预测的结果
    func displayPredictions(text:String){
        let node = createText(text: text)
        node.position = SCNVector3(self.hitTestResult.worldTransform.columns.3.x, self.hitTestResult.worldTransform.columns.3.y, self.hitTestResult.worldTransform.columns.3.z)
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    //制作AR图标跟底座
    func createText(text:String) -> SCNNode{
        let parentNode = SCNNode()
        //底座
        let sphere = SCNSphere(radius: 0.01) //单位米  创建一个半径1公分的球
        //渲染器
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.orange
        sphere.firstMaterial = sphereMaterial
        
        let sphereNode = SCNNode(geometry: sphere)
        
        
        
        let textGeo = SCNText(string: text, extrusionDepth: 0.1)
        textGeo.alignmentMode = kCAAlignmentCenter
        textGeo.firstMaterial?.diffuse.contents = UIColor.orange
        textGeo.firstMaterial?.specular.contents = UIColor.white
        textGeo.firstMaterial?.isDoubleSided = true
        textGeo.font = UIFont(name: "Futura", size: 0.15)
        
        let textNode = SCNNode(geometry: textGeo)
        textNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        
        
        parentNode.addChildNode(sphereNode)
        parentNode.addChildNode(textNode)
        
        return parentNode
    }
    
    func performVisionRequest(pixelBuffer:CVPixelBuffer){
        let visionModel = try! VNCoreMLModel(for: self.resentModel.model)
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if error != nil {return}
            guard let observations = request.results else {return}
            let observation = observations.first as! VNClassificationObservation//用来处理运算结果（把结果中的第一位拿出来进行分析）
            DispatchQueue.main.async {
                self.displayPredictions(text: observation.identifier)
            }
//            print("name \(observation.identifier) and \(observation.confidence)")
        }
        request.imageCropAndScaleOption = .centerCrop
        self.visionRequests = [request]//拿到结果
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])//将拿到的结果左右翻转
        DispatchQueue.global().async {
            try! imageRequestHandler.perform(self.visionRequests)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
