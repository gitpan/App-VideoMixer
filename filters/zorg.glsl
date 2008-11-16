%% $language
GLSL

%% &setup
    my ($self) = @_;
    my $tex_logo = OpenGL::Tools::load_alpha_texture('images/zorg3.png');
    $self->{logo} = $tex_logo;
    my $sh = $self->shader;
    my $location = $sh->Map('Zorg');
    OpenGL::glUniform1iARB($location,1);

%% &enable
    glActiveTextureARB(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, $_[0]->{logo});
    glEnable(GL_TEXTURE_2D);
    $_[0]->texture_unit("Zorg" => 1);

%% $vertex
varying vec2  texCoord;

void main(void)
{
   gl_Position = vec4( gl_Vertex.xy, 0.0, 1.0 );
   texCoord = (vec2( gl_Position.x, gl_Position.y ) + vec2( 1.0 ) ) / vec2( 2.0 );
}

%% $fragment
uniform sampler2D Source;
uniform sampler2D Zorg;

varying vec2  texCoord;

void main(void)
{
    vec4 pel;
    pel = texture2D( Zorg, texCoord.st );
    // gl_FragColor =  mix(texture2D(Source,texCoord), pel, pel.a);
    gl_FragColor =  mix(texture2D(Source,texCoord), pel, 0.1);
}