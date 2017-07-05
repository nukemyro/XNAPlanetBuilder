#include "DeferredHeader.fxh"
#include "..\ShaderTools.fxh"

// Global Variables
float4x4 world : WORLD;
float4x4 wvp : WorldViewProjection;

float AmbientIntensity = 1;
float4 AmbientColor : AMBIENT = float4(0,0,0,1);

float3 LightDirection : Direction = float3(0,1,1);

float3 CameraPosition : CameraPosition; 

float cloudSpeed = .0025;
float cloudHeight = .005;
float cloudShadowIntensity = 1;

bool hasAtmos = true;

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

struct VertexShaderInput
{
    float4 Position : POSITION0;
	float2 TexCoord : TexCoord0;
	float3 Normal	: Normal0;
	float3 Tangent	: Tangent0;
};

texture CloudMap;
sampler CloudMapSampler = sampler_state
{
	texture = <CloudMap>;    
};


texture WaveMap;
sampler WaveMapSampler = sampler_state
{
	texture = <WaveMap>;    
};

texture AtmosMap;
sampler AtmosMapSampler = sampler_state
{
	texture = <AtmosMap>;    
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TexCoord : TexCoord0;
    float3 Normal : Normal0;
	float3x3 Tangent: Tangent0;
	float4 SPos : TexCoord1;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input,uniform float size)
{
    VertexShaderOutput output = (VertexShaderOutput)0;
    
    if(size != 0 && hasAtmos)
		output.Position = mul(input.Position, wvp) + (mul(size, mul(input.Normal, wvp)));
	else		
		output.Position = mul(input.Position, wvp);
		
    output.TexCoord = input.TexCoord;
        
    output.Normal = mul(input.Normal,world);
	output.Tangent[0] = mul(input.Tangent,world);
	output.Tangent[1] = mul(cross(input.Tangent,input.Normal),world);
	output.Tangent[2] = normalize(output.Normal);
	
	output.SPos = output.Position;
	
	
    return output;
}

PixelShaderOutput PSClouds(VertexShaderOutput input) : COLOR0
{
	PixelShaderOutput output = (PixelShaderOutput)0;
	
	float2 cloudCoord = RotateRight(input.TexCoord,timer*cloudSpeed);	
	float4 clouds = tex2D(CloudMapSampler,cloudCoord);	
		
	output.Color = pow(clouds,3);
	
	return output;

}
PixelShaderOutput PSBasicTexture(VertexShaderOutput input) : COLOR0
{
	PixelShaderOutput output = (PixelShaderOutput)0;
	
	output.Color = tex2D(textureSample,input.TexCoord);
		
	float3 n = 2.0f * tex2D(BumpMapSampler,input.TexCoord) - 1.0f ;
	float3 wn = (2 * (tex2D(WaveMapSampler,MoveInCircle(input.TexCoord,timer,.001) * 50))) - 1.0;
	float s = tex2D(SpecularSampler,input.TexCoord);
	
	n = mul(n,input.Tangent);	
	output.Tangent.rgb = .5f  * (normalize(n+(wn*s)) + 1.0f);
	output.Tangent.a = 1;
	
	output.SGR.r = s;
	output.SGR.g = tex2D(GlowSampler,input.TexCoord);
	output.SGR.b = tex2D(ReflectionMap,input.TexCoord);
	output.SGR.w = 0;
	
	output.Depth.r = 1-(input.SPos.z/input.SPos.w);
	output.Depth.a = 1;
	
	return output; 
}
PixelShaderOutput PSAtmoshpere(VertexShaderOutput input,uniform bool flip)
{
	PixelShaderOutput output = (PixelShaderOutput)0;
	
	if(!hasAtmos)
		return output;
	else
		{
		
		input.SPos.xy /= input.SPos.w;
		
		// Do light scatter...
		float4 atmos = tex2D(AtmosMapSampler,input.TexCoord);

		float3 regN = normalize(input.Normal);
		float3 Half = normalize(normalize(CameraPosition-input.SPos) + normalize(CameraPosition - input.SPos));	
		float specular = 0;
		
		// Was playing about to see if I could get a better scatter, worked a bit, but not 100%
		// Guess I will need to read up on how to do it properly :P
		float Diffuse = saturate(1-dot(normalize(LightDirection),-regN))*2;
			
		if(flip)
		{		
			specular = saturate(1-dot(regN,Half))*.125;
			atmos *= specular;
		}
		else
		{
			//specular = 1-saturate(1.125 + dot(regN,Half));
			specular =  1-saturate(1.1 + dot(regN,Half));
			atmos *= specular*.25;
		}
		
		output.Color = pow(atmos * Diffuse,1);
		//output.SGR.r = specular;
		
		return output;
	}
}

technique Deferred
{
    pass Pass1
    {
		AlphaBlendEnable = False;
		CullMode = CCW;
        VertexShader = compile vs_3_0 VertexShaderFunction(0);
        PixelShader = compile ps_3_0 PSBasicTexture();
    }
    pass Pass2
    {
		AlphaBlendEnable = True;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        
        VertexShader = compile vs_3_0 VertexShaderFunction(.02);
        PixelShader = compile ps_3_0 PSClouds();
    }
    
    pass Pass3
    {
		DestBlend = InvSrcAlpha;
        
        // No need to move it out again, can use the same geom as the clouds.		
		PixelShader = compile ps_3_0 PSAtmoshpere(true);
    }
    
    pass Pass4
    {
		// No need to move it out again, can use the same geom as the clouds.	
        VertexShader = compile vs_3_0 VertexShaderFunction(.05);	
		PixelShader = compile ps_3_0 PSAtmoshpere(false);		
		CullMode = CW;
    }
    
}
