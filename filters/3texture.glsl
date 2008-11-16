%% $language
GLSL
%% $vertex
varying vec2  texCoord;

void main(void)
{
   gl_Position = vec4( gl_Vertex.xy, 0.0, 1.0 );
   gl_Position = sign( gl_Position );

   // Texture coordinate for screen aligned (in correct range):
   texCoord = (vec2( gl_Position.x, - gl_Position.y ) + vec2( 1.0 ) ) / vec2( 2.0 );

}

%% $fragment
uniform sampler2D Texture0;
uniform sampler2D Source;
uniform sampler2D Texture2;
uniform sampler2D Texture3;

varying vec2 texCoord;

void main(void)
{
    vec4 pel;
    vec4 target;
    float n;
    pel = texture2D( Texture0, texCoord );
    n = pel.x+pel.y+pel.z+pel.w;

    if (n > 0.0) {
        gl_FragColor = (
             texture2D( Source, texCoord )*pel.x
           + texture2D( Texture2, texCoord )*pel.y
           + texture2D( Texture3, texCoord )*pel.z
           ) / n;
    } else {
        gl_FragColor = vec4(0,0,0,0);
    }
}