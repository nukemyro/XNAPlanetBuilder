#include "DeferredHeader.fxh"

// Global Variables
float4x4 world : WorldViewProjection;
float4x4 vp : ViewProjection;

float2 sqrt = 1024;
float maxHeight = 30;

float4x4 Bones[MaxBones];

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float4 ScreenPosition : TEXCOORD0;    
};

struct VertexShaderInput
{
    float4 Position : POSITION0;    
    float4 Extras : POSITION1;    
	float4 BoneIndices : BLENDINDICES0;
    float4 BoneWeights : BLENDWEIGHT0;
};

VertexShaderOutput VertexShaderFunctionH(VertexShaderInput input,float4x4 instanceTransform : Binormal)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float4x4 world = transpose(instanceTransform);

	float4x4 skinTransform = 0;
    
	skinTransform += Bones[input.BoneIndices.x] * input.BoneWeights.x;
	skinTransform += Bones[input.BoneIndices.y] * input.BoneWeights.y;
	skinTransform += Bones[input.BoneIndices.z] * input.BoneWeights.z;
	skinTransform += Bones[input.BoneIndices.w] * input.BoneWeights.w;

	float4 position = mul(input.Position, mul(skinTransform,world));
    
	output.Position = mul(position, vp);
		
    output.ScreenPosition = output.Position;
    
    return output;
}
VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float4x4 skinTransform = 0;
    
	skinTransform += Bones[input.BoneIndices.x] * input.BoneWeights.x;
	skinTransform += Bones[input.BoneIndices.y] * input.BoneWeights.y;
	skinTransform += Bones[input.BoneIndices.z] * input.BoneWeights.z;
	skinTransform += Bones[input.BoneIndices.w] * input.BoneWeights.w;

	float4 position = mul(input.Position, skinTransform);
    
	output.Position = mul(position,vp);
    output.ScreenPosition = output.Position;
    
    return output;
}
struct outputPS
{
	float4 channel0 : COLOR0;
};
outputPS PSBasicTexture(VertexShaderOutput input)
{
	outputPS output = (outputPS)0;
	output.channel0.r = 1-(input.ScreenPosition.z/input.ScreenPosition.w);
	
	output.channel0.a = 1;
	return output;
}

technique ShadowMap
{
    pass Pass1
    {
		CULLMODE = NONE;
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
}

technique ShadowMapH
{
    pass Pass1
    {
		CULLMODE = NONE;
        VertexShader = compile vs_3_0 VertexShaderFunctionH();
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
}