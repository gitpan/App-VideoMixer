%% $language
GLSL
%% $fragment
// numTiles resp. stride, dotsize als Parameter

uniform sampler2D Source;
varying vec2 texCoord;

float steps = 16.0;
float dotsize = 1.0 / steps ;
float half_step = dotsize / 2.0;

void main(void)
{
    vec2 center = texCoord - vec2(mod(texCoord.x, dotsize),mod(texCoord.y, dotsize)) + half_step;
    vec4 cpel   = texture2D( Source, center );
    vec2 img    = texCoord * steps;
    vec4 pel    = texture2D( Source, img );
    
    // Should use luminance here instead of grayscale
    // Really should use an appropriate tint
    float gray  = 1.0 - dot(cpel.rgb,
                     vec3(0.3, 0.59, 0.11));

    gl_FragColor = pel * gray;
}

%% $vertex
varying vec2  texCoord;

void main(void)
{
   gl_Position = vec4( gl_Vertex.xy, 0.0, 1.0 );
   gl_Position = sign( gl_Position );

   // Texture coordinate for screen aligned (in correct range):
   texCoord = (vec2( gl_Position.x, + gl_Position.y ) + vec2( 1.0 ) ) / vec2( 2.0 );

}