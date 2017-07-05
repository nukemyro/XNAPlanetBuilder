#include "PPVertexShader.fx"

float4 vecViewPort;
float2 halfPixel;

float2 samples[16] =
	{
		float2(0.355512, 	-0.709318),
		float2(0.534186, 	0.71511),
		float2(-0.87866, 	0.157139),
		float2(0.140679, 	-0.475516),
		float2(-0.0796121, 	0.158842),
		float2(-0.0759516, 	-0.101676),
		float2(0.12493, 	-0.0223423),
		float2(-0.0720074, 	0.243395),
		float2(-0.207641, 	0.414286),
		float2(-0.277332, 	-0.371262),
		float2(0.63864, 	-0.114214),
		float2(-0.184051, 	0.622119),
		float2(0.110007, 	-0.219486),
		float2(0.235085, 	0.314707),
		float2(-0.290012, 	0.0518654),
		float2(0.0975089, 	-0.329594)
	};

//depth
texture depthMap;
sampler depthSampler = sampler_state
{
    Texture = (depthMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};

texture NoiseTexture : NoiseTexture;
sampler2D NoiseMap = sampler_state
{
	Texture = <NoiseTexture>;
	AddressU = Wrap;
	AddressV = Wrap;
	AddressW = Wrap;
};

float4 SSAOPS(float2 UV :TEXCOORD0) : COLOR0
{
	
	
	UV -= halfPixel;
	
	float depth = tex2D(depthSampler, UV);
	float occ = 0.0;
	for (int i = 0; i < 16; i += 1 )
	{
		float2 curSample = samples[i];
		
		float2 texCoord = UV + i * samples[i] * vecViewPort.zw;
		float newdepth = tex2D(depthSampler, texCoord);
		
		float depthDif = (newdepth - depth);
				
		// Blur if samples are less than 10cm apart	and angle between their normals is less than about 10 deg
		if(newdepth > depth)		
			occ += 1.0 / ( 1 + ( pow(depthDif,3)  ) ); // 0.01;
	}
	
	// Average
	float unOcclusion = 1.0 - ( occ / 16.0 );
	
	// Only first component matters
	if(depth > .0002)
		return float4(unOcclusion, unOcclusion, unOcclusion, 1.0) * 1.0f;
	else
		return 1;
}

technique ssao
{
	pass p0
	{
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 SSAOPS();
	}
}

