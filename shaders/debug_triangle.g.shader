///DEBUG TRIANGLE GEMOETRY SHADER
#version 330 core

layout(points) in;
layout(triangle_strip,max_vertices=36)out;

in vec4 gPos[];
out vec4 fpos;


void main()
{
    fpos=gPos[0];
    gl_Position=fpos;
    EmitVertex();
    fpos=gPos[1];
    gl_Position=fpos;
    EmitVertex();
    fpos=gPos[2];
    gl_Position=fpos;
    EmitVertex();
    EndPrimitive();
}
;