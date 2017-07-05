

float fWaveFreq = 0.75f;
float fWaveAmp = 0.125f;
float timer	: Time;

// Wave
struct Wave {
	float	fFreq;	// Frequency (2PI / Wavelength)
	float	fAmp;	// Amplitude
	float	fPhase;	// Phase (Speed * 2PI / Wavelength)
	float2	vDir;	// Direction
};

#define NUMWAVES	3


float EvaluateWave( Wave w, float2 vPos, float fTime ) 
{
	return w.fAmp * (sin( dot( w.vDir, vPos ) * w.fFreq + fTime * w.fPhase) + cos( dot( w.vDir, vPos ) * w.fFreq + fTime * w.fPhase)) ;
}

// Water pixel shader
// Based on the pixel shader by Wojciech Toman 2009
//
// Written by C.Humphrey
// http://www.xna-uk.net/blogs/randomchaos
//

float4x4 InvertViewProjection; 	

texture lightMap;
sampler lightSampler = sampler_state
{
    Texture = (lightMap);    
};

texture heightMapTex;
sampler heightMap = sampler_state
{
    Texture   = <heightMapTex>;    
    AddressU  = mirror; 
    AddressV  = mirror;
};
texture sgrMap;
sampler SGRSampler = sampler_state
{
    Texture = (sgrMap);    
};
sampler backBufferMap : register(s0);

texture positionMapTex;
sampler positionMap = sampler_state
{
    Texture   = <positionMapTex>;    
};

texture normalMapTex;
sampler normalMap = sampler_state
{
    Texture   = <normalMapTex>;
    AddressU  = mirror; 
    AddressV  = mirror;
};
texture foamMapTex;
sampler foamMap = sampler_state
{
    Texture   = <foamMapTex>;
    AddressU  = mirror; 
    AddressV  = mirror;
};

texture reflectionMapTex;
sampler reflectionMap = sampler_state
{
    Texture   = <reflectionMapTex>;       
};

float Viscosity = 5.0f;
// We need this matrix to restore position in world space
float4x4 matViewInverse;

// Level at which water surface begins
float waterLevel = -25.0f;

// Position of the camera
float3 cameraPos;

// How fast will colours fade out. You can also think about this
// values as how clear water is. Therefore use smaller values (eg. 0.05f)
// to have crystal clear water and bigger to achieve "muddy" water.
float fadeSpeed = 0.15f;

// Normals scaling factor
float normalScale = 1.0f;

// R0 is a constant related to the index of refraction (IOR).
// It should be computed on the CPU and passed to the shader.
float R0 = 0.5f;

// Direction of the light
float3 lightDir = {0.0f, 1.0f, -0.25f};

// Colour of the sun
float3 sunColor = {1.0f, 1.0f, 1.0f};

// The smaller this value is, the more soft the transition between
// shore and water. If you want hard edges use very big value.
// Default is 1.0f.
float shoreHardness = 1.0f;

// This value modifies current fresnel term. If you want to weaken
// reflections use bigger value. If you want to empasize them use
// value smaller then 0. Default is 0.0f.
float refractionStrength = 0.0f;
//float refractionStrength = -0.3f;

// Modifies 4 sampled normals. Increase first values to have more
// smaller "waves" or last to have more bigger "waves"
float4 normalModifier = {1.0f, 2.0f, 4.0f, 8.0f};

// Strength of displacement along normal.
float displace = .01f;

// Describes at what depth foam starts to fade out and
// at what it is completely invisible. The fird value is at
// what height foam for waves appear (+ waterLevel).
float3 foamExistence = {0.65f, 1.35f, 0.5f};

float sunScale = 3.0f;

float4x4 matReflection =
{
/*{0.5f, 0.0f, 0.0f, 0.0f},
{0.0f, 0.5f, 0.0f, 0.0f},
{0.0f, 0.0f, 1.0f, 0.0f},
{0.5f + (0.5f / 800), 0.5f + (0.5f / 600), 0.0f, 1.0f}
*/
{0.5f, 0.0f, 0.0f, 0.0f},
{0.0f, 0.5f, 0.0f, 0.0f},
{0.0f, 0.0f, 1.0f, 0.0f},
{0.5f, 0.5f, 0.0f, 1.0f}
};


float4x4 matViewProj;

float shininess = 0.32f;

// Colour of the water surface
float3 depthColour = {0.0078f, 0.5176f, 0.7f};
// Colour of the water depth
float3 bigDepthColour = {0.0039f, 0.00196f, 0.145f};
float3 extinction = {7.0f, 30.0f, 40.0f};			// Horizontal

// Water transparency along eye vector.
float visibility = 4.0f;

// Increase this value to have more smaller waves.
float2 scale = {.001f, .001f};
float refractionScale = .005;//0.005f;

// Wind force in x and z axes.
float2 wind = {-0.3f, 0.7f};


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


float3x3 compute_tangent_frame(float3 N, float3 P, float2 UV)
{
	float3 dp1 = ddx(P);
	float3 dp2 = ddy(P);
	float2 duv1 = ddx(UV);
	float2 duv2 = ddy(UV);
	
	float3x3 M = float3x3(dp1, dp2, cross(dp1, dp2));
	float2x3 inverseM = float2x3( cross( M[1], M[2] ), cross( M[2], M[0] ) );
	float3 T = mul(float2(duv1.x, duv2.x), inverseM);
	float3 B = mul(float2(duv1.y, duv2.y), inverseM);
	
	return float3x3(normalize(T), normalize(B), N);
}

