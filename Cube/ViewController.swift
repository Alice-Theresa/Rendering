//
//  ViewController.swift
//  Cube
//
//  Created by skylar on 2019/12/18.
//  Copyright © 2019 skylar. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    lazy var mtkView: MTKView = {
        let view = MTKView()
        view.depthStencilPixelFormat = .depth32Float
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var renderer: Renderer = {
        return Renderer(mtkView: self.mtkView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(mtkView)
        mtkView.delegate = renderer
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
    }
}

