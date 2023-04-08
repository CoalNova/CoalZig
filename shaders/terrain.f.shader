///COALSTAR BASE TERRAIN FRAGMENT SHADER
#version 330 core

in vec2 fUV;
in vec3 fNrm;

out vec4 oColor;

void main()
{
    vec3 lColor = vec3(0.1f, 0.8f, 0.3f) * (max(0.0, 1.0f - dot(vec3(0.0f, 0.0f, 1.0f), fNrm)) * 0.5f + 0.5f );
    oColor = vec4(lColor, 1.0f);
}