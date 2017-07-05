#include "PPVertexShader.fx"
#include "../ShaderTools.fxh"

// Water pixel shader
// Based on the pixel shader by Wojciech Toman 2009
//
// Written by C.Humphrey
// http://www.xna-uk.net/blogs/randomchaos
//

float4x4 InvertViewProjection; 	

float2 halfPixel;

texture lightMap;
sampler lightSampler = sampler_state
{
    Texture = (lightMap);
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;    
};

texture sceneNormal;
sampler sceneNormalSampler = sampler_state
{
    Texture = (sceneNormal);
	AddressU  = clamp; 
    AddressV  = clamp;
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;    
};

texture caustics;
sampler causticsSampler = sampler_state
{
    Texture = (caustics);
	AddressU  = mirror; 
    AddressV  = mirror;
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;    
};

texture heightMapTex;
sampler heightMap = sampler_state
{
    Texture   = <heightMapTex>;    
    AddressU  = mirror; 
    AddressV  = mirror;
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};
texture sgrMap;
sampler SGRSampler = sampler_state
{
    Texture = (sgrMap);  
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;  
};
texture backBufferMapTex;
sampler backBufferMap = sampler_state
{
    Texture   = <backBufferMapTex>;  
	AddressU  = clamp; 
    AddressV  = clamp;
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT; 
};

texture positionMapTex;
sampler positionMap = sampler_state
{
    Texture   = <positionMapTex>;
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;    
};

texture normalMapTex;
sampler normalMap = sampler_state
{
    Texture   = <normalMapTex>;
    AddressU  = mirror; 
    AddressV  = mirror;
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};
texture foamMapTex;
sampler foamMap = sampler_state
{
    Texture   = <foamMapTex>;
    AddressU  = mirror; 
    AddressV  = mirror;
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};

texture reflectionMapTex;
sampler reflectionMap = sampler_state
{
    Texture   = <reflectionMapTex>;    
	MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;   
};

// VertexShader results
struct VertexOutput
{
	float4 position : POSITION0;
	float2 texCoord : TEXCOORD0;
};

struct PS_OUTPUT
{
	float4 diffuse: COLOR0;
	float4 normal: COLOR1;
	float4 position: COLOR2;
};

float fogMinThickness = .999f;
float fogMaxThickness = 0.0f;
float fogDistance = 10;
float fogRange = 50;
float camMin;
float camMax;
float seaFloor = -30.0f;

