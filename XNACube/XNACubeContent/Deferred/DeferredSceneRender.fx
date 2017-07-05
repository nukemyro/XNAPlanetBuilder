#include "DeferredHeader.fxh"

texture colorMap;
texture lightMap;

float AmbientMag = .125;

sampler colorSampler = sampler_state
{
    Texture = (colorMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};
sampler lightSampler = sampler_state
{
    Texture = (lightMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};
texture sgrMap;
sampler SGRSampler = sampler_state
{
    Texture = (sgrMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

struct VertexShaderInput
{
    float3 Position : POSITION0;
    float2 texCoord : TEXCOORD0;
};

VertexShaderOutputToPS VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutputToPS output = (VertexShaderOutputToPS)0;
    output.Position = float4(input.Position,1);
    output.texCoord = input.texCoord - halfPixel;
    return output;
}

float4 RenderScenePS(VertexShaderOutputToPS input) : COLOR0
{
	//input.texCoord -= halfPixel;
	float4 col = tex2D(colorSampler,input.texCoord);
	float4 sgr = tex2D(SGRSampler,input.texCoord);
	
	// Only light none glowing pixels.
	if(sgr.g < .9)
		col *= (tex2D(lightSampler,input.texCoord) + AmbientMag) + (col * sgr.g);
	else
		col *= sgr.g;

	return col;
}
technique RenderScene
{
	pass Pass1
	{
		ZEnable = true;
		ZWriteEnable=true;
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 RenderScenePS();
	}
}