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
// DESCRIPTION: Clipping utilities (D3D10).
// AUTHOR: Mauricio Vives
// CREATED: May 2008
//**************************************************************************/

#ifndef _CLIPPING_FXH_
#define _CLIPPING_FXH_

// Clipping plane array (world space).
float4 gClipPlanes[8] : ClippingPlanes =
{
	float4(1.0f, 0.0f, 0.0f, 0.0f),
	float4(0.0f, 1.0f, 0.0f, 0.0f),
	float4(0.0f, 0.0f, 1.0f, 0.0f),
	float4(1.0f, 0.0f, 0.0f, 0.0f),
	float4(1.0f, 0.0f, 0.0f, 0.0f),
	float4(1.0f, 0.0f, 0.0f, 0.0f),
	float4(1.0f, 0.0f, 0.0f, 0.0f),
	float4(1.0f, 0.0f, 0.0f, 0.0f)
};

// Number of clipping planes.
int gNumClipPlanes : ClippingPlaneCount
<
    string UIName = "# Clipping Planes";
    string UIWidget = "Slider";
    int UIMin = 0;
    int UIMax = 8;
    int UIStep = 1;
>
= 0;

void ComputeClipDistances(float4 HPw, out float4 clipDistances0, out float4 clipDistances1)
{
	clipDistances0.xyzw = 1.0f;
	clipDistances1.xyzw = 1.0f;
	
	// A clip distance is the distance of the specified world-space point from the clipping plane.
	// This is computed with a dot product.  Values are interpolated in the rasterizer, and
	// fragments with any value less then zero (i.e. on the negative side of a clipping plane)
	// are discarded before reaching the pixel shader.

	// Compute clip distances for planes 0 - 3.
	if (gNumClipPlanes > 0)
	{
		clipDistances0.x = dot(HPw, gClipPlanes[0]);
		if (gNumClipPlanes > 1) clipDistances0.y = dot(HPw, gClipPlanes[1]);
		if (gNumClipPlanes > 2) clipDistances0.z = dot(HPw, gClipPlanes[2]);
		if (gNumClipPlanes > 3) clipDistances0.w = dot(HPw, gClipPlanes[3]);
	}
	
	// Compute clip distances for planes 4 - 7.
	if (gNumClipPlanes > 4)
	{
		clipDistances1.x = dot(HPw, gClipPlanes[4]);
		if (gNumClipPlanes > 5) clipDistances1.y = dot(HPw, gClipPlanes[5]);
		if (gNumClipPlanes > 6) clipDistances1.z = dot(HPw, gClipPlanes[6]);
		if (gNumClipPlanes > 7) clipDistances1.w = dot(HPw, gClipPlanes[7]);
	}
}

#endif // _CLIPPING_FXH_
