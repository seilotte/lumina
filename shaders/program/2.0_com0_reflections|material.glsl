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

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D depthtex1;
uniform sampler2D colortex0; // col_final.rgb
uniform sampler2D colortex5; // normals.rg, uv_lightmap.b, stencil.a


// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 col0;

void main()
{
    // Initialize values.
//     col0 = vec3(.0f);



    col0 = texture(colortex0, uv).rgb;
    vec4 col5 = texture(colortex5, uv);

    if (col5.a > 0.999f || col5.a != s_METALLIC && col5.a != s_WATER) return;

    #ifndef REF

        if (col5.a == s_METALLIC) return;

    #endif

    #ifndef REF_WATER

        if (col5.a == s_WATER) return;

    #endif

    vec3 normal = decode_normal(col5.rg * 2.0f - 1.0f);

    // screen -> ndc -> view
    vec3 pos_view;
    pos_view = vec3(uv, textureLod(depthtex1, uv, 0.0).r) * 2.0f - 1.0f;
    pos_view = vec3(
        gbufferProjectionInverse[0].x * pos_view.x,
        gbufferProjectionInverse[1].y * pos_view.y,
        gbufferProjectionInverse[3].z
    ) / (pos_view.z * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);

    // fov_x; Fix for zoom, not perfect.
    pos_view.z *= atan(1.0f / gbufferProjection[0].x);



    vec3 uv_ref = reflect(normalize(-pos_view), normal);

    float mask = max(0.0f, 0.7f - abs(uv_ref.y));
    mask *= col5.a == s_WATER ? REF_WATER_INTENSITY : REF_INTENSITY;

    // Modified polar coordinates.
    uv_ref.y = uv_ref.y * -0.7f + 0.5f;                     // theta
    uv_ref.x = abs(atan(uv_ref.z, uv_ref.x) * 0.31831f);    // phi



    // WRITE: col_final.rgb
    col0 = mix(col0, texture(colortex0, uv_ref.xy).rgb, mask);
}

#endif
