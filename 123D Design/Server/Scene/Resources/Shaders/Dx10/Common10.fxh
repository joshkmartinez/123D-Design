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
// DESCRIPTION: Common shader code (D3D10).
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
    float4 HPos : SV_Position;
    float2 UV : TEXCOORD0;
};

// Vertex shader.
VS_TO_PS_ScreenQuad VS_ScreenQuad(VS_INPUT_ScreenQuad In)
{
    VS_TO_PS_ScreenQuad Out;
    
    // Output the position and texture coordinates directly.
    Out.HPos = mul(float4(In.Pos, 1.0f), gWVPXf);
    Out.UV = In.UV;
    
    return Out;
}

#endif // _COMMON_FXH_