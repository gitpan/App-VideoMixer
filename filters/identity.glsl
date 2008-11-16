%% $language
GLSL
%% $vertex
//varying vec2  texCoord;

void main (void)
{
    //Weiterleitung der Texturkoordinaten
    gl_TexCoord[0] = gl_MultiTexCoord0;
    //Gleiche Vertexposition sichern
    gl_Position = ftransform();
}

%% $fragment
uniform sampler2D Source; //Deklaration einer 2D-Textur
void main(void)
{
    //Vector-Werte der Textur ermitteln
    vec4 texture = texture2D(Source, gl_TexCoord[0].st);
    //Speicherung der Farbwerte
    gl_FragColor = texture;
}
