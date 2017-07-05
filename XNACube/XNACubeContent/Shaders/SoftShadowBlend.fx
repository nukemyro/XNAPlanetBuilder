uniform extern texture sceneMap;
sampler screen = sampler_state 
{
    texture = <sceneMap>;    
};

struct PS_INPUT 
{
	float2 TexCoord	: TEXCOORD0;
};

struct VertexShaderInput
{
    float3 Position : POSITION0;
	float2 TexCoord	: TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
	float2 TexCoord	: TEXCOORD0;
};



VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;
    output.Position = float4(input.Position,1);
	output.TexCoord = input.TexCoord;
    return output;
}

float4 Render(PS_INPUT Input) : COLOR0 
{
	return tex2D(screen, Input.TexCoord);
}

technique PostInvert 
{
	pass P0
	{
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 Render();
	}
}