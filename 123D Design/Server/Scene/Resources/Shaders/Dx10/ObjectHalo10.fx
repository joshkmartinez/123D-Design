//**************************************************************************/
// Copyright 2009 Autodesk, Inc.
// All rights reserved.
// 
// These coded instructions, statements, and computer programs contain
// unpublished proprietary information written by Autodesk, Inc., and are
// protected by Federal copyright law. They may not be disclosed to third
// parties or copied or duplicated in any form, in whole or in part, without
// the prior written consent of Autodesk, Inc.
//**************************************************************************/
// DESCRIPTION: Object halo detection.
//	  Creates a halo only on the outside of the object.
//    Takes an object id map and a object depth map as input.
//    To calculate the halo you check object ids and object depths for samples in a radius around 
//    the center pixel and compare them with the center pixels id and depth.
//    If you find a sample with different object id and that is 
//	  closer(smaller depth) than the center pixel return white as halo, else return black.
//
//    Inputs:  object ID map and a depth map. 
//    Output:  black and white texture where white stands for halo.
//
// AUTHOR: Charlotta Wadman
// CREATED: February 2010
//**************************************************************************/

// World-view-projection transformation.
float4x4 gWVPXf : WorldViewProjection < string UIWidget = "None"; >;

float2 gFinalres : ViewportPixelSize;

int gHaloWidth = 2;

float4 gScissorBox = float4(0,0,1,1);

// Filter input sampler.
Texture2D gObjectID;

SamplerState ObjectIDSampler;

Texture2D gDepth;

SamplerState DepthSampler;

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

float4 CalcHalo(float4 id, float idz, float4 center, float centerz, inout float4 outColor)
{
    // if center pixel and sample have different id	
    if(any(center-id))
    {
        //Only add halo if the sample is closer than the center
        // to get a halo only on the outside of the object.
        if(centerz>idz ){
            outColor = float4(1,1,1,1);
        }
    }

    return outColor;
}

float4 PS_NPR(VS_TO_PS In) : SV_Target
{
	float4 outColor = float4(0,0,0,0);
    float2 texCoord = In.UV.xy;
	int stepRadius = gHaloWidth;
    float checkRadius = gHaloWidth+0.5;

    float2 offset;
    float2 sampleCoord;
    float4 sample, center;
    float samplez, centerz;

    float2 edgeOffset = float2(1/gFinalres.x,1/gFinalres.y);

    // retrieve the center and its z-depth, 
    center = gObjectID.Sample(ObjectIDSampler, texCoord);
    centerz = gDepth.Sample(DepthSampler, texCoord).r;

	float epsilon = max(1/gFinalres.x,1/gFinalres.y);

	if(texCoord.x >= (gScissorBox.x - checkRadius * epsilon)
	&& texCoord.x <= (gScissorBox.x + gScissorBox.z + checkRadius * epsilon)
	&& (1 - texCoord.y) >= (gScissorBox.y - checkRadius * epsilon)
	&& (1 - texCoord.y) <= (gScissorBox.y + gScissorBox.w + checkRadius * epsilon) )
	{
		// loop through all points in a square around the center point
		for ( int x = -stepRadius; x <= stepRadius; x++ )
		{
			offset.x = float(x);
			for ( int y = -stepRadius; y <= stepRadius; y++ )
			{
				offset.y = float(y);

				// is the distance to this point inside the radius?
				if (length(offset)< checkRadius )
				{	
					sampleCoord.xy = texCoord.xy + edgeOffset.xy * offset.xy;

					sample  = gObjectID.SampleLevel(ObjectIDSampler, sampleCoord,0);
					samplez = gDepth.SampleLevel(DepthSampler,sampleCoord,0).r;

					outColor = CalcHalo( sample, samplez, center, centerz, outColor);
				}
			}
		}
	}
    return outColor;
}

technique10 Main
{
    pass p0
    {
        SetVertexShader(CompileShader(vs_4_0,VS_NPR()));
        SetPixelShader(CompileShader(ps_4_0,PS_NPR()));
    }
}
