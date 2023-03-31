///COALSTAR BASE TERRAIN FRAGMENT SHADER
#version 330 core

in vec2 fUV;
in vec3 fNrm;

out vec4 oColor;

main()
{
    oColor = vec4(fUV.x * 0.5f + fNrm.x, fUV.y * 0.5f + fNrm.y, fNrm.z, 1.0f);
}