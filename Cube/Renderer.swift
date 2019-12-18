//
//  Renderer.swift
//  Cube
//
//  Created by skylar on 2019/12/18.
//  Copyright © 2019 skylar. All rights reserved.
//

import Metal
import MetalKit
import simd

struct Uniforms {
    var modelMatrix : float4x4
    var viewMatrix: float4x4
    var projectionMatrix: float4x4
}

class Renderer: NSObject {
    
    let mtkView: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var renderPipeline: MTLRenderPipelineState?
    var vertexDescriptor: MTLVertexDescriptor!
    
    var meshes: [MTKMesh] = []
    
    init(mtkView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(), let commandQueue = device.makeCommandQueue() else {
            fatalError("Init error")
        }
        mtkView.device = device
        self.device = device
        self.commandQueue = commandQueue
        self.mtkView = mtkView
        super.init()
        loadResources()
        buildPipeline()
    }
    
    func loadResources() {
        
        guard let modelURL = Bundle.main.url(forResource: "teapot", withExtension: "obj") else {
            fatalError("No such file")
        }
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        
        do {
            (_, meshes) = try MTKMesh.newMeshes(asset: asset, device: device)
        } catch {
            fatalError("Could not extract meshes from Model I/O asset")
        }
    }
    
    func buildPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load default library from main bundle")
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            renderPipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
    }
}

extension Renderer: MTKViewDelegate {
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = mtkView.currentRenderPassDescriptor,
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
            let renderPipeline = renderPipeline,
            let drawable = mtkView.currentDrawable  else {
                return
        }
        
        let model = modelMatrix()
        let view = viewMatrix()
        let projectionMatrix = projectMatrix(perspectiveProjectionFov: Float.pi / 3,
                                             aspectRatio: Float(mtkView.drawableSize.width / mtkView.drawableSize.height),
                                             nearZ: 0.1,
                                             farZ: 100)
        var uniforms = Uniforms(modelMatrix: model, viewMatrix: view, projectionMatrix: projectionMatrix)
        
        commandEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        commandEncoder.setRenderPipelineState(renderPipeline)
        for mesh in meshes {
            guard let vertexBuffer = mesh.vertexBuffers.first else {
                continue
            }
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)

            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
