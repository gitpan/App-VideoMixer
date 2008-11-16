%% $language
GLSL
%% $fragment
uniform sampler2D Source; //Deklaration einer 2D-Textur
varying vec2  texCoord;
vec2 tc_offset[9]; //Textur-Zugriff der Vektoren
void main(void)
{
//3x3 Kernel
vec4 sample[9];
//Setup der Vektoren
//Reihe 1
tc_offset[0] = vec2(-0.0028125, 0.0028125);
tc_offset[1] = vec2(0.00, 0.0028125);
tc_offset[2] = vec2(0.0028125, 0.0028125);
//Reihe 2
tc_offset[3] = vec2(-0.0028125, 0.00 );
tc_offset[4] = vec2(0.0, 0.0);
tc_offset[5] = vec2(0.0028125, 0.0028125);
//Reihe 3
tc_offset[6] = vec2(-0.0028125, -0.0028125);
tc_offset[7] = vec2(0.00, -0.0028125);
tc_offset[8] = vec2(0.0028125, -0.0028125);
//Vektor-Werte der Textur ermitteln (Anwendung auf sample)
for (int i = 0; i < 9; i++)
{
sample[i] = texture2D(Source, texCoord.st + tc_offset[i]);
}
// -1 -2 -1 1 0 -1
// H = 0 0 0 V = 2 0 -2
// 1 2 1 1 0 -1
vec4 horizEdge = sample[2] + (2.0*sample[5]) + sample[8] -
(sample[0] + (2.0*sample[3]) + sample[6]);
vec4 vertEdge = sample[0] + (2.0*sample[1]) + sample[2] -
(sample[6] + (2.0*sample[7]) + sample[8]);
//Speicherung der Farbwerte
gl_FragColor.rgb = sqrt((horizEdge.rgb * horizEdge.rgb) +
(vertEdge.rgb * vertEdge.rgb));
gl_FragColor.a = 1.0;
}
%% $vertex
varying vec2  texCoord;

void main(void)
{
   gl_Position = vec4( gl_Vertex.xy, 0.0, 1.0 );
   gl_Position = sign( gl_Position );

   // Texture coordinate for screen aligned (in correct range):
   texCoord = (vec2( gl_Position.x, gl_Position.y ) + vec2( 1.0 ) ) / vec2( 2.0 );

}