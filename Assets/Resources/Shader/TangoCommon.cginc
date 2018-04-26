#ifndef TANGO_COMMON
#define TANGO_COMMON

#include "UnityCG.cginc"

#define TANGENT_COORDS(idx1, idx2, idx3) \
    float4 TtoW0:TEXCOORD##idx1; \
    float4 TtoW1:TEXCOORD##idx2; \
    float4 TtoW2:TEXCOORD##idx3

#define WORLD_SPACE_TANGENT_VERTEX(v, o) \
    float3 worldNormal = UnityObjectToWorldNormal(v.vertex); \
    float3 worldTangent = UnityObjectToWorldDir(v.tangent); \
    float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; \
    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;\
    o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x); \
    o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y); \
    o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z)

#define WORLD_SPACE_TANGENT_FRAGMENT(i, tangentSpaceNormal) \
    half3 worldNormal = normalize(half3(dot(i.TtoW0.xyz, tangentSpaceNormal), dot(i.TtoW1.xyz, tangentSpaceNormal), dot(i.TtoW2.xyz, tangentSpaceNormal)))

#endif // TANGO_COMMON