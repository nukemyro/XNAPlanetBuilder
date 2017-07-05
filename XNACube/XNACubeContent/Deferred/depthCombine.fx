#include "DeferredHeader.fxh"

texture depthMap1;
texture depthMap2;

sampler depthSampler1 = sampler_state
{
    Texture = (depthMap1);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};

sampler depthSampler2 = sampler_state
{
    Texture = (depthMap2);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
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
	float4 col = 0;

	float d1 = tex2D(depthSampler1,input.texCoord);
	float d2 = tex2D(depthSampler2,input.texCoord);

	col.r = d1;

	if(d1 <= d2)
		col.r = d2;

	col.a = 1;

	return col;
}
technique RenderScene
{
	pass Pass1
	{
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 RenderScenePS();
	}
}