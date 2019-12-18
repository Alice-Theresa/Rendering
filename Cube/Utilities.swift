//
//  Utilities.swift
//  Cube
//
//  Created by skylar on 2019/12/18.
//  Copyright © 2019 skylar. All rights reserved.
//

import simd

func modelMatrix() -> matrix_float4x4 {
    return matrix_float4x4(columns: (vector_float4(1, 0, 0, 0),
                                     vector_float4(0, 1, 0, 0),
                                     vector_float4(0, 0, 1, 0),
                                     vector_float4(0, 0, 0, 1)))
}

func viewMatrix() -> matrix_float4x4 {
    return matrix_float4x4(columns: (vector_float4(1, 0, 0, 0),
                                     vector_float4(0, 1, 0, 0),
                                     vector_float4(0, 0, 1, 0),
                                     vector_float4(0, 0, -2, 1)))
}

func projectMatrix(perspectiveProjectionFov fovRadians: Float, aspectRatio aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
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
    return matrix_float4x4(columns: (vector_float4(xx, 0, 0, 0),
                                     vector_float4(0, yy, 0, 0),
                                     vector_float4(0, 0, zz, zw),
                                     vector_float4(0, 0, wz, 1)))
}
