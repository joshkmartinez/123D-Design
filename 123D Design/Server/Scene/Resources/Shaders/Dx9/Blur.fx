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
// DESCRIPTION: Simple box blur.
// AUTHOR: Mauricio Vives
// CREATED: January 2009
//**************************************************************************/

#include "Common.fxh"

// Specify a default blur amount (number of samples in each direction, or the "radius" of the box
// filter) if none is specified.  Use to determine the number of samples per pixel, including the
// center sample.
// NOTE: This can have a maximum value of 12 to work within SM2.
#ifndef BLUR_AMOUNT
    #define BLUR_AMOUNT 5
#endif
static int gNumSamples = BLUR_AMOUNT * 2 + 1;

#ifndef FX_COMPOSER

// The source buffer and sampler.
texture2D gSourceTex < string UIWidget = "None"; > = NULL;
sampler2D gSourceSamp = sampler_state
{
    texture = <gSourceTex>;
};

#endif

// Pixel shader.
// NOTE: This expects screen quad vertex shader output.
float4 PS_Blur(VS_TO_PS_ScreenQuad In, uniform sampler2D source, uniform float2 direction) : COLOR0
{
    // Compute the per-sample offset, based on the texel size and blur direction.  Then compute the
    // location of the starting sample, using the number of taps.
    float2 offset = direction * gTexelSize;
    float2 UV = In.UV - offset * (gNumSamples - 1) * 0.5f;
    
    // Sum each of the samples (box filter).
    float4 sum = 0;
    for (int i = 0; i < gNumSamples; i++)
    {
        // Add the value from the source texture.
        sum += tex2D(source, UV);
        
        // Increment the texture coordinates by the offset.
        UV += offset;
    }
    
    // Return the average color and alpha.
    return float4(sum / gNumSamples);
}

#ifndef FX_COMPOSER

// Horizontal blur technique.
technique BlurHoriz
{
    pass p0
    {
        VertexShader = compile vs_2_0 VS_ScreenQuad();
        PixelShader = compile ps_2_0 PS_Blur(gSourceSamp, float2(1.0f, 0.0f));
        // A horizontal blur direction is specified as an argument above.
    }
}

// Vertical blur technique.
technique BlurVert
{
    pass p0
    {
        VertexShader = compile vs_2_0 VS_ScreenQuad();
        PixelShader = compile ps_2_0 PS_Blur(gSourceSamp, float2(0.0f, 1.0f));
        // A vertical blur direction is specified as an argument above.
    }
}

#endif