//
//  ViewController.swift
//  exp2
//
//  Created by Andy W on 07/12/2018.
//  Copyright © 2018 Andy W. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    
    var heartNode: SCNNode?
    var diamondNode: SCNNode?
    var imageNodes = [SCNNode]()
    var isAnimating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        let heartScene = SCNScene(named: "art.scnassets/heart.scn")
        let diamondScene = SCNScene(named: "art.scnassets/diamond.scn")
        heartNode = heartScene?.rootNode
        diamondNode = diamondScene?.rootNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARImageTrackingConfiguration()
        
        //Setting up image tracking ref images
        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Playingcards", bundle: Bundle.main) {
            configuration.trackingImages = trackingImages
            configuration.maximumNumberOfTrackedImages = 2
        }
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //AR anchor detection and object placing
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        //Check and see if the anchor is detected ar img anchor
        if let imageAnchor = anchor as? ARImageAnchor {
            let size = imageAnchor.referenceImage.physicalSize
            let overlayPlane = SCNPlane(width: size.width, height: size.height)
            overlayPlane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
            overlayPlane.cornerRadius = 0.005
            let planeNode = SCNNode(geometry: overlayPlane)
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
            
        //Adding AR model to the real object
            var shapeNode:SCNNode?
            switch imageAnchor.referenceImage.name {
            case CardType.heart.rawValue :
                shapeNode = heartNode
            case CardType.diamond.rawValue :
                shapeNode = diamondNode
            default:
                break
            }
            
        //Adding nodes actions
            let shapeSpin = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
            let repeatSpin = SCNAction.repeatForever(shapeSpin)
            shapeNode?.runAction(repeatSpin)
            
            guard let shape = shapeNode else {return nil}
            node.addChildNode(shape)
            imageNodes.append(node)
            return node
        }
        return nil
    }
    
    //Adding action effect for nodes when they are close to each other
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if imageNodes.count == 2 {
            let positionOne = SCNVector3ToGLKVector3(imageNodes[0].position)
            let positionTwo = SCNVector3ToGLKVector3(imageNodes[1].position)
            let distance = GLKVector3Distance(positionOne, positionTwo)
            print(distance)
            
            if distance < 0.10 {
                spinJump(node: imageNodes[0])
                spinJump(node: imageNodes[1])
                isAnimating = true
            }else {
                isAnimating = false
            }
        }
    }
    
    //Nodes actions
    func spinJump(node: SCNNode) {
        if isAnimating {return}
        let actualShapeNode = node.childNodes[1]
        let shapeSpin = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 1)
        shapeSpin.timingMode = .easeInEaseOut
        
        let up = SCNAction.moveBy(x: 0, y: 0.03, z: 0, duration: 0.5)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        let upDown = SCNAction.sequence([up, down])
        
        actualShapeNode.runAction(shapeSpin)
        actualShapeNode.runAction(upDown)
    }
    
    enum CardType: String {
        case heart = "cardA"
        case diamond = "cardB"
    }
}

