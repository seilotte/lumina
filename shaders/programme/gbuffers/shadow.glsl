#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec3 vaPosition;

// =========



void main()
{
    gl_Position = proj4_ortho(mProj, mul3(mMV, vaPosition + chunkOffset));



    // Distortion.
    gl_Position.xy = mat2(u_mat2ShadowAlign) * gl_Position.xy;
    gl_Position.xy /= abs(gl_Position.xy) * 0.7 + 0.3; // distortion
}

#endif



/*
 * #########
 */



#ifdef FSH

// =========

// NOTE: We only use shadowtexN. There is no need to write shadowColorN.
/* RENDERTARGETS: 0 */

void main()
{

}

#endif
