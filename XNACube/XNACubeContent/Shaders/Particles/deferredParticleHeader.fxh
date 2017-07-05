struct PixelShaderOutput
{
	float4 Color	: COLOR0;	// Color	
	float4 Depth	: COLOR1;	// Depth map (R) Specular (G) Glow (B) and Reflection (A)
};

struct VertexShaderInput2
{
	float4x4 instanceTransform : BLENDWEIGHT;
	float4   extras : BLENDWEIGHT4;
};