#include "PPVertexShader.fx"

float4x4 ProjectionInv;
float4x4 Projection;

float2 halfPixel;
texture depthMap;

sampler depth = sampler_state
{
    Texture = (depthMap);
	MinFilter = Point;
	MagFilter = Point;
	MipFilter = None;
};

float4 PixelShaderFunction(float2 uv : TEXCOORD0) : COLOR0
{
	uv -= halfPixel;
    
	float4 position;
	float depthVal = 1-tex2D(depth,uv);
	position.x = uv.x * 2.0f - 1.0f;
	position.y = -(uv.y * 2.0f - 1.0f);
	position.z = depthVal;
	position.w = 1.0f;

	float4 worldPos = mul(position, ProjectionInv);
	worldPos.xyz /= worldPos.w;

	
	return mul(worldPos,Projection); //1-((worldPos + 1) * .5);
}

technique PositionMap
{
	pass p0
	{
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 PixelShaderFunction();
	}
}
