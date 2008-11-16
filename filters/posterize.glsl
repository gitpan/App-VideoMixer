%% $language
GLSL
%% $fragment
uniform sampler2D Source; //Deklaration einer 2D-Textur
varying vec2  texCoord;
float threshhold = 0.5;

void main(void)
{
    vec4 pel = texture2D(Source,texCoord);
    vec4 res = vec4(0.0,0.0,0.0,0.0);
    
    // Now, for every value above threshhold, put in the maximum:
    if (pel.r > threshhold) { res.r = 1.0; };
    
    if (pel.g > threshhold) { res.g = 1.0; };
    
    if (pel.b > threshhold) { res.b = 1.0; };
    
    gl_FragColor = res;
}

%% $vertex

varying vec2  texCoord;

void main(void)
{
   gl_Position = vec4( gl_Vertex.xy, 0.0, 1.0 );
   gl_Position = sign( gl_Position );
   //gl_TexCoord[0] = gl_MultiTexCoord0;

   // Texture coordinate for screen aligned (in correct range):
   texCoord = (vec2( gl_Position.x, gl_Position.y ) + vec2( 1.0 ) ) / vec2( 2.0 );

}