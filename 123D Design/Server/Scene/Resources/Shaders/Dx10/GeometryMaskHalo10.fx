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
// DESCRIPTION: Geometry mask Halo effect.
// Generates a halo around the input mask(s). The input can be one
// or two mask textures , one face mask and a line mask.
// The halo is calculated by first checking if you are outside both of the input masks (alpha 0).
// If true, check the samples in a specified radius around you. If you find a difference from 
// the pixel you are at return white as halo, else return black.
//
//    Inputs:  geometry face mask and geometry line mask. 
//    Output:  black and white texture where white stands for halo.
//
// AUTHOR:Charlotta Wadman
// CREATED: November 2009
//**************************************************************************/

// World-view-projection transformation.
float4x4 gWVPXf : WorldViewProjection < string UIWidget = "None"; >;

float2 gFinalres : ViewportPixelSize < string UIWidget = "None"; >;

float4 gScissorBox = float4(0,0,1,1);

#ifndef HALO_WIDTH
#define HALO_WIDTH 2
#endif


// The selection mask
texture2D gMask;

// Filter mask sampler.
SamplerState MaskSampler;

// The selection lines
texture2D gLines;

// Filter mask sampler.
SamplerState LinesSampler;

texture2D gBlur;
SamplerState BlurSampler;


// Input for deciding if lines should be taken into account.
bool gUseLines = true;

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
VS_TO_PS VS_NPR(VS_INPUT In)
{
    VS_TO_PS Out;

    // Transform the position from object space to clip space for output.
    Out.HPos = mul(In.Pos, gWVPXf);

    // Pass the texture coordinates unchanged.
    Out.UV = In.UV;

    return Out;
}


// Pixel shader.
// Generate the horizontal Halo
float4 PS_HHalo(VS_TO_PS In) : SV_Target
{
	float4 retValue = float4(0,0,0,0);
    float2 texCoord = In.UV.xy;

	int stepRadius = HALO_WIDTH;
    float checkRadius = HALO_WIDTH+0.5;

    float4 mask, lines;
    mask = gMask.Sample(MaskSampler, texCoord);
    lines = gLines.Sample(LinesSampler, texCoord);

    float2 offset;
    float2 sampleCoord;
    float4 sample, sample2;

    float2 edgeOffset = float2(1/gFinalres.x,1/gFinalres.y);

	float epsilon = max(1/gFinalres.x,1/gFinalres.y);

	if(texCoord.x >= (gScissorBox.x - checkRadius * epsilon)
	&& texCoord.x <= (gScissorBox.x + gScissorBox.z + checkRadius * epsilon)
	&& (1 - texCoord.y) >= (gScissorBox.y - checkRadius * epsilon)
	&& (1 - texCoord.y) <= (gScissorBox.y + gScissorBox.w + checkRadius * epsilon) )
	{
		// If lines are visible check the pixels where both the selection mask and lines mask have 
		// alpha 0(outside selection and lines).
		// If we skip this if statement there would be a halo on the inside of the lines as well.   
		if((mask.a == 0.0f) && (!gUseLines || (gUseLines && lines.a == 0.0f)))
		{

			// loop through all horizontal points around the center point
			offset.y = float(0);
			for ( int x = -stepRadius; x <= stepRadius; x++ )
			{
				offset.x = float(x);
				// is the distance to this point inside the radius?
				if (length(offset) < checkRadius)
				{	
					sampleCoord = texCoord + offset * edgeOffset;

					sample = gMask.SampleLevel( MaskSampler, sampleCoord, 0);
					sample2 = gLines.SampleLevel( LinesSampler, sampleCoord, 0);

					// check if this sample is different from the mask
					if(any(mask.rgb-sample.rgb) || (gUseLines && any(lines.rgb-sample2.rgb)))
					{
						retValue = float4(1,1,1,1);
					}
				}
			}
		}
		else
		{
			retValue = float4(1,1,1,1);
		}
	}
    return retValue;
}

