// [Olivier|Yannick|Clément] https://github.com/cdrinmatane/SSRT3
// Screen Space Ambient Occlusion & Screen Space Indirect Lighting with Visibility Bitmasks.
//
// Modified.
// Comment: Original almost 1:1 port is in "/_saves/com_ssrt3.glsl".

// ===

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
uniform vec2 c_viewPixelSize;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D noisetex;
uniform sampler2D depthtex1;
uniform sampler2D colortex5; // normals.rg, uv_lightmap.b, stencil.a

// ===

#if defined DISTANT_HORIZONS && defined RENDER_DISTANT_HORIZONS

uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;

uniform sampler2D dhDepthTex0; // equal to dhDepthTex1 in deferred

#endif

/**/
#if defined SS_GI || defined SS_CL

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
// uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

uniform sampler2D colortex0; // c_final.rgb
uniform sampler2D colortex6; // c_emissivet.rgb, m_emissivet.a
uniform sampler2D colortex8; // c_lights.rgb

#endif



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



void horizon_sampling(
    inout float ssao,
    inout vec3 ssgi,
    inout vec3 sscl,
    bool is_right,
    bool is_dh,

    float depth,
    float n,
    vec2 slice_dir_texel_size,
    vec3 pos_view,
    vec3 vec_view,
    vec3 nor_plane,
    vec3 nor_view,
    mat4 gProj,
    mat4 gProjInv
)
{
    uint occluded_bitfield_global = 0u;
    vec3 col_gi = vec3(.0f);
    vec3 col_cl = vec3(.0f);



    float radius_step = SS_GIAOCL_RADIUS * gProj[0].x / pos_view.z;
    float radius_view = radius_step * float(SS_GIAOCL_ITERATIONS - 1u);

    // s_ = sample_
    float s_dir = is_right ? 1.0f : -1.0f;

    float initial_ray_step = texture(noisetex, gl_FragCoord.xy * 0.015625f).r;

    #if defined SS_GI || defined SS_CL

        vec3 s_pos_view_last = pos_view;

    #endif

    for (uint j = 0u; j < SS_GIAOCL_ITERATIONS; ++j)
    {
        vec2 uv_offset = slice_dir_texel_size * max(
            abs((radius_step * (float(j) + initial_ray_step)) / radius_view) * radius_view,
            float(j + 1u)
        );

        vec2 s_uv = uv + uv_offset * s_dir;

        if (
            s_uv.x < 0.0f || s_uv.x > 1.0f ||
            s_uv.y < 0.0f || s_uv.y > 1.0f
        ) break;



        float mip = min(4.0f, float(j + 1u) * 0.5f);

        #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

            float s_depth= textureLod(depthtex1, s_uv, mip).r;

        #else

            float s_depth = is_dh ?
            textureLod(dhDepthTex0, s_uv, mip).r :
            textureLod(depthtex1, s_uv, mip).r;

        #endif

        if (
            s_depth == 1.0f || // is_sky
            s_depth < 0.6f  || // is_hand
            s_depth == depth
        ) break;

        // screen -> ndc -> view
        vec3 s_pos_view = vec3(
            gProjInv[0].x * (s_uv.x * 2.0f - 1.0f),
            gProjInv[1].y * (s_uv.y * 2.0f - 1.0f),
            gProjInv[3].z
        ) / ((s_depth * 2.0f - 1.0f) * gProjInv[2].w + gProjInv[3].w);

        vec3 s_pixel = normalize(s_pos_view - pos_view);
        vec3 s_pixel_backface = normalize((s_pos_view - vec_view) - pos_view);



        vec2 horizon_front_back;

        horizon_front_back = vec2(
            dot(vec_view, s_pixel),
            dot(vec_view, s_pixel_backface)
        );
        horizon_front_back = acos_fast(
            clamp(horizon_front_back, -1.0f, 1.0f)
        );
        horizon_front_back = clamp(
            (((s_dir * -horizon_front_back) - n + 1.570796326794896619) / 3.141592653589793238),
            0.0f, 1.0f
        );
        horizon_front_back = is_right ?
        horizon_front_back.yx :
        horizon_front_back.xy;


//         {
            // ComputeOccludedBitfield()
            uint horizon_start = uint(horizon_front_back.x * 32.0f);
            uint horizon_angle = uint(ceil(clamp(
                horizon_front_back.y - horizon_front_back.x,
                0.0f, 1.0f
            ) * 32.0f));
            uint horizon_angle_bitfield = horizon_angle > 0u ?
            0xFFFFFFFFu >> (32u - horizon_angle) :
            0u;

            uint occluded_bitfield_current =
            horizon_angle_bitfield << horizon_start;
            occluded_bitfield_current =
            occluded_bitfield_current & (~occluded_bitfield_global);

            // ssao
            occluded_bitfield_global =
            occluded_bitfield_global | occluded_bitfield_current;
//         }



        #ifdef SS_GI || defined SS_CL

        uint occluded_num_zones = bitCount(occluded_bitfield_current);

        if (occluded_num_zones > 0u)
        {
        vec2 uv_prev = get_prev_screen(vec3(s_uv, s_depth));

        vec3 c0 = textureLod(colortex0, s_uv, mip).rgb; // albedo
        vec3 c6 = textureLod(colortex6, s_uv, mip).rgb; // emissives_translucent
        bool c5 = textureLod(colortex5, s_uv, mip).a == s_EMISSIVE; // stencil

        vec3 albedo = c0 + c6;
        vec3 emission = c0 * float(c5) + c6;

        if(
            luma_average(albedo) > 0.001f ||
            luma_average(emission) > 0.001f
        )
        {
        vec3 light_dir_view = normalize(s_pixel);
        float NoL = dot(nor_view, light_dir_view);

        if (NoL > 0.001f)
        {
            vec3 light_nor_view =
            -s_dir * cross(normalize(s_pos_view - s_pos_view_last), nor_plane);

            float light_NoL =
            max(0.001f, dot(light_nor_view, -light_dir_view));

            col_gi +=
            float(occluded_num_zones) * 0.03125f * NoL * light_NoL * albedo;
            col_cl +=
            float(occluded_num_zones) * 0.03125f * NoL * light_NoL * emission;

            // Accumulate frame, helps with noise.
            col_cl = luma_average(col_cl) > 0.001f ?
            col_cl :
            texture(colortex8, uv_prev).rgb * 0.05f;
        }
        }
        }

        s_pos_view_last = s_pos_view;

        #endif
    }

    ssao += float(bitCount(occluded_bitfield_global)) * 0.03125f;
    ssgi += col_gi;
    sscl += col_cl;

    return;
}



