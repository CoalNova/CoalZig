///COALSTAR BASE TERRAIN GEOMETRY SHADER
#version 330 core

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in vec3 gPos[];
in vec3 gNrm[];
in vec2 gCrd[];
in float gZne[];
flat in int gSkp[];

out vec2 fUV;
out vec3 fNrm;
main()
{
    if (gSkp[0] + gSkp[1] + gSkp[2] > 0)
        return;
    
    gl_Position = gPos[0];
    fUV = vec2(0, 0);
    fNrm = gNrm[0];
    EmitVertex();
    gl_Position = gPos[1];
    fUV = gCrd[1] - gCrd[0];
    fNrm = gNrm[1];
    EmitVertex();
    gl_Position = gPos[2];
    fUV = gCrd[2] - gCrd[0];
    fNrm = gNrm[2];
    EmitVertex();
	EndPrimitive();

}