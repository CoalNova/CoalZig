///DEBUG TRIANGLE FRAGMENT SHADER
#version 330 core

in vec4 fPos;
out vec4 fColor;

void main()
{
    fColor = vec4(sin(fpos.x) * 0.4f + 1.2f, sin(fpos.y) * 0.4f + 1.2f, 0.8f, 1.0f);
}
;