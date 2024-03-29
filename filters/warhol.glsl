%% $language
GLSL
%% $fragment
// numTiles resp. stride, dotsize als Parameter

// #version 120

uniform sampler2D Source;
varying vec2 texCoord;

const float steps = 2.0;
const float dotsize = 1.0 / steps ;
const float half_step = dotsize / 2.0;

// This should be a static 2x2 pixel texture
// but it's done as an if statement instead ...

/*
mat4x4 tint = mat4(
                 vec4(1.0,0.0,1.0,0.0),
                 vec4(1.0,0.0,1.0,0.0),
                 vec4(1.0,0.0,1.0,0.0),
                 vec4(1.0,0.0,1.0,0.0)
                );
*/

void main(void)
{
    vec2 img    = texCoord * steps;
    vec4 pel    = texture2D( Source, img );
    
    vec4 tint;
    
    // Magenta Blue
    // Cyan    Yellow
    int ofs = int(texCoord.x*steps) + int(texCoord.y*steps)*2;
    if    (0 == ofs) {
        tint = vec4(1.0,1.0,0.0,0.0);
    } else if (1 == ofs) {
        tint = vec4(0.0,0.0,1.0,0.0);
    } else if (2 == ofs) {
        tint = vec4(1.0,0.0,1.0,0.0);
    } else { // (3 == ofs)
        tint = vec4(0.0,1.0,1.0,0.0);
    };
    
    float gray  = dot(pel.rgb,
                      vec3(0.3, 0.59, 0.11));
    gl_FragColor = mix( pel, tint, gray );
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