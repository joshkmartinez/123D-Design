#include "Clipping10.fxh"
//#define LOCAL_VIEWER
#define FLIP_BACKFACING_NORMALS

// Light structure.
struct Light
{
    // The light color.
    float3 Color;
    
    // The light ambient color.
    float3 AmbColor;
    
    // The light specular color.
    float3 SpecColor;

    // The light direction, in world space.
    // NOTE: Used by directional and spot lights.  This is the direction *toward* the light.
    float3 Dir;

    // The light position, in world space.
    // NOTE: Used by point and spot lights.
    float3 Pos;
    
    // The light range and attenuation factors.
    // NOTE: Used by point and spot lights.
    float4 Atten;
   
    // The cosine of the light hotspot and falloff half-angles.
    // NOTE: Used by spot lights.
    float2 Cone;
};

void ComputeLightingCoefficients(
    float3 Lw, float3 Nw, float3 Vw, float exp, out float diff, out float spec)
{
    // Compute the intermediate results for lighting.
    // > NdotL: The dot product of the world space normal and world space light direction.
    // > Hw   : The halfway vector between the light direction and the view direction, computed as
    //          the normalized sum of the vectors.
    // > NdotH: The dot product of the world space normal and world space halfway vector.
    float NdotL = dot(Nw, Lw);
    float3 Hw = normalize(Vw + Lw);
    float NdotH = dot(Nw, Hw);

    // Use the lit() intrinsic function to compute the diffuse and specular coefficients.
    float4 lighting = lit(NdotL, NdotH, exp);
    diff = lighting.y;
    spec = lighting.z;
}

// Computes lighting for a single directional light.
void ComputeDirectionalLight(
    Light light, float3 Nw, float3 Vw, float exp,
    out float3 amb, out float3 diff, out float3 spec)
{
    // Compute the lighting coefficients based on the incident light direction, surface normal, and
    // view direction.
    float diffCoeff = 0.0f, specCoeff = 0.0f;
    ComputeLightingCoefficients(light.Dir, Nw, Vw, exp, diffCoeff, specCoeff);
    
    // Multiply the light color by the coefficients.
    // NOTE: The ambient component is only affected by attenuation, and there is none here.
    amb  = light.AmbColor;
    diff = light.Color * diffCoeff;
    spec = light.SpecColor * specCoeff;
}

#define LIGHT_COUNT 2

// The array of lights if order of light type: directional lights, followed by point lights,
// followed by spot lights.
Light gLightList[LIGHT_COUNT] : LightArray;

// The number of directional lights.
int gNumDirectionalLights : DirLightCount
<
    string UIName = "# Directional Lights";
    string UIWidget = "Slider";
    int UIMin = 0;
    int UIMax = 8;
    int UIStep = 1;
>
= 1;

// Compute the lighting contribution from the lights in the light array.
void ComputeLighting(
    float3 Nw, float3 Vw, float3 Pw, float exp, out float3 amb, out float3 diff, out float3 spec)
{
    // Set the initial color components to black.
    amb = diff = spec = 0.0f;
    float3 ambFromLight = 0.0f, diffFromLight = 0.0f, specFromLight = 0.0f;

    // Loop over the directional lights, adding the ambient, diffuse, and specular contributions of
    // each one to the output values.
    for (int i = 0; i < gNumDirectionalLights; i++)
    {
        ComputeDirectionalLight(gLightList[i], Nw, Vw, exp,
            ambFromLight, diffFromLight, specFromLight);

        amb  += ambFromLight;
        diff += diffFromLight;
        spec += specFromLight;
    }
}


// World transformation.
float4x4 gWXf : World < string UIWidget = "None"; >;

// World transformation, inverse transpose.
float4x4 gWITXf : WorldInverseTranspose < string UIWidget = "None"; >;

// World-view-projection transformation.
float4x4 gWVPXf : WorldViewProjection < string UIWidget = "None"; >;

// World-view transformation
float4x4 gWV : WorldView < string UIWidget = "None"; >;

#ifdef LOCAL_VIEWER
	float4x4 gVIXf : ViewInverse < string UIWidget = "None"; >;
#else
	float3 gViewDirection : ViewDirection < string UIWidget = "None"; >;
#endif

// Whether the projection matrix flips Z: -1.0 if so, otherwise 1.0.
float gProjZSense : ProjectionZSense < string UIWidget = "None"; >;

int  gMapType : MapType
<
string UIName = "Map Type";
string UIWidget = "Slider";
> = 0; 

// Emissive color.
float3 gEmiColor : Emissive
<
    string UIName = "Emissive";
    string UIWidget = "Color";
> = float3(0.0f, 0.0f, 0.0f);

// Ambient color.
float3 gAmbColor : Ambient
<
    string UIName = "Ambient";
    string UIWidget = "Color";
> = float3(0.0f, 0.0f, 0.0f);

// Diffuse color.
float3 gDiffColor : Diffuse
<
    string UIName =  "Diffuse Color";
    string UIWidget = "Color";
> = float3(0.7f, 0.7f, 0.7f);

// Specular color.
float3 gSpecColor : Specular
<
    string UIName =  "Specular Color";
    string UIWidget = "Color";
> = float3(0.0f, 0.0f, 0.0f);

// Glossiness (specular power).
float gGlossiness : SpecularPower
<
    string UIName = "Glossiness";
    string UIWidget = "Slider";
    float UIMin = 1.0f;
    float UIMax = 128.0f;
    float UIStep = 10.0;
> = 32.0f;

// Opacity factor.
float gOpacity : Opacity
<
    string UIName = "Opacity";
    string UIWidget = "Slider";
    float UIMin = 0.0f;
    float UIMax = 1.0f;
    float UIStep = 0.1f;