// Pixel shader.
// Generate the vertical Halo
float4 PS_VHalo(VS_TO_PS In) : SV_Target
{
	float4 retValue = float4(0,0,0,0);
    float2 texCoord = In.UV.xy;

	int stepRadius = HALO_WIDTH;
    float checkRadius = HALO_WIDTH+0.5;

    float4 mask;
    mask = gMask.Sample(MaskSampler, texCoord);

    float2 offset;
    float2 sampleCoord;
    float4 sample;

    float2 edgeOffset = float2(1/gFinalres.x,1/gFinalres.y);

	float epsilon = max(1/gFinalres.x,1/gFinalres.y);

	if(texCoord.x >= (gScissorBox.x - checkRadius * epsilon)
	&& texCoord.x <= (gScissorBox.x + gScissorBox.z + checkRadius * epsilon)
	&& (1 - texCoord.y) >= (gScissorBox.y - checkRadius * epsilon)
	&& (1 - texCoord.y) <= (gScissorBox.y + gScissorBox.w + checkRadius * epsilon) )
	{
		if(mask.a == 0.0f)
		{
			// loop through all horizontal points around the center point
			offset.x = float(0);
			for ( int y = -stepRadius; y <= stepRadius; y++ )
			{
				offset.y = float(y);
				// is the distance to this point inside the radius?
				if (length(offset) < checkRadius)
				{	
					sampleCoord = texCoord + offset * edgeOffset;
					sample = gMask.SampleLevel( MaskSampler, sampleCoord, 0);

					// check if this sample is different from the mask
					if(any(mask.rgb-sample.rgb))
					{
						retValue = float4(1,1,1,1);
					}
				}
			}
		}
		else
		{
			retValue = float4(1,1,1,1);
		}
	}
    return retValue;
}

// Pixel shader.
float4 PS_NPR(VS_TO_PS In) : SV_Target
{
	float4 retValue = float4(0,0,0,0);
    float2 texCoord = In.UV.xy;

	int stepRadius = HALO_WIDTH;
    float checkRadius = HALO_WIDTH+0.5;

    float4 mask, lines, blur;
    mask = gMask.Sample(MaskSampler, texCoord);
	lines = gLines.Sample(LinesSampler, texCoord);
	blur = gBlur.Sample(BlurSampler, texCoord);

    float2 offset;
    float2 sampleCoord;
    float4 sample, sample2;

    float2 edgeOffset = float2(1/gFinalres.x,1/gFinalres.y);
	
	float epsilon = max(1/gFinalres.x,1/gFinalres.y);

	if(texCoord.x >= (gScissorBox.x - checkRadius * epsilon)
	&& texCoord.x <= (gScissorBox.x + gScissorBox.z + checkRadius * epsilon)
	&& (1 - texCoord.y) >= (gScissorBox.y - checkRadius * epsilon)
	&& (1 - texCoord.y) <= (gScissorBox.y + gScissorBox.w + checkRadius * epsilon) )
	{
		if((mask.a == 0.0f) && (!gUseLines || (gUseLines && lines.a == 0.0f)) && (blur.a != 0.0f))
		{
			// loop through all points in a square around the center point
			for ( int x = -stepRadius; x <= stepRadius; x++ )
			{
				offset.x = float(x);
				for ( int y = -stepRadius; y <= stepRadius; y++ )
				{
					offset.y = float(y);

					// is the distance to this point inside the radius?
					if (length(offset) < checkRadius)
					{	
						sampleCoord = texCoord + offset * edgeOffset;

						sample = gMask.SampleLevel( MaskSampler, sampleCoord, 0);
						sample2 = gLines.SampleLevel( LinesSampler, sampleCoord, 0);

						// check if this sample is different from the mask
						if(any(mask.rgb-sample.rgb) || (gUseLines && any(lines.rgb-sample2.rgb)))
						{
							retValue = float4(1,1,1,1);
						}
					}
				}
			}
		}
	}
    return retValue;
}

// The main technique.
technique10 Main
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_4_0,VS_NPR()));
        SetPixelShader(CompileShader(ps_4_0,PS_NPR()));
    }
}

technique10 T_HHalo
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_4_0, VS_NPR()));
        SetPixelShader(CompileShader(ps_4_0, PS_HHalo()));
    }

}

technique10 T_VHalo
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_4_0, VS_NPR()));
        SetPixelShader(CompileShader(ps_4_0, PS_VHalo()));
    }

}