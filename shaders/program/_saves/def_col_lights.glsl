#include "/shader.h"
#include "/program/lib/math.glsl"

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

uniform float frameTimeCounter;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

uniform sampler2D noisetex;
uniform sampler2D depthtex1;
uniform sampler2D colortex0; // col_final.rgb
uniform sampler2D colortex4; // normals.rg, uv_lightmap.b, stencil.a
uniform sampler2D colortex6; // col_emissives_translucent.r, mask_emissives_translucent.g
uniform sampler2D colortex8; // col_lights.r



// =========



vec2 get_prev_screen(vec3 ps)
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
        gbufferProjectionInverse[0].x * p.x,
        gbufferProjectionInverse[1].y * p.y,
        gbufferProjectionInverse[3].z
    ) / (p.z * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);

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
        gbufferPreviousProjection[0].x * p.x,
        gbufferPreviousProjection[1].y * p.y,
        gbufferPreviousProjection[2].z * p.z + gbufferPreviousProjection[3].z
    ) / -p.z;

    // prev_ndc -> prev_screen
    return p.xy * 0.5f + 0.5f;
}



// =========



/* RENDERTARGETS: 8 */
layout(location = 0) out vec3 col8; // col_lights.rgb

void main()
{
    // Initialize values.
    col8 = vec3(.0f);



    float z = textureLod(depthtex1, uv, 0.0f).r;
    if (z > .9999999998f || z < 1e-5) return;

    vec2 uv_prev = get_prev_screen(vec3(uv, z));
    if (clamp(uv_prev, -0.25f, 1.25f) != uv_prev) return;



    // [CaptTatsu] https://bitslablab.com/bslshaders
    // Modified.

    // or vec2(triwave(noise(coord)), triwave(noise(coord + value)))
    vec2 uv_offset = texture(noisetex, gl_FragCoord.xy * 0.0078125f + frameTimeCounter).rg * 0.06f - 0.03f;

    vec3 emission =
    texture(colortex0, uv).rgb * float(texture(colortex4, uv).a == s_EMISSIVE) +
    texture(colortex6, uv_prev).rgb; // col_emissives_translucent



    // WRITE: col_lights.rgb
    // mix(previous, emission * (1/fac), fac);
    col8 = mix(texture(colortex8, uv_prev + uv_offset).rgb, emission * 3.3f, .3f);
}

#endif
