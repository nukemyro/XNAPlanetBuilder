uniform extern texture sceneMap;
sampler screen = sampler_state 
{
    texture = <sceneMap>;    
	MinFilter = Point;
	MagFilter = Point;
};

struct PS_INPUT 
{
	float2 TexCoord	: TEXCOORD0;
};

float4 Invert(PS_INPUT Input) : COLOR0 
{
	float4 col = 0;

	col.r = tex2D(screen, Input.TexCoord).r * 10;

	return col;
}

technique RenderDepth 
{
	pass P0
	{
		PixelShader = compile ps_2_0 Invert();
	}
}