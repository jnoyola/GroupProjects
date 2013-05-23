//*****************************************************************************
// Torque -- HLSL procedural shader
//*****************************************************************************

// Dependencies:
#include "shaders/common/lighting.hlsl"
#include "shaders/common/torque.hlsl"

// Features:
// Vert Position
// Base Texture
// Specular Map
// Bumpmap
// RT Lighting
// Pixel Specular
// Visibility
// Fog
// HDR Output
// Hardware Instancing
// Forward Shaded Material
// DXTnm

struct ConnectData
{
   float2 texCoord        : TEXCOORD0;
   float3x3 worldToTangent  : TEXCOORD1;
   float3 wsPosition      : TEXCOORD4;
   float visibility      : TEXCOORD5;
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
              uniform sampler2D specularMap     : register(S1),
              uniform sampler2D bumpMap         : register(S2),
              uniform float3    eyePosWorld     : register(C14),
              uniform float4    inLightPos[3] : register(C0),
              uniform float4    inLightInvRadiusSq : register(C3),
              uniform float4    inLightColor[4] : register(C4),
              uniform float4    inLightSpotDir[3] : register(C8),
              uniform float4    inLightSpotAngle : register(C11),
              uniform float4    inLightSpotFalloff : register(C12),
              uniform float     specularPower   : register(C13),
              uniform float4    ambient         : register(C15),
              uniform float4    fogColor        : register(C16),
              uniform float3    fogData         : register(C17)
)
{
   Fragout OUT;

   // Vert Position
   
   // Base Texture
   OUT.col = tex2D(diffuseMap, IN.texCoord);
   
   // Specular Map
   float4 specularColor = tex2D(specularMap, IN.texCoord);
   
   // Bumpmap
   float4 bumpNormal = float4( tex2D(bumpMap, IN.texCoord).ag * 2.0 - 1.0, 0.0, 0.0 ); // DXTnm
   bumpNormal.z = sqrt( 1.0 - dot( bumpNormal.xy, bumpNormal.xy ) ); // DXTnm
   float3 wsNormal = normalize( mul( bumpNormal.xyz, IN.worldToTangent ) );
   
   // RT Lighting
   float3 wsView = normalize( eyePosWorld - IN.wsPosition );
   float4 rtShading; float4 specular;
   compute4Lights( wsView, IN.wsPosition, wsNormal, float4( 1, 1, 1, 1 ),
      inLightPos, inLightInvRadiusSq, inLightColor, inLightSpotDir, inLightSpotAngle, inLightSpotFalloff, specularPower, specularColor,
      rtShading, specular );
   OUT.col *= float4( rtShading.rgb + ambient.rgb, 1 );
   
   // Pixel Specular
   OUT.col.rgb += ( specular * specularColor ).rgb;
   
   // Visibility
   fizzle( IN.vpos, IN.visibility );
   
   // Fog
   float fogAmount = saturate( computeSceneFog( eyePosWorld, IN.wsPosition, fogData.r, fogData.g, fogData.b ) );
   OUT.col.rgb = lerp( fogColor.rgb, OUT.col.rgb, fogAmount );
   
   // HDR Output
   OUT.col = hdrEncode( OUT.col );
   
   // Hardware Instancing
   
   // Forward Shaded Material
   
   // DXTnm
   

   return OUT;
}