uniform extern texture sceneMap;
sampler screen = sampler_state 
{
    texture = <sceneMap>;    
};

texture buff2;

sampler buff2Sampler = sampler_state
{
	texture = <buff2>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

struct PS_INPUT 
{
	float2 TexCoord	: TEXCOORD0;
};

float4 Render(PS_INPUT Input) : COLOR0 
{
	float col = tex2D(screen, Input.TexCoord).r;
	float col2 = tex2D(buff2Sampler, Input.TexCoord).r;

	if(col > col2)
		return col;
	else
		return col2;
}

technique PostInvert 
{
	pass P0
	{
		PixelShader = compile ps_2_0 Render();
	}
}