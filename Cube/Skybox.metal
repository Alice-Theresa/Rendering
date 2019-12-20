//
//  Skybox.metal
//  Cube
//
//  Created by skylar on 2019/12/20.
//  Copyright © 2019 skylar. All rights reserved.
//

#import <simd/simd.h>
#include <metal_stdlib>
using namespace metal;

// Per-vertex inputs fed by vertex buffer laid out with MTLVertexDescriptor in Metal API
typedef struct
{
    float4 position [[attribute(0)]];
    float3 normal   [[attribute(2)]];
} SkyboxVertex;

typedef struct
{
    float4 position [[position]];
    float3 texcoord;
} SkyboxInOut;

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3x3 normalMatrix;
};

vertex SkyboxInOut skybox_vertex(SkyboxVertex in [[ stage_in ]], constant Uniforms & uniforms [[ buffer(1) ]])
{
    SkyboxInOut out;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * in.position;
    out.texcoord = in.normal;
    return out;
}

fragment half4 skybox_fragment(SkyboxInOut in [[ stage_in ]], texturecube<float> skybox_texture [[ texture(0) ]])
{
    constexpr sampler linearSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    float4 color = skybox_texture.sample(linearSampler, in.texcoord);
    return half4(color);
}

