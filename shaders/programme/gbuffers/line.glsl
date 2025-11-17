#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec2 vaUV0;
in vec3 vaPosition;
in vec3 vaNormal;
in vec4 vaColor;

out vec4 vcol;

// =========

vec2 normalize_fast(vec2 v)
{
//     return v * inversesqrt(dot(v, v));
    return v * rsqrt_fast(dot(v, v));
}

// =========



void main()
{
    vcol = vaColor; // f3 + b, f3 + g



    // From vanilla minecraft 1.21.1 /shaders/core/rendertype_lines.vsh
    // Modified.
    #define LINE_WIDTH 2.0
    #define VIEW_SHRINK 0.996074 // view_shrink = 1.0 - (1.0 / 256.0)

    vec4 line_start = proj4(mProj, mul3(mMV, vaPosition) * VIEW_SHRINK); // clip space
    vec4 line_end = proj4(mProj, mul3(mMV, vaPosition + vaNormal) * VIEW_SHRINK);

    vec3 ndc1 = line_start.xyz / line_start.w;
    vec3 ndc2 = line_end.xyz / line_end.w;

    vec2 line_screen_dir = normalize_fast((ndc2.xy - ndc1.xy) * u_viewResolution.xy);
    vec2 line_offset = vec2(-line_screen_dir.y, line_screen_dir.x) * LINE_WIDTH * u_viewResolution.zw;

    if (line_offset.x < 0.0) line_offset = -line_offset;
    if ((gl_VertexID & 1) != 0) line_offset = -line_offset;

    gl_Position = vec4((ndc1 + vec3(line_offset, 0.0)) * line_start.w, line_start.w);
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec4 vcol;

// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 col0;

void main()
{
    // Write.
    col0 = vcol;
}

#endif
