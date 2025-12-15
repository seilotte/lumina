#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec3 vaPosition;
in vec4 vaColor;

flat out vec4 vcol;

// =========



void main()
{
    vcol = vaColor; // f3 + g, lead



    gl_Position = proj4(mProj, mul3(mMV, vaPosition));
//     gl_Position.x = gl_Position.x * 0.5 - gl_Position.w * 0.5; // downscale
}

#endif



/*
 * #########
 */



#ifdef FSH

flat in vec4 vcol;

// =========



/* RENDERTARGETS: 1 */
layout(location = 0) out vec4 col1;

void main()
{
    if (vcol.a < 0.1) {discard; return;}



    // Write.
    col1 = vcol;
}

#endif
