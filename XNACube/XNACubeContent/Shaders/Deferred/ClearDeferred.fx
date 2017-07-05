#include "DeferredHeader.fxh"

bool clearDepth = true;

struct VertexShaderInput
{
    float3 Position : POSITION0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
};



VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;
    output.Position = float4(input.Position,1);
    return output;
}

PixelShaderOutput ClearBuffer(VertexShaderOutputToPS input)
{
	PixelShaderOutput output = (PixelShaderOutput)0;
	
	float4 empty = float4(0,0,0,1);
	output.Color = empty;
	output.SGR = 0;
	output.Tangent.rgb = 0;
	output.Tangent.a = 0;
	
	if(clearDepth)
	{
		output.Depth = -1;
		output.Depth.a = 1;
	}
	
	return output;
}

technique Clear
{
	pass Pass1
	{
		ZEnable = true;
		ZWriteEnable=true;
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 ClearBuffer();
	}
}