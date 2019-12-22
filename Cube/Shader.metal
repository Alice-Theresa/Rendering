//
//  Shader.metal
//  Cube
//
//  Created by skylar on 2019/12/18.
//  Copyright © 2019 skylar. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
    float3 tangent [[ attribute(3) ]];
    float3 bitangent [[ attribute(4) ]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float2 texCoords;
    float3 worldTangent;
    float3 worldBitangent;
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3x3 normalMatrix;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Uniforms &uniforms [[buffer(5)]])
{
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1);
    VertexOut vertexOut;
    vertexOut.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPosition;
    vertexOut.worldNormal = uniforms.normalMatrix * in.normal;
    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.texCoords = in.texCoords;
    vertexOut.worldTangent = uniforms.normalMatrix * in.tangent;
    vertexOut.worldBitangent = uniforms.normalMatrix * in.bitangent;
    return vertexOut;
}

constant float3 ambientIntensity = 0.1;
constant float3 lightPosition(2, 2, 2); // Light position in world space
constant float3 lightColor(1, 1, 1);
constant float3 worldCameraPosition(0, 0, 2);
constant float specularPower = 200;

fragment float4 fragment_main(VertexOut fragmentIn [[stage_in]],
                              texture2d<float, access::sample> baseColorTexture [[texture(0)]],
                              texture2d<float, access::sample> normalTexture [[texture(1)]],
                              sampler baseColorSampler [[sampler(0)]])
{
    float3 baseColor = baseColorTexture.sample(baseColorSampler, fragmentIn.texCoords).rgb;
    float3 normalValue = normalTexture.sample(baseColorSampler, fragmentIn.texCoords).rgb;
    normalValue = normalValue * 2 - 1;
    normalValue = normalize(normalValue);
    
    float3 N = normalize(float3x3(fragmentIn.worldTangent, fragmentIn.worldBitangent, fragmentIn.worldNormal) * normalValue);
//    float3 N = normalize(fragmentIn.worldNormal);
    float3 L = normalize(lightPosition - fragmentIn.worldPosition);
    float3 diffuseIntensity = saturate(dot(N, L));
    float3 V = normalize(worldCameraPosition - fragmentIn.worldPosition);
    float3 R = reflect(L, N);
    float specularIntensity = pow(saturate(-dot(R, V)), specularPower);
//    float3 H = normalize(L + V);
//    float specularBase = saturate(dot(N, H));
//    float specularIntensity = powr(specularBase, specularPower);
    float3 finalColor = saturate(ambientIntensity + diffuseIntensity) * baseColor * lightColor + specularIntensity * lightColor;
    return float4(finalColor, 1);
}

