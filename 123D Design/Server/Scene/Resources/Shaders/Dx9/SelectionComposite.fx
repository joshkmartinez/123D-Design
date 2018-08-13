//**************************************************************************/
// Copyright (c) 2009 Autodesk, Inc.
// All rights reserved.
// 
// These coded instructions, statements, and computer programs contain
// unpublished proprietary information written by Autodesk, Inc., and are
// protected by Federal copyright law. They may not be disclosed to third
// parties or copied or duplicated in any form, in whole or in part, without
// the prior written consent of Autodesk, Inc.
//**************************************************************************/
// DESCRIPTION: Composite selection effect.
//Takes different masks as input, face mask, halo mask, lines mask and glow mask.
// Colors the input masks and blends them together.
//
//    Inputs:  line geometry mask, geometry face mask, halo mask, glow mask. 
//    Output:  texture where masks has been colored and composited.
//
// AUTHOR:Charlotta Wadman
// CREATED: November 2009
//**************************************************************************/

// World-view-projection transformation.
float4x4 gWVPXf : WorldViewProjection < string UIWidget = "None"; >;

float2 gFinalres : ViewportPixelSize;

// The lines filter input
texture2D gLines;

// Filter input sampler.
sampler2D LinesSampler = sampler_state
{
    Texture = <gLines>;
};

// The selection mask
texture2D gMask;

// Filter mask sampler.
sampler2D MaskSampler = sampler_state
{
    Texture = <gMask>;
};

// The glow filter input
texture2D gGlow;

// Filter input sampler.
sampler2D GlowSampler = sampler_state
{
    Texture = <gGlow>;
};

// The halo input
texture2D gHalo;

// Filter input sampler.
sampler2D HaloSampler = sampler_state
{
    Texture = <gHalo>;
};

bool gUseBase = true;
bool gUseHalo = true;
bool gUseGlow = true;
bool gUseLines = true;

float4 gVisibleLineMask = float4(0.0f, 0.0f, 0.0f, 1.0f);
float4 gMaskColor = float4(0.0f, 0.0f, 0.0f, 1.0f);
float4 gMaskBackFaceColor = float4(1.0f, 0.0f, 0.0f, 1.0f);
float4 gLineColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
float4 gHiddenLineColor = float4(0.18f, 0.25f, 0.49f, 1.0f);
float4 gGlowColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
float4 gBaseColor = float4(0.0,0.0,1.0,0.5);
float4 gBackFaceColor = float4(0.0,0.0,1.0,0.1);
float4 gHaloColor = float4(0.5,0.5,0.5,1.0);

// Vertex shader input structure.
struct VS_INPUT
{
    float4 Pos : POSITION;
    float3 UV : TEXCOORD0;
};

// Vertex shader output structure.
struct VS_TO_PS
{
    float4 HPos : POSITION;
    float3 UV : TEXCOORD0;
};


// Vertex shader.
VS_TO_PS VS_NPR(VS_INPUT In)
{
    VS_TO_PS Out;
    
    // Transform the position from object space to clip space for output.
    Out.HPos = mul(In.Pos, gWVPXf);
    
    // Pass the texture coordinates unchanged.
    Out.UV = In.UV;
    
    return Out;
}

bool compareColors(float3 a, float3 b)
{	
    if((a[0]!=b[0]) || (a[1]!=b[1]) || (a[2]!=b[2])) 
    {
        return false;
    }
    return true;
}

// This function sets the base colors on pixels that are
// inside the selection mask. Mask back face pixels and front 
// face pixels gets different colors. 
float4 GetBase( float4 mask){

    //Set base color if inside the mask
    if(compareColors(mask.rgb,gMaskColor.rgb)) 
    {
        return gBaseColor;
    }
    if(compareColors(mask.rgb,gMaskBackFaceColor.rgb)) 
    {
        return gBackFaceColor;
    }
    
    return float4(0,0,0,0);
}

// To "precomposite", just composite all the layers back to front on
// top of a black and fully-transparent destination.
// Then you can take the resulting image and composite it on top of the underlying
// image normally. Both operations use the normal blending operations:
//
// dest.rgb' = dest.rgb * src.a + src.rgb    - here src is assumed to be premultiplied by alpha
// dest.a' = src.a + dest.a * (1 - src.a) (alternately: dest.a + src.a * (1 - dest.a), it's the same)

void specialBlend( inout float4 dest, float4 source )
{
    dest = float4( lerp( dest.rgb, source.rgb, source.a ), 
        source.a + dest.a * ( 1 - source.a ) );
}

// Pixel shader.
float4 PS_NPR(VS_TO_PS In) : COLOR0
{
    float2 texCoord = In.UV.xy;
    
    float4 lines, glow, mask, halo, all;
    
    // can be float4( scene.rgb,  ) if main scene is provided as input
    // Else, we make this a true compositing layer, with all 0's where nothing is happening.
    all = float4( 0, 0, 0, 0 );
    
    mask = tex2D(MaskSampler, texCoord);
    
    
    if(gUseBase)
    {
        // blend in the base color
        specialBlend( all, GetBase(mask) );
    }
    
    
    
    
    if(gUseLines){
        lines = tex2D(LinesSampler, texCoord);	
        
        float4 lineColor;
        if(lines.a==1.0 && lines.r == gVisibleLineMask.r )
        {
            lineColor = gLineColor;
        }
        else
        {
            lineColor = gHiddenLineColor;
        }
        
        specialBlend( all, float4( lineColor.rgb, lines.a * lineColor.a ));
    }
    
    if(gUseLines)
    {
        glow = tex2D(GlowSampler, texCoord);
        // note that maskedGlow.rgb is not used!
        //float4 maskedGlow = float4(lerp(glow.rgb,mask.rgb ,1-mask.a),(mask.a*glow.a*gGlowColor.a));
        //specialBlend( all, float4( gGlowColor.rgb, maskedGlow.a ) );
        // revised code:
		float4 lineColor;
        if(glow.a==1.0 && glow.r == gVisibleLineMask.r )
        {
            lineColor = gGlowColor;
        }
        else
        {
            lineColor = gHiddenLineColor;
        }
        specialBlend( all, float4( lineColor.rgb, glow.a*lineColor.a ) );
    }

    if(gUseHalo)
    {
        halo = tex2D(HaloSampler, texCoord);
        if(halo.r > 0.5){
            specialBlend( all, gHaloColor);
        }
    }
    
    return all;
}

// The main technique.
technique Main
{
    pass p0
    {

        VertexShader = compile vs_2_0 VS_NPR();
        PixelShader = compile ps_2_0 PS_NPR();

    }
}