// =========



/* RENDERTARGETS: 7,8 */
layout(location = 0) out vec4 col7; // ssgi.rgb, ssao.a
layout(location = 1) out vec3 col8; // c_lights.rgb

void main()
{
    // Initialize values.
    col7 = vec4(.0f);
    col8 = vec3(.0f);



    vec4 col5 = texture(colortex5, uv);

    // !sky & !beacon & !lightning_bolt
    if (col5.a == 1.0f) {discard; return;}



    float ssao;
    vec3 ssgi;
    vec3 sscl;



    #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

        bool is_dh = false;


        float z = textureLod(depthtex1, uv, 0.0f).r;
        mat4 gProjInv = gbufferProjectionInverse;
        mat4 gProj = gbufferProjection;

    #else

        float z = textureLod(depthtex1, uv, 0.0f).r;
        float z_dh = textureLod(dhDepthTex0, uv, 0.0f).r;

        bool is_dh = z == 1.0f && z_dh < 1.0f;


        z = is_dh ? z_dh : z;
        mat4 gProjInv = is_dh ? dhProjectionInverse : gbufferProjectionInverse;
        mat4 gProj = is_dh ? dhProjection : gbufferProjection;

    #endif

    // screen -> ndc -> view
    vec3 pos_view = vec3(
        gProjInv[0].x * (uv.x * 2.0f - 1.0f),
        gProjInv[1].y * (uv.y * 2.0f - 1.0f),
        gProjInv[3].z
    ) / ((z * 2.0f - 1.0f) * gProjInv[2].w + gProjInv[3].w);

    vec3 nor_view = decode_normal(col5.rg * 2.0f - 1.0f);

    vec3 vec_view = normalize(-pos_view);

//     for (uint i = 0u; i < 1u; ++i)
//     {

//         vec2 slice_dir = texture(
//             noisetex,
//             gl_FragCoord.xy * 0.015625f + frameTimeCounter
//         ).rg * 2.0f - 1.0f;

        // NOTE: *R2 noise* was the best for the taa I'm using,
        // even *fast noise* was not better (4 iterations).
        float rot_angle = noise_r2(
            gl_FragCoord.xy + frameTimeCounter
        ) * 3.141592653589793238;

        vec2 slice_dir = vec2(cos(rot_angle), sin(rot_angle));



        vec2 slice_dir_texel_size = slice_dir * c_viewPixelSize;

        vec3 nor_plane = normalize(cross(vec3(slice_dir, 0.0f), vec_view));
        vec3 tangent = cross(vec_view, nor_plane);
        vec3 nor_projected = nor_view - nor_plane * dot(nor_view, nor_plane);
        vec3 nor_projected_normalized = normalize(nor_projected);
        vec3 tangent_real = cross(nor_projected_normalized, nor_plane);

        float cos_n = clamp(
            dot(nor_projected_normalized, vec_view),
            -1.0f, 1.0f
        );
        float n = -sign(dot(nor_projected, tangent)) * acos_fast(cos_n);

        horizon_sampling(
            ssao,
            ssgi,
            sscl,
            true,
            is_dh,

            z,
            n,
            slice_dir_texel_size,
            pos_view,
            vec_view,
            nor_plane,
            nor_view,
            gProj,
            gProjInv
        );
        horizon_sampling(
            ssao,
            ssgi,
            sscl,
            false,
            is_dh,

            z,
            n,
            slice_dir_texel_size,
            pos_view,
            vec_view,
            nor_plane,
            nor_view,
            gProj,
            gProjInv
        );
//     }

    ssao = 1.0f - ssao;
    ssgi *= 10.0f;
    sscl *= 10.0f;



    // WRITE: ssgi.rgb, ssao.a
    col7 = vec4(ssgi, ssao);

    // WRITE: c_lights.rgb
    col8 = sscl;
}

#endif
