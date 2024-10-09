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

uniform sampler2D depthtex1;
uniform sampler2D colortex0; // c_final.rgb
uniform sampler2D colortex5; // normals.rg, uv_lightmap.b, stencil.a

// lighting
uniform float nightVision;
uniform float c_facRain;
uniform float c_isDay;
uniform vec3 c_shadowLightDirection;
uniform vec3 c_colZenith;
uniform vec3 c_colSun;

// ===

#if defined MAP_SHADOW || defined SS_SHADOWS || defined FOG

uniform mat4 gbufferProjectionInverse;

#if defined SS_SHADOWS || defined FOG
#if defined DISTANT_HORIZONS && defined RENDER_DISTANT_HORIZONS

uniform mat4 dhProjectionInverse;

#endif
#endif
#endif


#ifdef MAP_SHADOW

// uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

// uniform sampler2D depthtex1;
uniform sampler2D shadowtex1;

#endif


#if defined SS_SHADOWS || defined FOG_WATER

uniform mat4 gbufferProjection;

#endif


#if defined SS_SHADOWS || defined FOG_WATER || defined FOG
#if defined DISTANT_HORIZONS && defined RENDER_DISTANT_HORIZONS

uniform sampler2D dhDepthTex0; // equal to dhDepthTex1 in deferred

#if defined SS_SHADOWS || defined FOG_WATER

uniform mat4 dhProjection;

#endif
#endif
#endif


#ifdef SS_SHADOWS

uniform float frameTimeCounter;
uniform vec2 c_viewResolution;
// uniform vec3 c_shadowLightDirection;
// uniform mat4 gbufferProjection;
// uniform mat4 gbufferProjectionInverse;

// uniform sampler2D depthtex1;

#endif

/**/
#if defined SS_GI || defined SS_AO

// const bool colortex7MipmapEnabled = true;
uniform sampler2D colortex7; // ssgi.rgb, ssao.a

#endif


#ifdef SS_CL

// const bool colortex8MipmapEnabled = true;
uniform sampler2D colortex8; // c_lights.rgb

#endif

/**/
#if defined FOG_WATER || defined FOG

uniform sampler2D colortex4; // c_sky.rgb

#endif


#ifdef FOG_WATER

uniform int isEyeInWater;
uniform vec3 c_colWaterAbsorb;
uniform vec3 c_colWaterScatter;
// uniform mat4 gbufferProjection;

// uniform sampler2D depthtex1;
// uniform sampler2D colortex4; // c_sky.rgb
// uniform sampler2D colortex5; // normals.rg, uv_lightmap.b, stencil.a

// #if defined DISTANT_HORIZONS && defined RENDER_DISTANT_HORIZONS

// uniform mat4 dhProjection;

// uniform sampler2D dhDepthTex0; // equal to dhDepthTex1 in deferred

// #endif
#endif


#ifdef FOG

uniform float far;
// uniform mat4 gbufferProjectionInverse;

// uniform sampler2D colortex4; // c_sky.rgb

#if defined DISTANT_HORIZONS && defined RENDER_DISTANT_HORIZONS

uniform int dhRenderDistance;
// uniform mat4 dhProjectionInverse;

// uniform sampler2D dhDepthTex0; // equal to dhDepthTex1 in deferred

#endif
#endif



// =========



float min_of(vec3 x)
{
    return min(min(x.x, x.y), x.z);
}



// =========



/* RENDERTARGETS: 0 */
layout(location = 0) out vec3 col0; // c_final.rgb

