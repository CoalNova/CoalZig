///DEBUG CUBE GENERATION FRAGMENT SHADER
#version 330 core

out vec4 fColor;

void main()
{
	fColor = vec4(
		sin(gl_FragCoord.x * 2) * 0.4f + 0.8f, 
		sin(gl_FragCoord.y * 2) * 0.4f + 0.8f, 
		0.5f, 1.0f); 
}
