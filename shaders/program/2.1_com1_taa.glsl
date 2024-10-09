#include "/shader.h"
// #include "/program/lib/math.glsl"

#ifdef VSH

out vec2 uv;

in vec3 vaPosition;



// =========



void main()
{
    // vertex -> screen
    gl_Position = vec4(vaPosition.xy * 2.0f - 1.0f, 0.0f, 1.0f);

    uv = vaPosition.xy;
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv;

uniform vec2 c_viewPixelSize;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

uniform sampler2D depthtex0;
uniform sampler2D colortex0; // col_final.rgb
uniform sampler2D colortex9; // taa_previous_frame.rgb

// ===

#if defined DISTANT_HORIZONS && defined RENDER_DISTANT_HORIZONS

uniform mat4 dhProjectionInverse;
uniform mat4 dhPreviousProjection;

uniform sampler2D dhDepthTex0;

#endif



// =========



vec2 get_prev_screen(vec3 ps, mat4 gProjInv, mat4 gPrevProj)
{
    vec3 p;

    // screen -> ndc
    p = ps * 2.0f - 1.0f;

    // ndc -> view
    // x  0  0  0
    // 0  x  0  0
    // 0  0  x  x
    // 0  0 -1  1
    p = vec3(
        gProjInv[0].x * p.x,
        gProjInv[1].y * p.y,
        gProjInv[3].z
    ) / (p.z * gProjInv[2].w + gProjInv[3].w);

    // view -> feet
    // x  x  x  t
    // x  x  x  t
    // x  x  x  t
    // 0  0  0  1
    p = mat3(gbufferModelViewInverse) * p + gbufferModelViewInverse[3].xyz;

    // feet -> world -> prev_feet
    p = p + cameraPosition - previousCameraPosition;

    // prev_feet -> prev_view
    // x  x  x  t
    // x  x  x  t
    // x  x  x  t
    // 0  0  0  1
    p = mat3(gbufferPreviousModelView) * p + gbufferPreviousModelView[3].xyz;

    // prev_view -> prev_ndc
    // x  0  0  0
    // 0  x  0  0
    // 0  0  x  x
    // 0  0 -1  0
    p = vec3(
        gPrevProj[0].x * p.x,
        gPrevProj[1].y * p.y,
        gPrevProj[2].z * p.z + gPrevProj[3].z
    ) / -p.z;

    // prev_ndc -> prev_screen
    return p.xy * 0.5f + 0.5f;
}



// =========



/* RENDERTARGETS: 0,9 */
layout(location = 0) out vec3 col0;
layout(location = 1) out vec3 col9;

void main()
{
    // Initialize values.
//     col0 = vec3(.0f);
//     col9 = vec3(.0f);



    col0 = texture(colortex0, uv).rgb; // center

    #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

        float z = textureLod(depthtex0, uv, 0.0f).r;
        mat4 gProjInv = gbufferProjectionInverse;
        mat4 gPrevProj = gbufferPreviousProjection;

    #else

        float z = textureLod(depthtex0, uv, 0.0f).r;
        float z_dh = textureLod(dhDepthTex0, uv, 0.0f).r;

        bool is_dh = z == 1.0f && z_dh < 1.0f;


        z = is_dh ? z_dh : z;
        mat4 gProjInv = is_dh ? dhProjectionInverse : gbufferProjectionInverse;
        mat4 gPrevProj = is_dh ? dhPreviousProjection : gbufferPreviousProjection;

    #endif

    if (z == 1.0f || z < 1e-5) return;

    vec2 uv_prev = get_prev_screen(vec3(uv, z), gProjInv, gPrevProj);

//     if (clamp(uv_prev, -0.25f, 1.25f) != uv_prev) return;
    if (
        uv_prev.x < -0.25f || uv_prev.x > 1.25f ||
        uv_prev.y < -0.25f || uv_prev.y > 1.25f
    ) return;



    // [demofox] https://www.shadertoy.com/view/3sfBWs
    // Temporal Anti-Aliasing 3x3 neighborhood.

    // get the neighborhood min / max from this frame's render
    vec3 col_min = col0;
    vec3 col_max = col0;

    for (int iy = -1; iy < 2; ++iy)
    {
        for(int ix = -1; ix < 2; ++ix)
        {
            if (ix == 0 && iy == 0) continue;

            vec2 uv_offset = (gl_FragCoord.xy + vec2(ix, iy)) * c_viewPixelSize;
            vec3 col = texture(colortex0, uv_offset).rgb;

            col_min = min(col_min, col);
            col_max = max(col_max, col);
        }
    }

    // get last frame's pixel and clamp it to the neighborhood of this frame
    vec3 old = texture(colortex9, uv_prev).rgb;
    old = max(col_min, old);
    old = min(col_max, old);

    // sharpen; old = blured
    col0 *= (col0 - old) + 1.f;

    // interpolate from the clamped old colour to the new colour
    col0 = mix(old, col0, TAA_FAC);
    col9 = col0;
}

#endif
