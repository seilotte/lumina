#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec3 vaPosition;

out vec2 uv;

// =========



void main()
{
    uv = vaPosition.xy;



    gl_Position = vec4(vaPosition.xy * 2.0 - 1.0, 0.0, 1.0);
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform sampler2D colortex1; // final.rgb
uniform sampler2D colortex2; // albedo.rgb (translucent)

// =========



/* RENDERTARGETS: 1 */
layout(location = 0) out vec3 col1;

void main()
{
    // Initialize values.
//     col1 = vec3(0.0);



    vec3 c1 = textureLod(colortex1, uv, 0.0).rgb;
    vec4 c2 = textureLod(colortex2, uv, 0.0);

    c1 = c1 * c2.aaa + c2.rgb;



    // Write.
    col1 = c1;
}

#endif