void main()
{
    // Initialize values.
//     col0 = vec3(.0f);



    col0 = texture(colortex0, uv).rgb;
    vec4 col5 = texture(colortex5, uv);

    if (col5.a < 1.0f) // !sky & !beacon & !lightning_bolt
    {
        // Initialize values.
        vec3 normal = decode_normal(col5.rg * 2.0f - 1.0f);
        vec2 uv_lightmap = unpackUnorm2x4(col5.b);

        float NoL = dot(normal, c_shadowLightDirection) * 0.5f + 0.5f;
        float shadows = float(NoL > 0.255f);
        shadows = 1.0f;

        #if defined MAP_SHADOW || defined SS_SHADOWS \
        || defined FOG_WATER || defined FOG
        #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

            float z = textureLod(depthtex1, uv, 0.0f).r;

        #else

            float z = textureLod(depthtex1, uv, 0.0f).r;
            float z_dh = textureLod(dhDepthTex0, uv, 0.0f).r;

            bool is_dh = z == 1.0f && z_dh < 1.0f;

            z = is_dh ? z_dh : z;

        #endif
        #endif


        #if defined MAP_SHADOW || defined SS_SHADOW || defined FOG
        #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

            mat4 gProjInv = gbufferProjectionInverse;

        #else

            mat4 gProjInv = is_dh ? dhProjectionInverse : gbufferProjectionInverse;

        #endif

            // screen -> ndc -> view
            vec3 pos_view = vec3(
                gProjInv[0].x * (uv.x * 2.0f - 1.0f),
                gProjInv[1].y * (uv.y * 2.0f - 1.0f),
                gProjInv[3].z
            ) / ((z * 2.0f - 1.0f) * gProjInv[2].w + gProjInv[3].w);

        #endif



        #ifdef MAP_SHADOW

            if (shadows > 0.0f)
            {
                // [mateuskreuch] https://github.com/mateuskreuch/minecraft-miniature-shader
                // Modified.
                vec3 pos_feet =
                mat3(gbufferModelViewInverse) * pos_view + gbufferModelViewInverse[3].xyz;

                #if MAP_SHADOW_PIXEL > 0

                    pos_feet =
                    floor(pos_feet * MAP_SHADOW_PIXEL) / MAP_SHADOW_PIXEL;

                #endif

                float pos_distance = dot(pos_feet, pos_feet); // squared length
                float shadow_max_distance = shadowDistance * shadowDistance;

                // feet -> view_shadow -> ndc_shadow -> screen_shadow
                vec3 shadow_view =
                mat3(shadowModelView) * pos_feet + shadowModelView[3].xyz;
                vec2 shadow_uv = vec2(
                    shadowProjection[0].x * shadow_view.x * 0.5f + 0.5f,
                    shadowProjection[1].y * shadow_view.y * 0.5f + 0.5f
                );

                if (
                    shadow_uv.x > 0.0f && shadow_uv.x < 1.0f &&
                    shadow_uv.y > 0.0f && shadow_uv.y < 1.0f &&
                    pos_distance < shadow_max_distance &&
                    -shadow_view.z > 0.0f
                )
                {
                    float shadow_fade =
                    1.0f - pos_distance / shadow_max_distance;
                    float shadow_depth =
                    256.0f * texture(shadowtex1, shadow_uv).r;

                    shadows *=
                    1.0f - shadow_fade *
                    clamp(-shadow_view.z - shadow_depth, 0.0f, 1.0f);
                }
            }

        #endif



        #if defined SS_SHADOWS || defined FOG_WATER
        #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

            mat4 gProj = gbufferProjection;

        #else

            mat4 gProj = is_dh ? dhProjection : gbufferProjection;

        #endif
        #endif



        #ifdef SS_SHADOWS

            if (shadows > 0.f)
            {
                // [zombye] https://github.com/zombye/spectrum
                // Modified.
                float dither = noise_r2(gl_FragCoord.xy + frameTimeCounter);
                vec3 pos_screen = vec3(uv, z);

                vec3 ray_step;
                ray_step = pos_view + abs(pos_view.z) * c_shadowLightDirection;

                ray_step = (vec3(
                    gProj[0].x * ray_step.x,
                    gProj[1].y * ray_step.y,
                    gProj[2].z * ray_step.z + gProj[3].z
                ) / -ray_step.z) * 0.5f + 0.5f;


                ray_step -= pos_screen;
                ray_step *= min_of((step(0.0f, ray_step) - pos_screen) / ray_step);

                pos_screen.z -= 1e-5; // noise fix; tiny offset
                pos_screen.xy *= c_viewResolution;
                ray_step.xy *= c_viewResolution;

                ray_step /= abs(abs(ray_step.x) < abs(ray_step.y) ? ray_step.y : ray_step.x);
                ray_step *= SS_SHADOWS_STRIDE * dither * gProj[0].x; // gProj -> zoom fix

                for (uint i = 0u; i < SS_SHADOWS_ITERATIONS; ++i)
                {
                    vec3 pos_sample = pos_screen + ray_step * float(i);

                    // z at current step & on step toward -z
                    float maxZ = pos_sample.z;
                    float minZ = pos_sample.z - SS_SHADOWS_STRIDE * abs(ray_step.z);

                    if (1.0f < minZ || maxZ < 0.0f) break;

                    // Requiring from BOTH interpolated & noninterpolated depths,
                    // prevents pretty much all false occlusion.
                    #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

                        float z0 =
                        texelFetch(depthtex1, ivec2(pos_sample.xy), 0).r;

                    #else

                        float z0 = is_dh ?
                        texelFetch(dhDepthTex0, ivec2(pos_sample.xy), 0).r :
                        texelFetch(depthtex1, ivec2(pos_sample.xy), 0).r;

                    #endif

                    float z1;
                    {
                        // get_linear_depth()
                        // Interpolates after linearizing,
                        // significantly reduces a lot of issues for screen-space shadows.
                        vec2 coord = pos_sample.xy + 0.5f;

                        vec2 f = fract(coord);
                        ivec2 i = ivec2(coord - f);

                        #if !defined DISTANT_HORIZONS || !defined RENDER_DISTANT_HORIZONS

                            vec4 s =
                            textureGather(depthtex1, i / c_viewResolution);

                        #else

                            vec4 s = is_dh ?
                            textureGather(dhDepthTex0, i / c_viewResolution) :
                            textureGather(depthtex1, i / c_viewResolution);

                        #endif

                        s = 1.0f / (gProjInv[2].w * (s * 2.0f - 1.0f) + gProjInv[3].w);

                        s.xy = mix(s.wx, s.zy, f.x);
                        z1 = mix(s.x,  s.y,  f.y) * gProjInv[3].z;
                    }

                    // view -> screen
                    z1 = (gProj[2].z * z1 + gProj[3].z) * 0.5f / -z1 + 0.5f;

                    // ascribe amount
                    float amount = 0.01f * (i < 1u ? dither : SS_SHADOWS_STRIDE) * gProjInv[1].y;

                    float z0_a;
                    z0_a = 1.0f - 2.0f * z0;
                    z0_a = (z0_a + gProj[2].z * amount) / (1.0f + amount);
                    z0_a = 0.5f - 0.5f * z0_a;

                    float z1_a;
                    z1_a = 1.0f - 2.0f * z1;
                    z1_a = (z1_a + gProj[2].z * amount) / (1.f + amount);
                    z1_a = 0.5f - 0.5f * z1_a;

                    if (
                        maxZ > z0 && minZ < z0_a &&
                        maxZ > z1 && minZ < z1_a &&
                        z0 > 0.6f && z0 < 1.0f // no hand & sky
                    ) shadows = 0.0f;
                }
            }

        #endif



        // Needs: shader.h, vec3 col0, float NoL, float shadows,
        //        float nightVision, float c_isDay, float c_facRain,
        //        vec2 uv_lightmap, vec3 c_colZenith, vec3 c_colSun,
        //        sampler2D colortex8, sampler2D colortex7 (deferred)
        #include "/program/lib/do_lighting().glsl"



        // Needs: ... Open the file.
        #ifdef FOG

            float pos_length = length_fast(pos_view);

        #endif

        #include "/program/lib/do_fog().glsl"



        // WRITE: c_final.rgb
//         col0 = col0;
//         col0 = vec3(shadows); // debug
    }
}

#endif
