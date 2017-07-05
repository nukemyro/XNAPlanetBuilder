//////////////////////////////////////////////////////////////
//															//
//	This shader is intended to be used by ST Excalibur's	//
//	hard point editor to render ships as a post process.	//
//															//
//	By: Charles Humphrey									//
//															//
//////////////////////////////////////////////////////////////

sampler screen : register(s0);			// Rather than passing scene, pass the deferred color map

float4x4 viewProjectionInv;				// The Inverse of the view projection
float angle = 1.0f/2.0f;				// Angle of drop off
float sobelWeight = 0;					// Sobel weight

float4 color;							// Color
float4 bgColor;							// Background/drop off color
float3 camPos;							// Camera position


texture depthMap;						// deferred Depth map

sampler2D DepthMap = sampler_state
{
	Texture = <depthMap>;
	MinFilter = Point;
	MagFilter = Point;
	MipFilter = None;
};

texture bumpMap;						// deferred bump map

sampler2D BumpMap = sampler_state
{
	Texture = <bumpMap>;
	AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};

struct PS_INPUT 
{
	float2 TexCoord	: TEXCOORD0;
};

float lum(float4 c) 
{
	return dot(c.rgb, float3(0.3, 0.59, 0.11));
}

float2 imageIncrement = float2(1,1);

float4 focalPS(PS_INPUT Input) : COLOR0 
{
	
	float depth = 1-tex2D(DepthMap,Input.TexCoord).r;

	if(depth >= .999)
		return bgColor;
	else
	{

		// Sobel stuff
		float2 imageCoord = Input.TexCoord;
		float s = 1.0f;
		float t00 = lum(tex2D(screen, imageCoord + imageIncrement * float2(-s, -s)));
		float t10 = lum(tex2D(screen, imageCoord + imageIncrement * float2( 0, -s)));
		float t20 = lum(tex2D(screen, imageCoord + imageIncrement * float2( s, -s)));
		float t01 = lum(tex2D(screen, imageCoord + imageIncrement * float2(-s,  0)));
		float t21 = lum(tex2D(screen, imageCoord + imageIncrement * float2( s,  0)));
		float t02 = lum(tex2D(screen, imageCoord + imageIncrement * float2(-s,  s)));
		float t12 = lum(tex2D(screen, imageCoord + imageIncrement * float2( 0,  s)));
		float t22 = lum(tex2D(screen, imageCoord + imageIncrement * float2( s,  s)));
		
		float2 grad;		
		grad.x = t00 + 2.0 * t01 + t02 - t20 - 2.0 * t21 - t22;
		grad.y = t00 + 2.0 * t10 + t20 - t02 - 2.0 * t12 - t22;
		
		float len = length(grad);
		float4 c = float4(len, len, len, 1.0);
  
		// Fall off light calc
		float4 normalData = tex2D(BumpMap,Input.TexCoord);
		float3 normal = 2.0f * normalData.xyz - 1.0f;

		// Our position on the screen
		float4 screenPos;
		screenPos.x = Input.TexCoord.x*2.0f-1.0f;
		screenPos.y = -(Input.TexCoord.y*2.0f-1.0f);
	
		screenPos.z = depth;
		screenPos.w = 1.0f;
	
		// Our position in the world
		float4 worldPos = mul(screenPos, viewProjectionInv);
		worldPos /= worldPos.w;

		// Calc light direction based on camera position.
		float3 ld = normalize(camPos - worldPos.xyz);

		// Calc the normal.
		float3 n = 2.0f * tex2D(BumpMap,Input.TexCoord) - 1.0f;

		// Calc the dot product of the light
		float d = dot(n,ld);
	
		// Apply color to pixel, based on sobel + colorFallOff
		return (c * sobelWeight) + lerp(bgColor,color * 2,saturate(angle-d));
	
	}
	
}

technique STHardPointShip 
{
	pass P0
	{
		PixelShader = compile ps_2_0 focalPS();
	}
}