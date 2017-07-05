uniform extern texture sceneMap;
sampler screen = sampler_state 
{
    texture = <sceneMap>;    
};

struct PS_INPUT 
{
	float2 TexCoord	: TEXCOORD0;
};

float4 Render(PS_INPUT Input) : COLOR0 
{
	//Input.TexCoord.y = 1 - Input.TexCoord.y;
	float4 col = tex2D(screen, Input.TexCoord).bgra;
	return col;
}

technique PostInvert 
{
	pass P0
	{
		PixelShader = compile ps_2_0 Render();
	}
}