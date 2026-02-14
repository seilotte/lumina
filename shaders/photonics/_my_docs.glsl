/*
    Photonics 0.2.9

    ## NOTE
    In the next update a lot of things will change.
    Therefore all this is **temporary!**
    - Patching will no longer be necessary.
    - Copper lights will be supported.

    ## TEMPORARY GUIDE
    - ph_config.txt
        -> /.minecraft
    - patch.json, ph_indirect.glsl, ph_lighting.glsl, ph_screen.glsl, shader.h
        -> Photonics-0.2.9.jar/assets/photonics/shaders/patches/lumina

    ## WARNING
        Copy-paste on every include worked (ph_lighting.glsl).
        Manual rewrite broke, so...
        Do not remove all the files, easier to mantain.

    SSBO's:
        ...

    Uniforms:
        ...

    You can patch photonics shader files:
        Inside the ./shaders folder.

        ph_core.glsl
        ph_indirect.glsl
        ph_lighting.glsl
        ph_raytracing.glsl
        ph_screen.glsl
        photonics.glsl
        shader_interface.glsl

    Programs:
        Inside the dimensions folder.
        e.g: ./shaders/world0

        indirect.fsh (includes ph_indirect.glsl)
        lighting.fsh (includes ph_lighting.glsl)
        screen.vsh (includes ph_screen.glsl)

        gbuffers_voxels? // not working; for 3D?
        gbuffers_shadow_voxels? // not working; for 3D?

    ## screen.vsh
        Vertex shader for lighting.fsh & indirect.fsh.
        | Like a composite vertex shader.

        Uniforms:
            vec3 position;

    ## lighting.fsh
        Here we write to multiple things.
        Use for raytracing logic.

        Images:
            uniform layout(r32ui) uimage3D gi_x;
            uniform layout(r32ui) uimage3D gi_y;
            uniform layout(r32ui) uimage3D gi_z;
            uniform layout(r32ui) uimage3D gi_w;
            uniform layout(r32ui) uimage3D gi_d;

        Textures:
            layout(location = 0) out vec4 position_frag_out;
            layout(location = 1) out vec4 normal_frag_out;
            layout(location = 2) out vec4 direct_frag_out;
            layout(location = 3) out vec4 direct_soft_frag_out;
            layout(location = 4) out vec4 handheld_frag_out;

            where

            position_frag_out = ???; for temporal reprojection
            normal_frag_out = ???; for temporal reprojection
            direct_frag_out = uniform sampler2D radiosity_direct
            direct_soft_frag_out = uniform sampler2D radiosity_direct_soft;
            handheld_frag_out = uniform sampler2D radiosity_handheld;

    ## indirect.fsh
        Use for indirect lighting; Images.
*/
