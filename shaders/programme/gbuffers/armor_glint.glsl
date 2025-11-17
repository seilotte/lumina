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
    uv = (textureMatrix * vec4(vaUV0, 0.0, 1.0)).xy;



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
    vec2 tex_data = texture(gtexture, uv).ra;
    vec3 albedo = vec3(tex_data.r) * vec3(1.2, 1.0, 1.3); // .75 .5 1.



    // Write.
    col0 = vec4(albedo, tex_data.g);
}

#endif