> = 1.0f;

float gGaussianFactor : GaussianFactor
<
    string UIName = "GaussianFactor";
    string UIWidget = "Slider";
> = 1.0f;

float4x4 gTextureTransform : TextureTransform;  

Texture1D gDiffTex : DiffuseTexture
<
string UIName = "Diffuse Texture";
> = NULL;

SamplerState gDiffSamp : DiffuseSampler;

// Depth priority, which shifts the model a bit forward in the z-buffer
float gDepthPriority : DepthPriority
<
    string UIName =  "Depth Priority";
    string UIWidget = "Slider";
    float UIMin = -16/1048576.0f;    // divide by 2^24/16 by default
    float UIMax = 16/1048576.0f;
    float UIStep = 1/1048576.0f;
> = 0.0f;

struct VS_INPUT
{
    float3 Pos  : POSITION;
    float3 Normal: NORMAL;
    float2 Texture  : TEXCOORD0;
};

struct VS_TO_PS
{
    float4 HPos       : SV_Position;
	float3 CurData    : TEXCOORD0;
    float3 Diff : COLOR0; 
    float3 Spec : COLOR1;

    // D3D10 ONLY
    // Clip distances, for eight clipping planes.
    float4 ClipDistances0 : SV_ClipDistance0;
    float4 ClipDistances1 : SV_ClipDistance1;
};

VS_TO_PS curvatureVS(VS_INPUT IN)
{
    VS_TO_PS OUT;
    float4 P = float4(IN.Pos, 1.0);
    OUT.HPos          = mul(P, gWVPXf);  

    // Transform the position and normal to world space for lighting, and normalize the normal.
    float4 HPw = mul(P, gWXf);
    float3 Nw = normalize(mul(IN.Normal, (float3x3)gWITXf));
    
#ifdef LOCAL_VIEWER
    // Compute the view direction, using the eye position and vertex position.  The eye
    // position is the translation vector of the inverse view transformation matrix.  This
    // provides more accurate lighting highlights and environment-mapped reflections than
    // using a non-local viewer (below).
    float3 Vw = HPw - gVIXf[3];
    float3 VwNorm = normalize(Vw);    
#else
    // Use the fixed view direction, the same for the entire view.  Use of this vector is
    // similar to disabling D3DRS_LOCALVIEWER for lighting and reflection in D3D9 (the
    // default state).  This is appropriate for orthographic projections.
    float3 VwNorm = gViewDirection;
#endif

    // Flip the normal to face the view direction, allowing proper shading of back-facing surfaces.
    // NOTE: This will lead to artifacts on the silhouettes of coarsely-tessellated surfaces.  A
    // compensation of about nine degrees is performed here (cos(99deg) ~ 0.15), so this issue
    // should be limited to triangles with very divergent normals.
#ifdef FLIP_BACKFACING_NORMALS
    Nw = -Nw * sign(dot(VwNorm, Nw));
#endif
    
    // Compute the ambient, diffuse, and specular lighting components from the light array.
    float3 amb = 0.0f;
    float3 spec = 0.0f;
    
    // Use the glossiness value.
    ComputeLighting(Nw, -VwNorm, HPw, gGlossiness, amb, OUT.Diff.rgb, spec);
    OUT.Diff.rgb *= gDiffColor;
    OUT.Diff.rgb += gAmbColor * amb + gEmiColor;
    OUT.Spec = gSpecColor * spec;

    // Clamp the diffuse and specular components to [0.0, 1.0] to match the limitations of COLOR
    // registers in SM 2.0.  Otherwise the final color output will not match.
    OUT.Diff = saturate(OUT.Diff);

    // modify the HPos a bit by biasing the Z a bit forward, based on depth priority
    OUT.HPos.z -= OUT.HPos.w*gDepthPriority;

	OUT.CurData.x = IN.Texture.x;
	OUT.CurData.y = IN.Texture.y;
	if(gMapType == 0)
	{
		OUT.CurData.z = IN.Texture.x * IN.Texture.y;
	}

    // D3D10 ONLY
    // Compute the eight clip distances.
    ComputeClipDistances(HPw, OUT.ClipDistances0, OUT.ClipDistances1);

    return OUT;
}

float4 curvaturePS(VS_TO_PS IN) : SV_Target
{
	float x;
 
 	if(gMapType == 0)
	{
		float curvature = IN.CurData.z;

        float sign = (curvature < 0.0f)?-1.0f:1.0f;
		curvature = (curvature < 0.0f)?-curvature:curvature;
		
		if (curvature == 0.0f || gGaussianFactor == 0.0f)
        {
			x = 0.5f;
        }
        else 
        {
			float expval = exp(-0.01f/(gGaussianFactor*gGaussianFactor*curvature))/2.0f;
			x = 0.5f + sign*expval;                                        
        }
	}
	else
	{
		if(gMapType == 1) x = IN.CurData.x;		
		else if(gMapType == 2) x =IN.CurData.y;
		x = x>0.0f?x:-x;
		float4 tp = mul(float4(x,0,0,1), gTextureTransform);
		x = tp.x;
	} 	

 	x = clamp(x, 0.01f, 0.99f);
	float4 color = gDiffTex.Sample(gDiffSamp, x);

    // Start the output color with the diffuse component.  The rest of the shader adds to it.
    float3 outputColor = IN.Diff.rgb;
    outputColor *= color;  //Treat the curvature map color as the diffuse texture
    // Add the specular component.
    outputColor += IN.Spec; 
    // Final color and alpha.
    float4 final = float4(outputColor, gOpacity);

    return final;
}

technique10 Curvature
{
    pass P0
    {
        SetVertexShader(CompileShader(vs_4_0, curvatureVS()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, curvaturePS()));
    }
}