// Function calculating fresnel term.
// - normal - normalized normal vector
// - eyeVec - normalized eye vector
float fresnelTerm(float3 normal, float3 eyeVec)
{
	float angle = 1.0f - saturate(dot(normal, eyeVec));
	float fresnel = angle * angle;
	fresnel = fresnel * fresnel;
	fresnel = fresnel * angle;
	return saturate(fresnel * (1.0f - saturate(R0)) + R0 - refractionStrength);
}
float2 halfPixel;
float4 main(VertexOutput IN): COLOR0
{
	
	IN.texCoord -= halfPixel;
	float3 color2 = tex2D(backBufferMap, IN.texCoord).rgb;
	float3 color = color2;
	
	float3 bdc = bigDepthColour * tex2D(lightSampler,IN.texCoord);
	float3 dc = depthColour * tex2D(lightSampler,IN.texCoord);
	
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
	
	/*
	// Waves	
	Wave Waves[NUMWAVES] = {
		{ 1.0f, 1.00f, 0.50f, float2( -1.0f, -0.1f ) },
		{ 2.0f, 1.50f, 1.30f, float2( -0.7f, 0.7f ) },
		{ .50f, 2.50f, 0.250f, float2( 0.2f, -0.1f ) },
	};
	// Generate some waves!
    Waves[0].fFreq 	= fWaveFreq;
    Waves[0].fAmp 	= fWaveAmp;

    Waves[1].fFreq 	= fWaveFreq * 2.0f;
    Waves[1].fAmp 	= fWaveAmp * 0.5f;
    
    Waves[2].fFreq 	= fWaveFreq * 3.0f;
    Waves[2].fAmp 	= fWaveAmp * 1.0f;

	// Sum up the waves
	float ddx = 0.0f, ddy = 0.0f;
	for( int i = 0; i < NUMWAVES; i++ ) 
	{
		level += EvaluateWave( Waves[i], surfacePoint.xz, timer );
	}

	*/
	
	//texCoord = (surfacePoint.xz + eyeVecNorm.xz * 0.1f) + timer;
	//level += tex2D(heightMap,texCoord * .25);
	
	texCoord = (surfacePoint.xz + eyeVecNorm.xz * 0.1f) * scale + timer * 0.01 * wind;
	
	
	t = (level - cameraPos.y) / eyeVecNorm.y;
	surfacePoint = cameraPos + eyeVecNorm * t;
	
	depth = length(position - surfacePoint);
	float depth2 = surfacePoint.y - position.y;
	
	eyeVecNorm = normalize(cameraPos - surfacePoint);
	
	
	// If we are underwater let's leave out complex computations
	if(level > cameraPos.y)
	{
		color = color2 *  dc;				
	}	
	else
	{
		if(position.y <= level)
		{
			// Generate the Normal			
			float3 n[3];
			for( int i = 0; i < NUMWAVES; i++ ) 
			{
				for(int c=0;c < 3;c++)
				{
					float2 xz = surfacePoint.zx;
					if(c == 1)
						xz.x+=1;
					if(c == 2)
						xz.y-=1;
						
					float y = level;//waterLevel + EvaluateWave( Waves[i], xz, timer );
					
					n[c] = float3(xz.x,y,xz.y);
				}
			}
			float3 s[2];
			s[0] = n[0] - n[1];
			s[1] = n[0] - n[2];
			float3 myNormal =  normalize(cross(s[0],s[1]));
			
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
			
			//normal = myNormal;
			
			// Refraction.
			texCoord = IN.texCoord;
			texCoord.x += sin((timer * Viscosity) + 3.0f * abs(position.y)) * (refractionScale * min(depth2, 1.0f)) * ((1-depthVal)*255);
			float3 refraction = tex2D(backBufferMap, texCoord).rgb;
			
			float3 depthN = depth * fadeSpeed;
			float3 waterCol = saturate(length(sunColor) / sunScale);
			refraction = saturate(lerp(lerp(refraction, dc * waterCol, saturate(depthN / visibility)),
							  bdc * waterCol, saturate(depth2 / extinction)));
			
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

			texCoord = (surfacePoint.xz + eyeVecNorm.xz * 0.1) * 0.05 + timer * 0.01f * wind + sin(timer * 0.1 + position.x) * 0.025;
			float2 texCoord2 = (surfacePoint.xz + eyeVecNorm.xz * 0.1) * 0.05 + timer * 0.02f * wind + sin(timer * 0.1 + position.z) * 0.025;
			
			if(depth2 < foamExistence.x)
				foam = (tex2D(foamMap, texCoord) + tex2D(foamMap, texCoord2)) * 0.5f;				
			else if(depth2 < foamExistence.y)
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
			specular += pow(saturate(dot(myNormal,Half)),25) * shininess;
							  
			//color = refraction;// + specular;	
			color = lerp(refraction, reflect, fresnel);
			color = saturate(color + max(specular * (tex2D(lightSampler,IN.texCoord)*2), foam * sunColor));			
			color = lerp(refraction, color, saturate(depth * shoreHardness));				
		}	
		if(position.y > level)
			color = color2;
	}	

	return float4(color, 1.0f);
}


Technique PostProcess
{
    Pass Go
    {       
        PixelShader  = compile ps_3_0 main();
    }
}