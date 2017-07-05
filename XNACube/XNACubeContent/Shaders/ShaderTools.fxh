float fWaveFreq = 0.75f;
float fWaveAmp = 0.125f;
float timer	: Time;

float Viscosity = 5.0f;
// We need this matrix to restore position in world space
float4x4 matViewInverse;

// Level at which water surface begins
float waterLevel = -5.0f;

// Position of the camera
float3 cameraPos;

// Maximum waves amplitude
float maxAmplitude = 3.25f;

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
float refractionScale = .00525;//0.005f;

// Wind force in x and z axes.
float2 wind = {-0.3f, 0.7f};

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


float2 RotateRight(float2 coord,float time)
{
	coord.x -= time;
	if(coord.x < 0)	
		coord.x = coord.x+1;
		
	return coord;
}
float2 MoveInCircle(float2 texCoord,float time,float speed)
{
	float2 texRoll = texCoord;
	texRoll.x += cos(time*speed);
	texRoll.y += sin(time*speed);
	
	return texRoll;
}