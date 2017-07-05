#include "DeferredHeader.fxh"

// Global Variables
float4x4 world : WorldViewProjection;
float4x4 vp : ViewProjection;

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

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	//output.Position = mul(mul(input.Position, world),vp);
	output.Position = mul(input.Position,vp);
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
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
}


