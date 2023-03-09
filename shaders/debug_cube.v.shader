//DEBUG CUBE GENERATION VERTEX SHADER
#version 330 core

layout (location = 0) in vec3 inPos;
out vec4 pos;


void main()
{
	pos = vec4(inPos, 1.0f);
}