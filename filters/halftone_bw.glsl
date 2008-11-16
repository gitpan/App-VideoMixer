%% $language
GLSL
%% $fragment
// numTiles resp. stride, dotsize als Parameter

uniform sampler2D Source;
varying vec2 texCoord;

float steps = 28.0;
float dotsize = 1.0 / steps ;
float half_step = dotsize / 2.0;

void main(void)
{

    vec2 center = texCoord - vec2(mod(texCoord.x, dotsize),mod(texCoord.y, dotsize)) + half_step;
    vec4 pel = texture2D( Source, center );
    float gray = 1.0 - dot(pel.rgb,
                     vec3(0.3, 0.59, 0.11));

    if (distance(texCoord,center) <= dotsize*gray/2.0) {
      gl_FragColor = vec4(0.0,0.0,0.0,0.0);
    } else {
      gl_FragColor = vec4(1.0,1.0,1.0,0.0);
    };
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