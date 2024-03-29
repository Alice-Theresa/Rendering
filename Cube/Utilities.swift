//
//  Utilities.swift
//  Cube
//
//  Created by skylar on 2019/12/18.
//  Copyright © 2019 skylar. All rights reserved.
//

import simd

extension float4x4 {
    init(scaleBy s: Float) {
        self.init(vector_float4(s, 0, 0, 0),
                  vector_float4(0, s, 0, 0),
                  vector_float4(0, 0, s, 0),
                  vector_float4(0, 0, 0, 1))
    }
    
    init(rotationAbout axis: vector_float3, by angleRadians: Float) {
        let x = axis.x, y = axis.y, z = axis.z
        let c = cosf(angleRadians)
        let s = sinf(angleRadians)
        let t = 1 - c
        self.init(vector_float4( t * x * x + c,     t * x * y + z * s, t * x * z - y * s, 0),
                  vector_float4( t * x * y - z * s, t * y * y + c,     t * y * z + x * s, 0),
                  vector_float4( t * x * z + y * s, t * y * z - x * s,     t * z * z + c, 0),
                  vector_float4(                 0,                 0,                 0, 1))
    }
    
    init(translationBy t: vector_float3) {
        self.init(vector_float4(   1,    0,    0, 0),
                  vector_float4(   0,    1,    0, 0),
                  vector_float4(   0,    0,    1, 0),
                  vector_float4(t[0], t[1], t[2], 1))
    }
    
    init(perspectiveProjectionFov fovRadians: Float, aspectRatio aspect: Float, nearZ: Float, farZ: Float) {
        let yScale = 1 / tan(fovRadians * 0.5)
        let xScale = yScale / aspect
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange
        
        let xx = xScale
        let yy = yScale
        let zz = zScale
        let zw = Float(-1)
        let wz = wzScale
        
        self.init(vector_float4(xx,  0,  0,  0),
                  vector_float4( 0, yy,  0,  0),
                  vector_float4( 0,  0, zz, zw),
                  vector_float4( 0,  0, wz,  1))
    }
    
    var normalMatrix: float3x3 {
        let (c1, c2, c3, _) = columns
        let upperLeft = float3x3(vector_float3(c1.x, c1.y, c1.z), vector_float3(c2.x, c2.y, c2.z), vector_float3(c3.x, c3.y, c3.z))
        return upperLeft.transpose.inverse
    }
}


