#include "DeferredHeader.fxh"

// Global Variables
float4x4 world : WORLD;
float4x4 wvp : WorldViewProjection;

float3 color = 1;
float refract = 0;

texture textureMat;
sampler textureSample = sampler_state
{
    Texture = <textureMat>; 
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
	MipFilter = POINT; 
	MinFilter = POINT; 
	MagFilter = POINT; 
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
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TexCoord : TexCoord0;
    float3 Normal : Normal0;
	float3x3 Tangent: Tangent0;
	float4 SPos : TexCoord1;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

    output.Position = mul(input.Position, wvp);
	
	output.TexCoord = input.TexCoord;
        
    output.Normal = mul(input.Normal,world);
	output.Tangent[0] = mul(input.Tangent,world);
	output.Tangent[1] = mul(cross(input.Tangent,output.Normal),world);
	output.Tangent[2] = normalize(output.Normal);
	
	output.SPos = output.Position;
    
    return output;
}

PixelShaderOutput PSBasicTexture(VertexShaderOutput input) : COLOR0
{
	PixelShaderOutput output = (PixelShaderOutput)0;

	output.Color = tex2D(textureSample,input.TexCoord) * float4(color,1);

	float3 n = 2.0f * tex2D(BumpMapSampler,input.TexCoord) - 1.0f;
	
	n = mul(n,input.Tangent);	

	output.Tangent.rgb= .5f  * (normalize(n) + 1.0f) ;
	output.Tangent.a = 1;
	
	output.SGR.r = tex2D(SpecularSampler,input.TexCoord);
	output.SGR.g = output.Color.a;
	output.SGR.b = tex2D(ReflectionMap,input.TexCoord);
	output.SGR.w = refract;

	output.Depth.r = 1-(input.SPos.z/input.SPos.w);
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
