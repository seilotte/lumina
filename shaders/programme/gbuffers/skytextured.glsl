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
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform sampler2D gtexture; // not atlas

// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 col0;

void main()
{
    // Write.
    col0 = texture(gtexture, uv);
}

#endif
