//*****************************************************************************
// Torque -- HLSL procedural shader
//*****************************************************************************

// Dependencies:
#include "shaders/common/lighting.hlsl"
#include "shaders/common/torque.hlsl"

// Features:
// Vert Position
// Terrain Base Texture
// Terrain Lightmap Texture
// RT Lighting
// Fog
// HDR Output
// Forward Shaded Material

struct ConnectData
{
   float3 texCoord        : TEXCOORD0;
   float3 wsNormal        : TEXCOORD1;
   float3 wsPosition      : TEXCOORD2;
};


struct Fragout
{
   float4 col : COLOR0;
};


//-----------------------------------------------------------------------------
// Main
//-----------------------------------------------------------------------------
Fragout main( ConnectData IN,
              uniform sampler2D baseTexMap      : register(S0),
              uniform sampler2D lightMapTex     : register(S1),
              uniform float3    eyePosWorld     : register(C15),
              uniform float4    inLightPos[3] : register(C0),
              uniform float4    inLightInvRadiusSq : register(C3),
              uniform float4    inLightColor[4] : register(C4),
              uniform float4    inLightSpotDir[3] : register(C8),
              uniform float4    inLightSpotAngle : register(C11),
              uniform float4    inLightSpotFalloff : register(C12),
              uniform float     specularPower   : register(C13),
              uniform float4    specularColor   : register(C14),
              uniform float4    ambient         : register(C16),
              uniform float4    fogColor        : register(C17),
              uniform float3    fogData         : register(C18)
)
{
   Fragout OUT;

   // Vert Position
   
   // Terrain Base Texture
   float4 baseColor = tex2D( baseTexMap, IN.texCoord.xy );
   OUT.col = baseColor;
   
   // Terrain Lightmap Texture
   float4 lightMask = 1;
   lightMask[0] = tex2D( lightMapTex, IN.texCoord.xy ).r;
   
   // RT Lighting
   IN.wsNormal = normalize( half3( IN.wsNormal ) );
   float3 wsView = normalize( eyePosWorld - IN.wsPosition );
   float4 rtShading; float4 specular;
   compute4Lights( wsView, IN.wsPosition, IN.wsNormal, lightMask,
      inLightPos, inLightInvRadiusSq, inLightColor, inLightSpotDir, inLightSpotAngle, inLightSpotFalloff, specularPower, specularColor,
      rtShading, specular );
   OUT.col *= float4( rtShading.rgb + ambient.rgb, 1 );
   
   // Fog
   float fogAmount = saturate( computeSceneFog( eyePosWorld, IN.wsPosition, fogData.r, fogData.g, fogData.b ) );
   OUT.col.rgb = lerp( fogColor.rgb, OUT.col.rgb, fogAmount );
   
   // HDR Output
   OUT.col = hdrEncode( OUT.col );
   
   // Forward Shaded Material
   

   return OUT;
}
