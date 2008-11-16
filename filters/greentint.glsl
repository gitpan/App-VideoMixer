%% $language
GLSL
%% $fragment
uniform sampler2D Source;
varying vec2  texCoord;

vec4 tintcolor = vec4(1.0,1.0,0.0,1.0);

void main(void)
{
    //Vector-Werte der Textur ermitteln
    vec4 texture = texture2D(Source, texCoord.st);
    //Konvertierung RGB in Graustufen (Punktprodukt)
    float gray = dot(vec3(texture[0], texture[1], texture[2]),
    vec3(0.3, 0.59, 0.11));

    gl_FragColor = tintcolor * vec4(gray,gray,gray,1.0);
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