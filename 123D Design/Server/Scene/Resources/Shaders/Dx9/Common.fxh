//**************************************************************************/
// Copyright (c) 2008 Autodesk, Inc.
// All rights reserved.
// 
// These coded instructions, statements, and computer programs contain
// unpublished proprietary information written by Autodesk, Inc., and are
// protected by Federal copyright law. They may not be disclosed to third
// parties or copied or duplicated in any form, in whole or in part, without
// the prior written consent of Autodesk, Inc.
//**************************************************************************/
// DESCRIPTION: Common shader code.
// AUTHOR: Mauricio Vives
// CREATED: December 2008
//**************************************************************************/

#ifndef _COMMON_FXH_
#define _COMMON_FXH_

// World-view-projection transformation.
float4x4 gWVPXf : WorldViewProjection < string UIWidget = "None"; >;

// Screen size, in pixels.
float2 gScreenSize : ViewportPixelSize < string UIWidget = "None"; >;
static float2 gTexelSize = 1.0f / gScreenSize;

////////////////////////////////////////////////////////////////////////////////////////////////////
// Screen Quad Vertex Shader
////////////////////////////////////////////////////////////////////////////////////////////////////

// Vertex shader input structure.
struct VS_INPUT_ScreenQuad
{
    float3 Pos : POSITION;
    float2 UV : TEXCOORD0;
};

// Vertex shader output structure.
struct VS_TO_PS_ScreenQuad
{
    float4 HPos : POSITION;
    float2 UV : TEXCOORD0;
};

// Vertex shader.
VS_TO_PS_ScreenQuad VS_ScreenQuad(VS_INPUT_ScreenQuad In)
{
    VS_TO_PS_ScreenQuad Out;
    
    // Output the position and texture coordinates directly.
    #ifdef FX_COMPOSER
        Out.HPos = float4(In.Pos, 1.0f);
        Out.UV = In.UV + 0.5f / gScreenSize; // D3D9 texel offset
    #else
        Out.HPos = mul(float4(In.Pos, 1.0f), gWVPXf);
        Out.UV = In.UV;
    #endif
    
    return Out;
}

#endif // _COMMON_FXH_