//uniform extern texture g_texBlit;

sampler g_sampBlit : register(s0);
/* = sampler_state
{
	texture = (g_texBlit);
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};*/

float2 halfPixel;

float g_BlurAmount = 1.0f; // Kernel size multiplier
static const int g_cKernelSize = 13;

float aTexelKernel[g_cKernelSize] = { -6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6, };

static const float aBlurWeights[g_cKernelSize] = 
{
  0.002216,0.008764,0.026995,0.064759,0.120985,0.176033,
  0.199471,
  0.176033,0.120985,0.064759,0.026995,0.008764,0.002216
};

float4 BlurPS(float2 vec2TC : TEXCOORD0, uniform bool bHorizontal) : COLOR
{
	float4 clrOrg = tex2D(g_sampBlit,vec2TC - halfPixel);
    float4 clrBlurred = 0;
	float2 vec2TexCoord;

    for (int i=0; i<g_cKernelSize; i++)
    {		
		vec2TexCoord = vec2TC - halfPixel;
		float fOffset = (aTexelKernel[i] / 256.0f) * g_BlurAmount;
		if (bHorizontal)
			vec2TexCoord.x += fOffset;
		else 
			vec2TexCoord.y += fOffset;

        clrBlurred += tex2D(g_sampBlit,vec2TexCoord) * aBlurWeights[i];
	}
    return clrBlurred;
}

technique BlurH
{
	pass pHorz
	{
		PixelShader = compile ps_2_0 BlurPS(true);
	}	
}
technique BlurV
{
	pass pVert
	{
		PixelShader = compile ps_2_0 BlurPS(false);
	}
}