%% $language
GLSL
#%% &init
#    my ($shader,$source_texture) = @_;
#    $self->SetVar("Texture0", $source_texture);

%% $fragment
uniform sampler2D Source;
// uniform float offset;
// uniform float frequency;
uniform float offset;
float frequency = 83.0;

varying vec2 texCoord;

void main(void)
{
    float global_pos = (texCoord.y + offset) * frequency;
    float wave_pos = cos((fract( global_pos ) - 0.5)*3.14);
    vec4 pel = texture2D( Source, texCoord );

    gl_FragColor = mix(vec4(0,0,0,0), pel, wave_pos);
}
%% $vertex

varying vec2  texCoord;

void main(void)
{
   gl_Position = vec4( gl_Vertex.xy, 0.0, 1.0 );
   gl_Position = sign( gl_Position );
   gl_TexCoord[0] = gl_MultiTexCoord0;

   // Texture coordinate for screen aligned (in correct range):
   texCoord = (vec2( gl_Position.x, gl_Position.y ) + vec2( 1.0 ) ) / vec2( 2.0 );

}

