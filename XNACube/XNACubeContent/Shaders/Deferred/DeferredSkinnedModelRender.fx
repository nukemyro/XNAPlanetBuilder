#include "DeferredHeader.fxh"

// Global Variables
float4x4 world : WORLD;
float4x4 wvp : WorldViewProjection;
float4x4 vp : ViewProjection;

float4 clipPlane = 0;
float4x4 Bones[MaxBones];

float3 color = 1;

texture textureMat;

sampler textureSample = sampler_state 
{
    texture = <textureMat>; 
	AddressU = Wrap;
	AddressV = Wrap;   
	MipFilter = LINEAR; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
};

texture BumpMap;
sampler BumpMapSampler = sampler_state
{
	Texture = <BumpMap>;
	AddressU = Wrap;
	AddressV = Wrap;
	MipFilter = LINEAR; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
};

texture specularMap;
sampler SpecularSampler = sampler_state
{
	Texture = <specularMap>;	
	AddressU = Wrap;
	AddressV = Wrap;
	MipFilter = LINEAR; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
};

texture glowMap;
sampler GlowSampler = sampler_state
{
	Texture = <glowMap>;	
	AddressU = Wrap;
	AddressV = Wrap;
	MipFilter = LINEAR; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
};

texture reflectionMap;
sampler ReflectionMap = sampler_state
{
	Texture = <reflectionMap>;	
	AddressU = Wrap;
	AddressV = Wrap;
	MipFilter = LINEAR; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
};

struct VertexShaderInput
{
    float4 Position : POSITION0;
	float2 TexCoord : TexCoord0;
	float3 Normal	: Normal0;
	float3 Tangent	: Tangent0;
	float4 BoneIndices : BLENDINDICES0;
    float4 BoneWeights : BLENDWEIGHT0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TexCoord : TexCoord0;
    float3 Normal : Normal0;
	float3x3 Tangent: Tangent0;
	float4 SPos : TexCoord1;
	float4 clipDistances : TEXCOORD2;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float4x4 skinTransform = 0;
    
    skinTransform += Bones[input.BoneIndices.x] * input.BoneWeights.x;
    skinTransform += Bones[input.BoneIndices.y] * input.BoneWeights.y;
    skinTransform += Bones[input.BoneIndices.z] * input.BoneWeights.z;
    skinTransform += Bones[input.BoneIndices.w] * input.BoneWeights.w;

	float4 position = mul(input.Position, skinTransform);
    
    output.Position = mul(position,vp);
    output.TexCoord = input.TexCoord;
        
    output.Normal = mul(input.Normal,world);
	output.Tangent[0] = mul(input.Tangent,world);
	output.Tangent[1] = mul(cross(input.Tangent,input.Normal),world);
	output.Tangent[2] = normalize(output.Normal);
	
	output.SPos = output.Position;

	output.clipDistances.x = dot(output.Position,clipPlane);
	output.clipDistances.y = 0;
	output.clipDistances.z = 0;
	output.clipDistances.w = 0;
    
    return output;
}

PixelShaderOutput PSBasicTexture(VertexShaderOutput input) : COLOR0
{
	PixelShaderOutput output = (PixelShaderOutput)0;

	clip(input.clipDistances);
	
	output.Color = tex2D(textureSample,input.TexCoord) * float4(color,1);
		
	// Get value in the range of -1 to 1
	float3 n = 2.0f * tex2D(BumpMapSampler,input.TexCoord) - 1.0f;
	
	// Multiply by the tangent matrix
	n = mul(n,input.Tangent);	

	// Generate normal values
	output.Tangent.rgb = .5f  * (normalize(n) + 1.0f);
	output.Tangent.a = 1;
	
	// Write out SGR
	output.SGR.r = tex2D(SpecularSampler,input.TexCoord);
	output.SGR.g = tex2D(GlowSampler,input.TexCoord);
	output.SGR.b = tex2D(ReflectionMap,input.TexCoord);
	output.SGR.w = 0;
	
	// Depth
	output.Depth.r = 1-(input.SPos.z/input.SPos.w); // Flip to keep accuracy away from floating point issues.
	output.Depth.a = 1;
	
	return output;
}

technique Deferred
{
    pass Pass1
    {
		VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
}
