///COALSTAR BASE TERRAIN FRAGMENT SHADER
#version 330 core

//! [0] szzz_zzzz_zzzz_zzzz_zzZo_ZoZo_ZoXn_XnXn
layout (location = 0) in int superZone;
//! [1] XnYn_YnYn_Ynxx_xxxx_xxxx_xyyy_yyyy_yyyy
layout (location = 1) in int superVert;

const float norm_div = 1 / 512;

out vec4 gPos;
out vec3 gNrm;
out vec2 gCrd;
out float gZne;
flat out int gSkp;


uniform mat4 matrix;

void main()
{
    float 
        x = ((superVert >> 11) & 2047) - 512.0f,
        y = (superVert & 2047) - 512.0f,
        z = 0,
        norm_x = 0,
        norm_y = 0;

    gPos = matrix * vec4(x, y, z, 1.0f);
    gNrm = vec3(norm_x, norm_y, 1.0f - (abs(norm_x) + abs(norm_y)));
    gCrd = vec2(norm_x, norm_y);
    gZne = 0;
    gSkp = 0;
}