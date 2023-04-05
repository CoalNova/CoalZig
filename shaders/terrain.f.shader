///COALSTAR BASE TERRAIN FRAGMENT SHADER
#version 330 core

in vec2 fUV;
in vec3 fNrm;

out vec4 oColor;

void main()
{
    oColor = vec4(0.1f, 0.8f, 0.3f, 1.0f);
}