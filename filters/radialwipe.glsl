%% $language
GLSL
%% $vertex
sampler2D tex[2];

struct v2p {
	float4 Position	: POSITION;
	float4 Color : COLOR0;
	float2 Texcoord[2] : TEXCOORD0;
};

// sampler2D defines texture array that represents the video streams. v2p is the struct of stream from vertex shader to pixel shader.

void main(in v2p IN, out float4 OUT : COLOR)
{
	float Brightness = 1.2343;
	float len = 0.3;
	float a = 0.2;
	float b = a+len;
	float2 center = float2(0.5, 0.5);
	float3 result;

// Brightness is the variable for brightness of light. a and b are the radius of inner and outer circle respectively. len is the width of the ring. And the center is the centric coordinate of the ring. result represents the result of the value of effect.

	float3 color0  = tex2D(tex[0], IN.Texcoord[0]);
	float3 color1  = tex2D(tex[1], IN.Texcoord[1]);
	float2 point = IN.Texcoord[0];

// color0 and color1 are sampled color value from the first picture and the second picture respectively. point is the current coordinate value.

	float dist = distance( point, center );
	if ( dist < a) {
		result = color0;
	} else if (dist > b) {
		result = color1;
	} else {
		result = lerp(color0, color1, saturate((dist-a) / len));
	}

// This is the kernel of the algorithm. distance is the build-in HLSL function. saturate function converts dist value from [a, b] to [0, 1]. lerp is the build-in function for linear interpolation.


	OUT.rgb = Brightness * result;
	OUT.a = 1.0;
}
%% $fragment
void main (void)
{
    //Weiterleitung der Texturkoordinaten
    gl_TexCoord[0] = gl_MultiTexCoord0;
    //Gleiche Vertexposition sichern
    gl_Position = ftransform();
}