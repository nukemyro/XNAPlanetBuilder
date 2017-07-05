#include "DeferredHeader.fxh"

// Global Variables
float4x4 world : WorldViewProjection;
float4x4 vp : ViewProjection;

float2 sqrt = 1024;
float maxHeight = 30;

float3 EyePosition;
float4x4 World;
texture heightMap;

sampler heightMapSampler = sampler_state
{
	Texture = <heightMap>;  
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float4 ScreenPosition : TEXCOORD0;    
};

struct VertexShaderInput
{
    float4 Position : POSITION0;    
    float4 Extras : POSITION1;
};

struct VertexShaderInputHP
{
    float4 Position : POSITION0; 
	float2 TexCoord : TEXCOORD0;   
    float4 Extras : POSITION1;
};

VertexShaderOutput VertexShaderFunctionT(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	
	input.Position.y = tex2Dlod(heightMapSampler,float4(input.Position.xz/sqrt,0,0)).r * maxHeight;

	output.Position = mul(mul(input.Position, world),vp);
	
    output.ScreenPosition = output.Position;
    
    return output;
}
VertexShaderOutput VertexShaderFunctionH(VertexShaderInput input,float4x4 instanceTransform : BLENDWEIGHT)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float4x4 world = transpose(instanceTransform);
	
	output.Position = mul(mul(input.Position, world),vp);
    output.ScreenPosition = output.Position;
    
    return output;
}

VertexShaderOutput VertexShaderFunctionHP(VertexShaderInputHP input,VertexShaderInput2 input2)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float4x4 world = transpose(input2.instanceTransform);
	input.Position.xyz = 0;
	
	float3 center = mul(input.Position,World);	
	float3 eyeVector = center - EyePosition;
	
	float3 finalPos = center;
	
	finalPos.x += input.TexCoord.x - .5;
	finalPos.y += .5 - input.TexCoord.y;
	
	half4 finalPos4 = mul(half4(finalPos,1),world);
	
	output.Position = mul(finalPos4,vp);
    output.ScreenPosition = output.Position;

	return output;
}
VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	output.Position = mul(mul(input.Position, world),vp);
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

technique ShadowMapHP
{
    pass Pass1
    {
		CULLMODE = NONE;
        VertexShader = compile vs_3_0 VertexShaderFunctionHP();
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
}

technique ShadowMapT
{
    pass Pass1
    {
		CULLMODE = NONE;
        VertexShader = compile vs_3_0 VertexShaderFunctionT();
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
}
