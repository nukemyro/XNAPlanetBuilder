

sampler screen : register(s0);

texture depthMap;

sampler2D DepthMap = sampler_state
{
	Texture = <depthMap>;
	MinFilter = Point;
	MagFilter = Point;
	MipFilter = None;
};

float camMin;
float camMax;
float fogRange;
float fogDistance;
float4 fogColor;
float fogMinThickness = .999f;
float fogMaxThickness = 0.0f;

float baseHeight = 0;
float height = 10;

struct PS_INPUT 
{
	float2 TexCoord	: TEXCOORD0;
};

float4 FogPS(PS_INPUT Input) : COLOR0 
{
	float depth = 1-tex2D(DepthMap,Input.TexCoord);
	float fSceneZ = ( -camMin * ((camMax /(camMax - camMin))) ) / ( depth - ((camMax /(camMax - camMin))));
	float fFogFactor = clamp(saturate( ( fSceneZ - fogDistance ) / fogRange ),fogMaxThickness,fogMinThickness);

	return lerp(tex2D(screen, Input.TexCoord),fogColor,saturate(fFogFactor));
}

technique Fog 
{
	pass P0
	{
		PixelShader = compile ps_2_0 FogPS();
	}
}