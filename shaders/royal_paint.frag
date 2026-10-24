// Royal metallic-flake paint, modelled on automotive "flake" finishes:
//   1. base coat   - curved-panel shading, deep -> base -> bright
//   2. clear coat  - soft specular hotspot + a sweeping reflection band
//   3. flakes      - two layers of tiny mirror flakes with random tilt; each
//                    glints only when the light lines up with its normal.
// The light drifts with time and follows device tilt (uLight).

#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;        // surface size in logical px
uniform vec2 uOrigin;      // surface top-left in local px
uniform float uTime;       // seconds
uniform vec2 uLight;       // device tilt, roughly -1..1 per axis
uniform vec4 uDeep;        // shadow tone
uniform vec4 uBase;        // body tone
uniform vec4 uBright;      // highlight tone
uniform vec4 uFlakeA;      // flake tint A (silver)
uniform vec4 uFlakeB;      // flake tint B (ice / violet)
uniform float uFlakeScale; // flake cell size in px
uniform float uSparkle;    // 0..1 glint strength
uniform float uOpacity;    // overall opacity

out vec4 fragColor;

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.xx + p3.yz) * p3.zy);
}

// One layer of flakes. Returns added light. Most flakes are a faint,
// body-tinted texture; only some are angled to throw a sharp glint.
vec3 flakes(vec2 px, float scale, vec2 light, float seed, float hot) {
  vec2 cell = floor(px / scale);
  vec2 f = fract(px / scale);
  vec2 rnd = hash22(cell + seed);
  vec2 center = 0.25 + rnd * 0.5;
  float size = 0.12 + 0.16 * hash12(cell + seed + 7.0);
  float mask = smoothstep(size, size * 0.15, length(f - center));

  // Random flake tilt; light direction wobbles per flake so they twinkle.
  float a = hash12(cell + seed + 13.1) * 6.2831853;
  vec2 n = vec2(cos(a), sin(a));
  vec2 l = normalize(light + 0.5 * vec2(
    sin(uTime * 0.8 + rnd.x * 6.2831853),
    cos(uTime * 0.65 + rnd.y * 6.2831853)) + 1e-4);
  float glint = pow(max(dot(n, l), 0.0), 60.0);
  float canGlint = step(0.62, hash12(cell + seed + 21.0));

  float lum = hash12(cell + seed + 3.0);
  vec3 tint = mix(uFlakeA.rgb, uFlakeB.rgb, hash12(cell + seed + 5.0));
  vec3 grain = mix(uBright.rgb, tint, 0.45) * lum * 0.09;
  vec3 sparkle = uFlakeA.rgb * glint * canGlint * 2.6 * uSparkle * hot;
  return mask * (grain + sparkle);
}

void main() {
  vec2 px = FlutterFragCoord().xy;
  vec2 uv = (px - uOrigin) / max(uSize, vec2(1.0));

  // Light hotspot in surface space: drifts slowly, follows tilt.
  vec2 drift = vec2(sin(uTime * 0.23), cos(uTime * 0.19)) * 0.07;
  vec2 hot = vec2(0.28, 0.18) + uLight * vec2(0.45, 0.35) + drift;
  float d = distance(uv * vec2(1.0, 0.8), hot * vec2(1.0, 0.8));

  // 1. Base coat.
  float diffuse = smoothstep(1.25, 0.0, d);
  vec3 col = mix(uDeep.rgb, uBase.rgb, diffuse);
  col = mix(col, uDeep.rgb, smoothstep(0.55, 1.0, uv.y) * 0.35); // under-panel

  // 2. Clear coat: hotspot + a sweeping reflection band.
  float spec = pow(max(0.0, 1.0 - d * 1.5), 5.0);
  col = mix(col, uBright.rgb, spec * 0.9);
  float bandPos = 0.15 + uLight.x * 0.35 + sin(uTime * 0.31) * 0.25;
  float band = (uv.x * 0.75 + uv.y * 0.35) - bandPos;
  col += uBright.rgb * 0.16 * exp(-band * band * 55.0);

  // 3. Flakes: fine + coarse, brightest near the light.
  float near = 0.35 + diffuse * 0.65 + spec;
  vec2 light = normalize(vec2(0.6, -0.8) + uLight * 0.9);
  col += flakes(px, uFlakeScale, light, 0.0, near);
  col += flakes(px + 31.7, uFlakeScale * 2.1, light.yx, 17.0, near) * 0.45;

  col = clamp(col, 0.0, 1.0);
  fragColor = vec4(col * uOpacity, uOpacity);
}
