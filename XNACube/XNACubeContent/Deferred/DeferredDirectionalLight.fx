#include "DeferredHeader.fxh"

float4x4 viewProjectionInv;
float4x4 lightViewProjection;

bool CastShadow;

//direction of the light
float3 lightDirection;

float3 cameraPosition; 

float power = 1;

//color of the light 
float3 Color; 

float shadowMod = .0000005f;

// normals, and specularPower in the alpha channel
texture normalMap;
texture depthMap;
texture shadowMap;

sampler normalSampler = sampler_state
{
    Texture = (normalMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};
sampler depthSampler = sampler_state
{
    Texture = (depthMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};
sampler shadowSampler = sampler_state
{
    Texture = (shadowMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};

texture sgrMap;
sampler SGRSampler = sampler_state
{
    Texture = (sgrMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

struct VertexShaderInput
{
    float3 Position : POSITION0;
    float2 texCoord : TEXCOORD0;
};

VertexShaderOutputToPS VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutputToPS output = (VertexShaderOutputToPS)0;
    output.Position = float4(input.Position,1);
    output.texCoord = input.texCoord - halfPixel;
    return output;
}

float4 DirectionalLightPS(VertexShaderOutputToPS input) : COLOR0
{
	//input.texCoord -= halfPixel;	
    float4 normalData = tex2D(normalSampler,input.texCoord);
    float3 normal = 2.0f * normalData.xyz - 1.0f;
    
    float depth = 1-(tex2D(depthSampler, input.texCoord).r);
    
    //create screen position
	float4 screenPos;
	screenPos.x = input.texCoord.x*2.0f-1.0f;
	screenPos.y = -(input.texCoord.y*2.0f-1.0f);
	
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
	/*float mod = .00000045f;
	//mod = .0001;
	//mod = .0000015f;
	mod = .00000033f;
	mod = .0000005f;*/

	realDistanceToLight -= shadowMod;
	
	#ifdef XBOX
	bool shadowCondition = distanceStoredInDepthMap >= realDistanceToLight;
    #else
	bool shadowCondition = distanceStoredInDepthMap <= realDistanceToLight;
	#endif
    //surface-to-light vector
    float3 lightVector = normalize(-lightDirection);

    //compute diffuse light
    float NdL = saturate(dot(normal,lightVector));
    float3 diffuseLight = (NdL * Color.rgb) * power;
    
    float shading = .5;	
	if(!CastShadow)
		shadowCondition = false;
		
	if (!shadowCondition)		
		shading = 1;

	//reflection vector
    float3 reflectionVector = normalize(reflect(-lightVector, normal));

	//camera-to-surface vector
    float3 directionToCamera = normalize(cameraPosition - input.ScreenPosition);

	float4 sgr = tex2D(SGRSampler, input.texCoord);
    
    float3 Half = normalize(reflectionVector + normalize(directionToCamera));	
	float specular = pow(saturate(dot(normalData,Half)),25) * sgr.r;

	diffuseLight += (specular * power);
    
    //output the two lights
    return float4(diffuseLight.rgb, 1) * shading;
}

technique DirectionalLight
{
	pass Pass1
	{
		VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader = compile ps_3_0 DirectionalLightPS();
	}
}