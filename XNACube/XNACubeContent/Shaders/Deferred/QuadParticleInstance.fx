#include "DeferredHeader.fxh"

// Global Variables
float4x4 worlds[60] : WorldViewProjection;
float4x4 vp :ViewProjection;

float3 color = 1;
float time;

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
	AddressU = Mirror;
	AddressV = Mirror;
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

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TexCoord : TexCoord0;
    float3 Normal : Normal0;
	float3x3 Tangent: Tangent0;
	float4 SPos : TexCoord1;
};

struct VertexShaderInput
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
	float2 TexCoord : TEXCOORD0;
	float3 Tangent : TANGENT0;
	float4 Extras : POSITION1;
};



VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
	VertexShaderOutput output = (VertexShaderOutput)0;

	float4x4 world = worlds[input.Extras.x];
 
    output.Position = mul(mul(input.Position, world),vp);
    output.TexCoord = input.TexCoord;
        
    output.Normal = normalize(mul(input.Normal,world));
	output.Tangent[0] = mul(input.Tangent,world);
	output.Tangent[1] = mul(cross(input.Tangent,input.Normal),world);
	output.Tangent[2] = output.Normal;    
	
	output.SPos = output.Position;
    
    return output;
}
VertexShaderOutput VertexShaderFunctionH(VertexShaderInput input,VertexShaderInput2 input2)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float4x4 world = transpose(input2.instanceTransform);
	
	output.Position = mul(mul(input.Position, world),vp);
    output.TexCoord = input.TexCoord;
        
    output.Normal = mul(input.Normal,world);
	output.Tangent[0] = mul(input.Tangent,world);
	output.Tangent[1] = mul(cross(input.Tangent,input.Normal),world);
	output.Tangent[2] = normalize(output.Normal);

	output.SPos = output.Position;
    
    return output;
}

PixelShaderOutput PSBasicTexture(VertexShaderOutput input) : COLOR0
{
	PixelShaderOutput output = (PixelShaderOutput)0;
	
	output.Color = tex2D(textureSample,input.TexCoord) * float4(color,1);
	
	// Get value in the range of -1 to 1
	float3 n = 2.0f * tex2D(BumpMapSampler,input.TexCoord) - 1.0f;
	
	// Multiply by the tangent matrix
	n = mul(n,input.Tangent);	

	// Generate normal values
	output.Tangent.rgb = .5f  * (normalize(n) + 1.0f);
	output.Tangent.a = 1;
	
	// Write out SGR
	output.SGR.r = tex2D(SpecularSampler,input.TexCoord + float2(0,time * .05));
	output.SGR.g = tex2D(GlowSampler,input.TexCoord);
	output.SGR.b = tex2D(ReflectionMap,input.TexCoord);
	output.SGR.w = 0;
	
	// Depth
	if(output.Color.a == 1)
		output.Depth.r = 1-(input.SPos.z/input.SPos.w); // Flip to keep accuracy away from floating point issues.

	output.Depth.a = 1;
	
	return output; 
}

technique BasicTexture
{
    pass Pass1
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
}

technique BasicTextureH
{
    pass Pass1
    {
        VertexShader = compile vs_3_0 VertexShaderFunctionH();
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
}
