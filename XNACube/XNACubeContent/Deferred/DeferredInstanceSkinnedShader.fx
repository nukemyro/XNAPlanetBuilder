#include "DeferredHeader.fxh"

float4x4 Bones[MaxBones];


// Global Variables
float4x4 worlds[60] : WorldViewProjection;
float4x4 vp :ViewProjection;

float3 color = 1;

texture textureMat;
sampler textureSample = sampler_state 
{
    texture = <textureMat>;    
};

texture BumpMap;
sampler BumpMapSampler = sampler_state
{
	Texture = <BumpMap>;	
};

texture specularMap;
sampler SpecularSampler = sampler_state
{
	Texture = <specularMap>;	
};

texture glowMap;
sampler GlowSampler = sampler_state
{
	Texture = <glowMap>;	
};

texture reflectionMap;
sampler ReflectionMap = sampler_state
{
	Texture = <reflectionMap>;	
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TexCoord : TexCoord0;
    float3 Normal : Normal0;
	float3x3 Tangent: Tangent0;
	float4 SPos : TexCoord1;
	float4 color : Color0;
};

struct VertexShaderInput
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
	float2 TexCoord : TEXCOORD0;
	float3 Tangent : TANGENT0;
	float4 Extras : POSITION1;
	float4 BoneIndices : BLENDINDICES0;
    float4 BoneWeights : BLENDWEIGHT0;
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

	output.color = 1;
    
    return output;
}
VertexShaderOutput VertexShaderFunctionH(VertexShaderInput input,VertexShaderInputSkinned2 input2)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float4x4 world = transpose(input2.instanceTransform);
	
	float4x4 skinTransform = 0;
    
    skinTransform += Bones[input.BoneIndices.x] * input.BoneWeights.x;
    skinTransform += Bones[input.BoneIndices.y] * input.BoneWeights.y;
    skinTransform += Bones[input.BoneIndices.z] * input.BoneWeights.z;
    skinTransform += Bones[input.BoneIndices.w] * input.BoneWeights.w;

	float4 position = mul(input.Position, skinTransform);
    
    output.Position = mul(mul(position, world),vp);
    output.TexCoord = input.TexCoord;
        
    output.Normal = normalize(mul(input.Normal,world));
	output.Tangent[0] = mul(input.Tangent,world);
	output.Tangent[1] = mul(cross(input.Tangent,input.Normal),world);
	output.Tangent[2] = output.Normal;    
	
	output.SPos = output.Position;

	output.color = input2.extras;
    
    return output;
}

PixelShaderOutput PSBasicTexture(VertexShaderOutput input) : COLOR0
{
	PixelShaderOutput output = (PixelShaderOutput)0;
	
	output.Color = tex2D(textureSample,input.TexCoord)  * float4(color,1) * input.color;
	
	float3 n = 2.0f * tex2D(BumpMapSampler,input.TexCoord) - 1.0f;
	
	n = mul(n,input.Tangent);	
	output.Tangent.rgb = .5f  * (normalize(n) + 1.0f);
	output.Tangent.a = 1;
	
	output.SGR.r = tex2D(SpecularSampler,input.TexCoord);
	output.SGR.g = tex2D(GlowSampler,input.TexCoord);
	output.SGR.b = tex2D(ReflectionMap,input.TexCoord);
	output.SGR.w = 0;
	
	output.Depth.r = 1-(input.SPos.z/input.SPos.w);
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
