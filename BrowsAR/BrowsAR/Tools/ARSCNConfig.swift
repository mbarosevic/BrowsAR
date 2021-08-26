//
//  ARSCNConfig.swift
//  BrowsAR
//
//  Created by mbarosevic on 26.08.2021..
//

import ARKit

extension ARSCNView {
  
  func hitTest(_ point: CGPoint) -> ARHitTestResult? {
    
    // Perform the hit test.
    let results = hitTest(point, types: [.existingPlaneUsingGeometry])
    
    // 1. Check for a result on an existing plane using geometry.
    if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }) {
      return existingPlaneUsingGeometryResult
    }
    
    // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
    let infinitePlaneResults = hitTest(point, types: .existingPlane)
    
    if let infinitePlaneResult = infinitePlaneResults.first {
      return infinitePlaneResult
    }
    
    return results.first(where: { $0.type == .estimatedHorizontalPlane })
  }
  
  func setUpNewTrackingConfiguration() {
    let configuration = ARWorldTrackingConfiguration()
    configuration.environmentTexturing = .automatic
    configuration.planeDetection = .horizontal
    
    let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
    session.run(configuration, options: options)
  }
}
