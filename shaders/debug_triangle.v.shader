///DEBUG TRIANGLE VERTEX SHADER
#version 330 core

layout(location = 0)in vec3 vPos;
out vec4 fPos;

void main()
{
    fPos = vec4(vPos.x, vPos.y, vPos.z, 1.0f);
    gl_Position = fPos;
}
;