float4 WaterPS(VertexOutput IN): COLOR0
{
	
	IN.texCoord -= halfPixel;
	float3 color2 = tex2D(backBufferMap, IN.texCoord).rgb;
	float3 color = color2;
	
	float3 bigDepthColourl = bigDepthColour * tex2D(lightSampler,IN.texCoord);
	float3 depthColourl = depthColour * tex2D(lightSampler,IN.texCoord);
	
	float3 position;
	
	float depthVal = 1- tex2D(positionMap, IN.texCoord).r;	        
		
	float4 pos;
	
	pos.x =   IN.texCoord.x * 2.0f - 1.0f;
	pos.y = -(IN.texCoord.y * 2.0f - 1.0f);
	pos.z = depthVal;
	pos.w = 1.0f;	        
	
	pos = mul(pos, InvertViewProjection);
	pos /= pos.w;		
	
	position = pos.xyz;
	
	float level = waterLevel;
	float depth = 0.0f;

	
	float3 eyeVec = position - cameraPos;
	float diff = level - position.y;
	float cameraDepth = cameraPos.y - position.y;

	// Find intersection with water surface
	float3 eyeVecNorm = normalize(eyeVec);
	float t = (level - cameraPos.y) / eyeVecNorm.y;
	float3 surfacePoint = cameraPos + eyeVecNorm * t;

	eyeVecNorm = normalize(eyeVecNorm);
	
	float2 texCoord;
	for(int i = 0; i < 10; ++i)
	{
		texCoord = (surfacePoint.xz + eyeVecNorm.xz * 1.0f) * scale + timer * 0.01f * wind;
			
		float bias = tex2D(heightMap, texCoord).r;
	
		bias *= 0.1f;
		level += bias * maxAmplitude;
		t = (level - cameraPos.y) / eyeVecNorm.y;
		surfacePoint = cameraPos + eyeVecNorm * t;
	}

	depth = length(position - surfacePoint);
	float depth2 = surfacePoint.y - position.y;
	
	eyeVecNorm = normalize(cameraPos - surfacePoint);
	
	
	// If we are underwater let's leave out complex computations
	if(level >= cameraPos.y)
	{	
		float fSceneZ = ( -camMin * ((camMax /(camMax - camMin))) ) / ( depthVal - ((camMax /(camMax - camMin))));
		float fFogFactor = clamp(saturate( ( fSceneZ - fogDistance ) / fogRange ),fogMaxThickness,fogMinThickness);

		float mod = .05f;
		float2 uv = (position.xz * mod);

		float4 sceneNormal = tex2D(sceneNormalSampler,IN.texCoord);
		float3 n = 2.0f * sceneNormal.rgb -1.0f;
		float d = saturate(dot(n,normalize(lightDir)));

		float caustic = (tex2D(causticsSampler,uv).r * 2);

		if(position.y < level)
			color = color2 * lerp(depthColourl,bigDepthColourl,saturate(fFogFactor))  * caustic;
		else
			color = color2 * lerp(depthColourl,bigDepthColourl,saturate(fFogFactor));

		//color = depthVal > .8f;//position.y < level;
		//color = position.y/(seaFloor);
	}
	else
	{
		if(position.y < level)
		{
		    float3 myNormal = float3(0,1,0);
			
			// Bump Mapping
			texCoord = surfacePoint.xz * 1.6 + wind * timer * .016;
			
			float3x3 tangentFrame = compute_tangent_frame(myNormal, eyeVecNorm, texCoord);
			float3 normal0a = normalize(mul(2.0f * tex2D(normalMap, texCoord) - 1.0f, tangentFrame));

			texCoord = surfacePoint.xz * 0.8 + wind * timer * 0.008;
			tangentFrame = compute_tangent_frame(myNormal, eyeVecNorm, texCoord);
			float3 normal1a = normalize(mul(2.0f * tex2D(normalMap, texCoord) - 1.0f, tangentFrame));
			
			texCoord = surfacePoint.xz * 0.4 + wind * timer * 0.004;
			tangentFrame = compute_tangent_frame(myNormal, eyeVecNorm, texCoord);
			float3 normal2a = normalize(mul(2.0f * tex2D(normalMap, texCoord) - 1.0f, tangentFrame));
			
			texCoord = surfacePoint.xz * 0.1 + wind * timer * 0.012;
			tangentFrame = compute_tangent_frame(myNormal, eyeVecNorm, texCoord);
			float3 normal3a = normalize(mul(2.0f * tex2D(normalMap, texCoord) - 1.0f, tangentFrame));
			
			float3 normal = normalize(normal0a * normalModifier.x + normal1a * normalModifier.y +
									  normal2a * normalModifier.z + normal3a * normalModifier.w);
			
			// Refraction.
			texCoord = IN.texCoord;
			texCoord.x += sin((timer * Viscosity) + 3.0f * abs(position.y)) * (refractionScale * min(depth2, 1.0f)) * ((1-depthVal)*255);
			float3 refraction = tex2D(backBufferMap, texCoord).rgb;
			
			float3 depthN = depth * fadeSpeed;
			float3 waterCol = saturate(length(sunColor) / sunScale);
			refraction = saturate(lerp(lerp(refraction, depthColourl * waterCol, saturate(depthN / visibility)),
							  bigDepthColourl * waterCol, saturate(depth2 / extinction)));
			
			// Reflection	
					
			float2 rT = texCoord;
			rT.x *= -1;
			
			rT.x = rT.x + displace * normal.x;
			rT.y = rT.y + displace * normal.z;
			float4 rCol = tex2D(reflectionMap, rT);
			rCol *= tex2D(lightSampler,texCoord) + (rCol * tex2D(SGRSampler,rT).g);
			float3 reflect = rCol;
			
			/*
			float4x4 matTextureProj = mul(matViewProj, matReflection) + tex2D(SGRSampler,matReflection).g;
				
			float3 waterPosition = surfacePoint.xyz;
			waterPosition.y -= (level - waterLevel);
			float4 texCoordProj = mul(float4(waterPosition, 1.0f), matTextureProj);
			
			float4 dPos;
			dPos.x = texCoordProj.x + displace * normal.x;
			dPos.z = texCoordProj.z + displace * normal.z;
			dPos.yw = texCoordProj.yw;
			texCoordProj = dPos;		
			
			float3 reflect = tex2Dproj(reflectionMap, texCoordProj) * tex2Dproj(lightSampler,texCoordProj);
			*/
			// Foam
			float foam = 0.0f;		

			texCoord = (surfacePoint.xz + eyeVecNorm.xz * 0.1) * 0.05 + timer * 0.01f * wind + sin(timer * 0.1 + position.x) * 0.0125;
			float2 texCoord2 = (surfacePoint.xz + eyeVecNorm.xz * 0.1) * 0.05 + timer * 0.02f * wind + sin(timer * 0.1 + position.z) * 0.0125;
			
			if(depth2 < foamExistence.x)
				foam = (tex2D(foamMap, texCoord) + tex2D(foamMap, texCoord2)) * 0.5f;				
			else 
				if(depth2 < foamExistence.y)
			{
				foam = lerp((tex2D(foamMap, texCoord) + tex2D(foamMap, texCoord2)) * 0.5f, 0.0f,
							 (depth2 - foamExistence.x) / (foamExistence.y - foamExistence.x));
				
			}
			foam *= tex2D(lightSampler,IN.texCoord)*2;
			
			// Specular			
			float fresnel = fresnelTerm(normal, eyeVecNorm);
			half3 specular = 0.0f;
			float3 Half = normalize(lightDir + eyeVecNorm);
			specular = pow(saturate(dot(normal,Half)),25) * shininess;
			//specular += pow(saturate(dot(myNormal,Half)),25) * shininess;
							  
			//color = refraction;// + specular;	
			color = lerp(refraction, reflect, fresnel);
			color = saturate(color + max(specular * (tex2D(lightSampler,IN.texCoord)*2), foam * sunColor));			
			//color = saturate(color + max(specular, foam * sunColor));			
			color = lerp(refraction, color, saturate(depth * shoreHardness));			

		}	
		if(position.y > level)
			color = color2;
	}
	
	

	return float4(color, 1.0f);
}

technique Water
{
	pass p0
    {       
		VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader  = compile ps_3_0 WaterPS();
    }
}