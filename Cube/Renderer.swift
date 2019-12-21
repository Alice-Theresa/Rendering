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
    var normalMatrix: float3x3
}

class Renderer: NSObject {
    
    let mtkView: MTKView
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var renderPipeline: MTLRenderPipelineState?
    var vertexDescriptor: MTLVertexDescriptor?
    var library: MTLLibrary?
    
    var meshes: [MTKMesh] = []
    var angle: Float = 0
    
    var texture: MTLTexture?
    let samplerState: MTLSamplerState
    let depthStencilState: MTLDepthStencilState

    var skyboxPipeline: MTLRenderPipelineState?
    var skyMesh: MTKMesh?
//    var skyboxDescriptor: MTLVertexDescriptor?
    var skyTexture: MTLTexture?
    
    init(mtkView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(), let commandQueue = device.makeCommandQueue(), let library = device.makeDefaultLibrary() else {
            fatalError("Init error")
        }
        mtkView.device    = device
        self.device       = device
        self.commandQueue = commandQueue
        self.mtkView      = mtkView
        self.library = library
        samplerState = Renderer.buildSamplerState(device: device)
        depthStencilState = Renderer.buildDepthStencilState(device: device)
        super.init()
        loadResources()
        buildPipeline()
        buildSkybox()
    }
    
    func loadResources() {
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
        texture = try? textureLoader.newTexture(name: "tank",
                                                scaleFactor: 1.0,
                                                bundle: nil,
                                                options: options)
        guard let modelURL = Bundle.main.url(forResource: "cup_low", withExtension: "obj") else {
            fatalError("No such file")
        }
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
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
        guard let library = library else {
            fatalError("Could not load default library from main bundle")
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            renderPipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
    }
    
    func buildSkybox() {
        
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        guard let library = library else {
            fatalError("Could not load default library from main bundle")
        }
        
        let skyboxVertexFunction = library.makeFunction(name: "skybox_vertex")
        let skyboxFragmentFunction = library.makeFunction(name: "skybox_fragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = skyboxVertexFunction
        pipelineDescriptor.fragmentFunction = skyboxFragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        
        do {
            skyboxPipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let sphereMDLMesh = MDLMesh.init(boxWithExtent: [1, 1, 1], segments: [1, 1, 1], inwardNormals: true, geometryType: .triangles, allocator: bufferAllocator)
        skyMesh = try! MTKMesh(mesh: sphereMDLMesh, device: device)
        
        let textureLoader = MTKTextureLoader(device: device)
        skyTexture = try? textureLoader.newTexture(name: "SkyMap",
                                                   scaleFactor: 1.0,
                                                   bundle: .main,
                                                   options: nil)
        
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    static func buildDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
    static func buildSkyDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .lessEqual
        descriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState(descriptor: descriptor)!
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
        
        angle -= 1 / Float(mtkView.preferredFramesPerSecond)
        let modelMatrix = float4x4(rotationAbout: vector_float3(0, 1, 0), by: angle)
        var viewMatrix = float4x4(translationBy: vector_float3(0, 0, -6))
        let projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3,
                                        aspectRatio: Float(mtkView.drawableSize.width / mtkView.drawableSize.height),
                                        nearZ: 0.1,
                                        farZ: 100)
        var uniforms = Uniforms(modelMatrix: modelMatrix, viewMatrix: viewMatrix, projectionMatrix: projectionMatrix, normalMatrix: modelMatrix.normalMatrix)
        
        commandEncoder.setRenderPipelineState(renderPipeline)
        
        commandEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        
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
        // MARK: sky
        viewMatrix.columns.3 = [0, 0, 0, 1]
        uniforms = Uniforms(modelMatrix: float4x4(scaleBy: 1), viewMatrix: viewMatrix, projectionMatrix: projectionMatrix, normalMatrix: modelMatrix.normalMatrix)
        
        commandEncoder.setRenderPipelineState(skyboxPipeline!)
        commandEncoder.setDepthStencilState(Renderer.buildSkyDepthStencilState(device: device))
        commandEncoder.setVertexBuffer(skyMesh!.vertexBuffers[0].buffer, offset: 0, index: 0)
        commandEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        commandEncoder.setFragmentTexture(skyTexture!, index: 0)
        let submesh = skyMesh!.submeshes[0]
        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: submesh.indexCount,
                                            indexType: submesh.indexType,
                                            indexBuffer: submesh.indexBuffer.buffer,
                                            indexBufferOffset: 0)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
