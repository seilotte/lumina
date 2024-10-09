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

// const bool colortex7MipmapEnabled = true;
// const bool colortex8MipmapEnabled = true;

uniform sampler2D colortex0; // c_final.rgb

uniform sampler2D colortex4; // col_sky.rgb
uniform sampler2D colortex5; // normals.rg, uv_lightmap.b, stencil.a
uniform sampler2D colortex6; // c_emissivet.r, m_emissivet.g
uniform sampler2D colortex7; // ssgi.r, ssao.g
uniform sampler2D colortex8; // c_lights.r

uniform sampler2D colortex9; // c_taa.rgb

// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 debug;

void main()
{
    // Initialize values.
    debug = vec3(.0f);



    vec4 col0           = texture(colortex0, uv);
    vec4 col4           = texture(colortex4, uv);
    vec4 col5           = texture(colortex5, uv);
    vec4 col6           = texture(colortex6, uv);
    vec4 col7           = texture(colortex7, uv);
    vec4 col8           = texture(colortex8, uv);
//     vec4 col9           = texture(colortex9, uv);

    vec3 col_final      = col0.rgb;

    vec3 col_sky        = col4.rgb;

    vec3 normal         = decode_normal(col5.rg * 2.0f - 1.0f);
    vec2 uv_lightmap    = unpackUnorm2x4(col5.b);
    float stencil       = col5.a;

    vec3 col_emiss      = col6.rgb;
    float mask_emiss    = col6.a;

    vec3 ssgi           = col7.rgb;
    float ssao          = col7.a;

    vec3 col_lights     = normalize(col8.rgb + vec3(1e-2, 8e-3, 6e-3));

//     vec3 taa_prev       = col9.rgb;



//     debug = col_final;

//     debug = col_sky;

    debug = normal;
//     debug = vec3(uv_lightmap, 0.0f);
//     debug = vec3(uv_lightmap.x);
//     debug = vec3(stencil);
//     debug = vec3(stencil == s_EMISSIVE);

//     debug = col_emiss;
//     debug = vec3(mask_emiss);

//     debug = ssgi;
//     debug = vec3(ssao);

//     debug = col8.rgb;
//     debug = col_lights;
}

#endif
