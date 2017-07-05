float4x4 viewProjectionInv;
float4x4 lightViewProjection;

bool CastShadow;
float shadowMod = .0000005f;

//sampler screen : register(s0);

float intensity;

texture depthMap;
sampler depthSampler = sampler_state
{
	texture = <depthMap>;
	AddressU = CLAMP;
    AddressV = CLAMP;
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};

texture shadowMap;
sampler shadowSampler = sampler_state
{
	texture = <shadowMap>;
	AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
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
	float depth = 1-(tex2D(depthSampler, Input.TexCoord).r);

	//create screen position
	float4 screenPos;
	screenPos.x = Input.TexCoord.x*2.0f-1.0f;
	screenPos.y = -(Input.TexCoord.y*2.0f-1.0f);
	
	screenPos.z = depth;
	screenPos.w = 1.0f;
	
	float4 worldPos = mul(screenPos, viewProjectionInv);
	worldPos /= worldPos.w;
	
	//find screen position as seen by the light
	float4 lightScreenPos = mul(worldPos, lightViewProjection);
	lightScreenPos /= lightScreenPos.w;
	
	//find sample position in shadow map
	float2 lightSamplePos;
	lightSamplePos.x = lightScreenPos.x/2.0f+0.5f;
	lightSamplePos.y = (-lightScreenPos.y/2.0f+0.5f);
	
	//determine shadowing criteria
	float realDistanceToLight = lightScreenPos.z;	
	float distanceStoredInDepthMap = 1-tex2D(shadowSampler, lightSamplePos).r;	
	
	realDistanceToLight -= shadowMod;
	
	#ifdef XBOX
	bool shadowCondition = distanceStoredInDepthMap >= realDistanceToLight;
    #else
	bool shadowCondition = distanceStoredInDepthMap <= realDistanceToLight;
	#endif

	if(!CastShadow)
		shadowCondition = false;
		
	if (!shadowCondition)		
		return float4(1 * intensity, 0, 0, 1);
	else
		return 0;
}

technique SSSM 
{
	pass P0
	{
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 Render();
	}
}