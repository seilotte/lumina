// Custom uniforms.
uniform vec3 u_shadowLightDirection;

uniform vec4 u_viewResolution;
uniform vec4 u_lightColor;

// =========

uniform int renderStage;
uniform int worldTime;
// uniform int entityId;
uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int isEyeInWater;
uniform int frameCounter;

uniform float frameTimeCounter;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float fogStart;
uniform float fogEnd;
uniform float cloudHeight;
uniform float cloudTime;

uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 chunkOffset;
uniform vec3 sunPosition;
uniform vec3 eyePosition;

uniform vec4 entityColor;

uniform mat3 normalMatrix;
uniform mat4 textureMatrix = mat4(1.0);

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;

uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform mat4 modelViewMatrix;
uniform mat4 modelViewMatrixInverse;
uniform mat4 projectionMatrix;
uniform mat4 projectionMatrixInverse;

// =========

#if defined VOXY

uniform int vxRenderDistance;

#define vxFar float(vxRenderDistance)

// uniform mat4 vxModelView;
// uniform mat4 vxModelViewInv;
// uniform mat4 vxModelViewPrev;
// uniform mat4 vxProj;
// uniform mat4 vxProjInv;
// uniform mat4 vxProjPrev;
// uniform mat4 vxViewProj;
// uniform mat4 vxViewProjInv;
// uniform mat4 vxViewProjPrev;

// uniform sampler2D vxDepthTexOpaque;
// uniform sampler2D vxDepthTexTrans;

#endif
