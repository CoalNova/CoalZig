///DEBUG CUBE GENERATION FRAGMENT SHADER
#version 330 core

in vec4 vPos;
out vec4 color;

void main()
{

	vec3 tempColor = vec3(sin(vPos.x) * 0.4f + 0.6f, sin(vPos.y) * 0.4f + 0.6f, sin(vPos.z) * 0.4f + 0.6f);

	color = vec4(tempColor, 1.0f);
}
