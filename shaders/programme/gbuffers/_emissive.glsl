#include "/programme/_lib/version.glsl"

#include "/programme/_lib/uniforms.glsl"
#include "/programme/_lib/math.glsl"
#include "/shader.h"

#ifdef VSH

in vec2 vaUV0;
in vec3 vaPosition;
in vec4 vaColor;

out vec2 uv_atlas;
out vec4 vcol;

// =========



void main()
{
    #if !defined RENDER_OPAQUE

        gl_Position = vec4(-10.0); // discard
        return;

    #endif

    #if !defined RENDER_BEACON_BEAMS && defined G_BEACONBEAM

        gl_Position = vec4(-10.0); // discard
        return;

    #endif



    vec3 position = vaPosition;

    #if defined G_TEXTURED

        position += chunkOffset; // world border

    #endif



    uv_atlas = vaUV0;



    #if !defined G_LIGHTNING

        vcol = vaColor;

    #else

        // NOTE: I do not know why entityId is not working.
//         vcol = entityId == i_LIGHTNING_BOLT ? vec4(1.0) : vec4(vaColor.rgb, 1.0);

//         vcol = abs(vaColor.b - 0.498) < 0.001 ? vec4(1, 0, 0, 1) : vec4(0, 1, 0, 1);
        vcol = vaColor.b < 0.5 ? vec4(1.0) : vec4(vaColor.rgb, 1.0); // else dragon_death_rays

    #endif



    gl_Position = proj4(mProj, mul3(mMV, position));
}

#endif



/*
 * #########
 */



#ifdef FSH

in vec2 uv_atlas;
in vec4 vcol;

uniform sampler2D gtexture; // atlas

// =========



/* RENDERTARGETS: 0,7,1,10,17 */
layout(location = 0) out vec4 col0;
layout(location = 1) out uint col7;

layout(location = 2) out vec4 col1;
layout(location = 3) out vec4 col10;
layout(location = 4) out uint col17;

void main()
{
    vec4 albedo = vcol;

    #if defined MAP_ALBEDO && !defined G_LIGHTNING

        albedo *= texture(gtexture, uv_atlas);

    #endif



    #if !defined G_BEACONBEAM

        if (albedo.a < 0.1) {discard; return;}

    #else

        if (vcol.a < 0.9) {discard; return;}

    #endif



    #if defined G_SPIDEREYES

        albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

    #endif



    // Write.
//     col0 = vec4(0, 1, 0, 1); // debug
    col0 = albedo;
    col7 = 14u; // 3; uint(is_emissive * 7.0 + dither) << 1u

    col1 = vec4(1.0);
    col10 = vec4(0.0);
    col17 = 14u;
}

#endif
