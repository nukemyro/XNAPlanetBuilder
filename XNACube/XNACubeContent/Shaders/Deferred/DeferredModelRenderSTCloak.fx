#include "DeferredHeader.fxh"
#include "..\ShaderTools.fxh"

// Global Variables
float4x4 world : WORLD;
float4x4 wvp : WorldViewProjection;
float4x4 vp;
float4x4 invViewProj;

float3 color = 1;
float3 CameraPos : CAMERAPOSITION;

float cloak = 0;
float time;

texture bg;

sampler2D BG = sampler_state
{
	Texture = <bg>;
	AddressU = clamp;
	AddressV = clamp;
};

texture cubeMap;
samplerCUBE CubeMap = sampler_state 
{ 
    texture = <cubeMap> ;     
};

float4 CubeMapLookup(float3 CubeTexcoord)
{    
    return texCUBE(CubeMap, CubeTexcoord);
}

texture noiseMat;
sampler noiseSample = sampler_state
{
    Texture = <noiseMat>; 
	AddressU = mirror;
	AddressV = mirror;   
	MipFilter = LINEAR; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
};

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

float3 etas = { 0.80, 0.82, 0.84 };

// wavelength colors
const float4 colors[3] = {
    { 1, 0, 0, 0 },
    { 0, 1, 0, 0 },
    { 0, 0, 1, 0 },
};

float3 refract2( float3 I, float3 N, float eta)
{
	float IdotN = dot(I, N);
	float k = 1 - eta*eta*(1 - IdotN*IdotN);

	return eta*I - (eta*IdotN + sqrt(k))*N;
}

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
	float3 ViewDirection: TEXCOORD2; 
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput)0;

	float x = cos(input.Position.x * time);
	float y = cos(input.Position.y * time);
	float z = cos(input.Position.z * time);
	float4 mod = saturate(((float4(input.Normal,1) * ((x+y+z)/3)) * .1));
	
	float3 size = float3(x,y,z); 

	size = cos(input.Position.xyz * (time * .5f));
	
	
	mod = mul(size,mul(input.Normal * 2,wvp));
	
	if(cloak < .5)
		mod *= cloak;
	else
		mod *= (1 - cloak);

	//output.Position = mul(input.Position, wvp) - (mul(size, mul(input.Normal, wvp)));
	
	output.Position = mul(input.Position, wvp) - mod;
	
	output.TexCoord = input.TexCoord;
        
    output.Normal = mul(input.Normal - mod,world);
	output.Tangent[0] = mul(input.Tangent,world);
	output.Tangent[1] = mul(cross(input.Tangent,output.Normal),world);
	output.Tangent[2] = normalize(output.Normal);

	output.ViewDirection = normalize(CameraPos-mul(input.Position, world));

	//for(int i=0; i<3; i++) 
    //    output.RefractRGB[i] = refract2(ViewDirection, output.Normal, etas[i]);
	
	output.SPos = output.Position;
    
    return output;
}

PixelShaderOutput PSBasicTexture(VertexShaderOutput input) : COLOR0
{
	PixelShaderOutput output = (PixelShaderOutput)0;
	float3 RefractRGB[3];

	float2 tc = MoveInCircle(input.TexCoord,time,.1f);
	float3 nml = lerp((2.0f * tex2D(noiseSample,tc) - 1.0f) * 50 ,1,cloak);

	float4 refract = 0;

	float4 tx;
	tx = input.SPos;
	
	//tx.w = 1;
	//tx = mul(tx,invViewProj);
	//tx /= tx.w;
	
    for(int c=0;c<3;c++)
	{
		RefractRGB[c] = refract2(input.ViewDirection, input.Normal * nml, etas[c]);
		//RefractRGB[c] = refract2(tx.xyz, input.Normal * nml, etas[c]);
		refract += tex2D(BG,tx.xy) * colors[c];
		
        //refract += CubeMapLookup(RefractRGB[c]) * colors[c];
	}	

	float2 texCoord = 0.0125 * (float2(input.SPos.x,-input.SPos.y) + 8.0f);
	refract = tex2D(BG,texCoord);
    
	float4 col = tex2D(textureSample,input.TexCoord) * float4(color,1);
    output.Color = lerp(col,refract * float4(color,1),cloak);

	//output.Color = tex2D(noiseSample,tc);

	float3 n = 2.0f * tex2D(BumpMapSampler,input.TexCoord) - 1.0f;
	
	n = mul(n,input.Tangent);	

	output.Tangent.rgb= .5f  * (normalize(n) + 1.0f) ;
	output.Tangent.a = 1;
	
	output.SGR.r = lerp(tex2D(SpecularSampler,input.TexCoord),1,cloak);
	output.SGR.g = lerp(output.Color.a,1,cloak);
	output.SGR.b = lerp(1,tex2D(ReflectionMap,input.TexCoord),cloak);
	output.SGR.w = cloak;

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
