#include "..\Deferred\DeferredHeader.fxh"

float4x4 world : World;
float4x4 wvp : WorldViewProjection;

float4 clipPlane = 0;

float3 EyePosition;

float2 sqrt = 1024;
float mod = 1024;
float maxHeight = 30;

// Terrain Textures.
texture  LayerMap0;
texture  LayerMap1;
texture  LayerMap2;
texture  LayerMap3;

// Terrain Normals for above texture.
texture BumpMap0;
texture BumpMap1;
texture BumpMap2;
texture BumpMap3;

// Normal samplers
sampler BumpMap0Sampler = sampler_state
{
	Texture = <BumpMap0>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = mirror;
	AddressV = mirror;
};

sampler BumpMap1Sampler = sampler_state
{
	Texture = <BumpMap1>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = mirror;
	AddressV = mirror;
};

sampler BumpMap2Sampler = sampler_state
{
	Texture = <BumpMap2>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = mirror;
	AddressV = mirror;
};

sampler BumpMap3Sampler = sampler_state
{
	Texture = <BumpMap3>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = mirror;
	AddressV = mirror;
};

// Texture Samplers
sampler LayerMap0Sampler = sampler_state
{
    Texture   = <LayerMap0>;
    MinFilter = LINEAR; 
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler LayerMap1Sampler = sampler_state
{
	Texture   = <LayerMap1>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
    AddressV  = WRAP;
};

sampler LayerMap2Sampler = sampler_state
{
    Texture   = <LayerMap2>;
    MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
    AddressV  = WRAP;
};
sampler LayerMap3Sampler = sampler_state
{
    Texture   = <LayerMap3>;
    MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = WRAP;
    AddressV  = WRAP;
};


texture heightMap;

sampler heightMapSampler = sampler_state
{
	Texture = <heightMap>;  
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

struct VertexShaderInput
{
    float4 Position : POSITION0;
	float3 Color : Color0;    
};

struct VertexShaderOutput
{
	float4 Position         : POSITION0;	
    float2 TexCoord    : TEXCOORD0;      
    float4 weight : TEXCOORD1;
    float3x3 Tangent : TEXCOORD4;
    float4 SPos : TEXCOORD3; 	
	float4 clipDistances : TEXCOORD2;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float y = 0;
	
	// Generate Normals
	float3 lN = input.Position.xyz;
	float3 bN = input.Position.xyz;
		
	lN.x += 1;
	bN.z -= 1;
	
	y = tex2Dlod(heightMapSampler,float4(lN.xz/sqrt,0,0)).r * maxHeight;
	lN.y = y;
	
	y = tex2Dlod(heightMapSampler,float4(bN.xz/sqrt,0,0)).r * maxHeight;
	bN.y = y;
	
	y = tex2Dlod(heightMapSampler,float4(input.Position.xz/sqrt,0,0)).r * maxHeight;
	input.Position.y = y;
	
	// Texture Weights
	output.weight.x = saturate(1 - (abs(y) / 8));
	output.weight.y = saturate(1 - (abs(y - 10) / 10));
	output.weight.z = saturate(1 - (abs(y - 23) / 10));
	output.weight.w = saturate(1 - (abs(y - 30) / 8));	
	
	float totW = output.weight.x + output.weight.y + output.weight.z + output.weight.w;	
	output.weight.x /= totW;
	output.weight.y /= totW;
	output.weight.z /= totW;
	output.weight.w /= totW;
	
	float3 side1 = input.Position.xyz - lN;
	float3 side2 = input.Position.xyz - bN;
	float3 normal = cross(side1,side2);
	
	// Generate Tangents	
	float3 tL = input.Position.xyz;
	
	tL.x -= 2;
	y = tex2Dlod(heightMapSampler,float4(tL.xz/sqrt,0,0)).r * maxHeight;
	tL.y = y;
	
	float3 Tangent = normalize(tL-lN);
	
	output.Tangent[0] = mul(Tangent,world);
	output.Tangent[1] = mul(cross(Tangent,normal),world);
	output.Tangent[2] = mul(normal,world);
	
	output.Position = mul(input.Position, wvp);
    
    output.TexCoord = (input.Position.xz/mod) * 64;
	
	output.SPos = output.Position;
	//output.p = mul(input.Position, world);

	output.clipDistances.x = dot(output.Position, clipPlane);
	output.clipDistances.y = 0;
	output.clipDistances.z = 0;
	output.clipDistances.w = 0;

    return output;
}

PixelShaderOutput PixelShaderFunction(VertexShaderOutput input)
{
	PixelShaderOutput output = (PixelShaderOutput)0;

	clip(input.clipDistances);
	
	float3 Normal;
	float4x4 norm;
	
	norm[0] = tex2D(BumpMap0Sampler, input.TexCoord);
    norm[1] = tex2D(BumpMap1Sampler, input.TexCoord);
    norm[2] = tex2D(BumpMap2Sampler, input.TexCoord);
    norm[3] = tex2D(BumpMap3Sampler, input.TexCoord);

	Normal = mul(input.weight,norm);
    Normal = (2 * Normal - 1);
	
	float4 Col;		
	float4x4 col;	
	
	col[0] = tex2D(LayerMap0Sampler, input.TexCoord);
    col[1] = tex2D(LayerMap1Sampler, input.TexCoord);
    col[2] = tex2D(LayerMap2Sampler, input.TexCoord);
    col[3] = tex2D(LayerMap3Sampler, input.TexCoord);

    Col = mul(input.weight,col);

	output.Color = Col;
	
	Normal = mul(Normal,input.Tangent);	
	output.Tangent.rgb = .5f  * (normalize(Normal) + 1.0f);
	output.Tangent.a = 1;
		
	output.SGR = 0;
	
	output.Depth.r = 1-(input.SPos.z/input.SPos.w);
	output.Depth.a = 1;
	
	
	return output;	
}

technique GeoClipMap
{
    pass Pass1
    {
		FILLMODE = WIREFRAME;
		CULLMODE = NONE;		
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();
    }
}
