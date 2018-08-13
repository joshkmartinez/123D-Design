//**************************************************************************/
// Copyright 2009 Autodesk, Inc.
// All rights reserved.
//
// This computer source code and related instructions and comments are the
// unpublished confidential and proprietary information of Autodesk, Inc.
// and are protected under Federal copyright and state trade secret law.
// They may not be disclosed to, copied or used by any third party without
// the prior written consent of Autodesk, Inc.
//**************************************************************************/
// DESCRIPTION: Weighted Average OIT effect.
// AUTHOR: Liming Zhang
// CREATED: February 2010
//**************************************************************************/

// World-view-projection transformation.
float4x4 gWVPXf : WorldViewProjection < string UIWidget = "None"; >;

// Color and alpha accumulation texture.
texture2D gColorTex : InputTexture
<
    string UIName = "Input Texture";
> = NULL;

// Color and alpha accumulation texture sampler.
sampler gColorSamp = sampler_state 
{
    Texture   = <gColorTex>;
};

// Depth complexity texture.
texture2D gColorTex2 : InputTexture
<
    string UIName = "Input Texture";
> = NULL;

// Depth complexity texture sampler.
sampler gColorSamp2 = sampler_state 
{
    Texture   = <gColorTex2>;
};

// Vertex shader input structure.
struct VS_INPUT
{
    float4 Pos : POSITION;
    float3 UV : TEXCOORD0;
};

// Vertex shader output structure.
struct VS_TO_PS
{
    float4 HPos : SV_Position;
    float3 UV : TEXCOORD0;
};

// Vertex shader.
VS_TO_PS VS_WeightedAverageFinal(VS_INPUT In)
{
    VS_TO_PS Out;
    
    // Transform the position from object space to clip space for output.
    Out.HPos = mul(In.Pos, gWVPXf);
    
    // Pass the texture coordinates unchanged.
    Out.UV = In.UV;
    
    return Out;
}


// Pixel shader.
float4 PS_WeightedAverageFinal(VS_TO_PS In) : SV_Target
{
    // Color sum.
	float4 SumColor = gColorTex.Sample(gColorSamp, In.UV.xy);

	// Depth Complexity
    float n = gColorTex2.Sample(gColorSamp2, In.UV.xy).r;

    // If depth comlexity is zero, it means no transparent color on this pixel.
    // So return zero directly.
	if (n == 0.0) {
		return 0.0f;
	}

    // Average Color
	float3 AvgColor = SumColor.rgb / SumColor.a;

    // Average Alpha
	float AvgAlpha = SumColor.a / n;

    // Final Alpha
	float T = pow(1.0-AvgAlpha, n);

    return float4(AvgColor, 1 - T);
}

// The main technique.
technique10 Main
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_4_0, VS_WeightedAverageFinal()));
        SetPixelShader(CompileShader(ps_4_0, PS_WeightedAverageFinal()));
    }
}
