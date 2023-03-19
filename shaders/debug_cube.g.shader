///DEBUG CUBE GENERATION GEOMETRY SHADER
#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 36) out;

out vec4 vPos;

uniform mat4 matrix;

vec3 verts[8] = vec3[]
(
	vec3(-0.5f, -0.5f, -0.5f),
	vec3(0.5f, -0.5f, -0.5f),
	vec3(-0.5f, -0.5f, 0.5f),
	vec3(0.5f, -0.5f, 0.5f),

	vec3(0.5f, 0.5f, -0.5f),
	vec3(-0.5f, 0.5f, -0.5f),
	vec3(0.5f, 0.5f, 0.5f),
	vec3(-0.5f, 0.5f, 0.5f)
);


void BuildFace(int fir, int sec, int thr, int frt)
{
	vPos = matrix * vec4(verts[fir], 1.0f);
	gl_Position = vPos;
	EmitVertex();
	vPos = matrix * vec4(verts[sec], 1.0f);
	gl_Position = vPos;
	EmitVertex();
	vPos = matrix * vec4(verts[thr], 1.0f);
	gl_Position = vPos;
	EmitVertex();
	EndPrimitive();

	vPos = matrix * vec4(verts[fir], 1.0f);
	gl_Position = vPos;
	EmitVertex();
	vPos = matrix * vec4(verts[frt], 1.0f);
	gl_Position = vPos;
	EmitVertex();
	vPos = matrix * vec4(verts[sec], 1.0f);
	gl_Position = vPos;
	EmitVertex();
	EndPrimitive();

}
/*
0,3,2, 0,1,3,
5,2,7, 5,0,2,
1,6,3, 1,4,6,
2,6,7, 2,3,6,
5,1,0, 5,4,1,
4,7,6, 4,5,7
*/

void main()
{
	BuildFace(0, 3, 2, 1);
	BuildFace(5, 2, 7, 0);
	BuildFace(1, 6, 3, 4);
	BuildFace(2, 6, 7, 3);
	BuildFace(5, 1, 0, 4);
	BuildFace(4, 7, 6, 5);
}