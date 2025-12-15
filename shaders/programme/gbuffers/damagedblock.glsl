#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec2 vaUV0;
in vec3 vaPosition;

out vec2 uv;

// =========



void main()
{
    uv = vaUV0;



    gl_Position = proj4(mProj, mul3(mMV, vaPosition));
//     gl_Position.x = gl_Position.x * 0.5 - gl_Position.w * 0.5; // downscale
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform sampler2D gtexture; // not atlas

// =========



/* RENDERTARGETS: 1 */
layout(location = 0) out vec4 col1;

void main()
{
    vec4 albedo = texture(gtexture, uv);

    if (albedo.a < 0.1) {discard; return;}



    // Write.
    col1 = albedo;
}

#endif
