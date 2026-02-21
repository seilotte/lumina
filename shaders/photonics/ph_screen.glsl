#include "/programme/_lib/version.glsl"

layout(location = 0) in vec3 position;

out vec2 uv;

// =========



void main()
{
    uv = position.xy;



    gl_Position = vec4(position.xy * 2.0 - 1.0, 0.0, 1.0);
}
