//*****************************************************************************
// Torque -- HLSL procedural shader
//*****************************************************************************

// Dependencies:
#include "shaders/common/lighting.hlsl"
#include "shaders/common/torque.hlsl"

// Features:
// Vert Position
// Base Texture
// RT Lighting
// Visibility
// Fog
// HDR Output
// Hardware Instancing
// Forward Shaded Material

struct ConnectData
{
   float2 texCoord        : TEXCOORD0;
   float3 wsNormal        : TEXCOORD1;
   float3 wsPosition      : TEXCOORD2;
   float visibility      : TEXCOORD3;
   float2 vpos            : VPOS;
};


struct Fragout
{
   float4 col : COLOR0;
};


//-----------------------------------------------------------------------------
// Main
//-----------------------------------------------------------------------------
Fragout main( ConnectData IN,
              uniform sampler2D diffuseMap      : register(S0),
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
   
   // Base Texture
   OUT.col = tex2D(diffuseMap, IN.texCoord);
   
   // RT Lighting
   IN.wsNormal = normalize( half3( IN.wsNormal ) );
   float3 wsView = normalize( eyePosWorld - IN.wsPosition );
   float4 rtShading; float4 specular;
   compute4Lights( wsView, IN.wsPosition, IN.wsNormal, float4( 1, 1, 1, 1 ),
      inLightPos, inLightInvRadiusSq, inLightColor, inLightSpotDir, inLightSpotAngle, inLightSpotFalloff, specularPower, specularColor,
      rtShading, specular );
   OUT.col *= float4( rtShading.rgb + ambient.rgb, 1 );
   
   // Visibility
   fizzle( IN.vpos, IN.visibility );
   
   // Fog
   float fogAmount = saturate( computeSceneFog( eyePosWorld, IN.wsPosition, fogData.r, fogData.g, fogData.b ) );
   OUT.col.rgb = lerp( fogColor.rgb, OUT.col.rgb, fogAmount );
   
   // HDR Output
   OUT.col = hdrEncode( OUT.col );
   
   // Hardware Instancing
   
   // Forward Shaded Material
   

   return OUT;
}
