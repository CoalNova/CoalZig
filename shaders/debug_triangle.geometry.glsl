///DEBUG TRIANGLE GEMOETRY SHADER

layout(points);
layout(triangle_strip,max_vertices=36)out;

out vec4 fpos

vec3 verts[3]=vec3[]
(
    vec4(-.8,-.8,.5,1),
    vec4(.8,-.8,.5,1),
    vec4(0.,.8,.5,1)
);

void main()
{
    fpos=verts[0];
    gl_Position=fpos;
    EmitVertex();
    fpos=verts[1];
    gl_Position=fpos;
    EmitVertex();
    fpos=verts[2];
    gl_Position=fpos;
    EmitVertex();
    EndPrimitive();
}