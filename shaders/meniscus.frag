// 折射场移植自 VII-Cae/hyalite--liquid-glass hyalite.js v0.5.0,MIT © 2026 VII-Cae。
// 料、GGX 高光、高度场移植自 TangfanOVO/qiaosi components/liquid-glass/liquid-core.js,AGPL-3.0。

#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uTex;       // ImageFilter.shader 要求第一个 uniform 是它
uniform vec2 uSize;
uniform vec2 uOrigin;
uniform vec2 uScale;
uniform vec4 uWall;
uniform float uRadius;
uniform float uThick;
uniform float uIor;
uniform float uBevel;
uniform float uSlab;
uniform float uSlope;
uniform float uMaxd;
uniform float uDispPx;
uniform float uRingSat;
uniform vec4 uTintCol;
uniform float uSat;
uniform float uSpec;
uniform vec2 uLight;
uniform float uLive;

uniform sampler2D uBg;

out vec4 fragColor;

vec3 bgAt(vec2 p) {
  if (uLive > 0.5) {
    vec2 uv = clamp((p * uScale + uOrigin) / uTex, vec2(0.0), vec2(1.0));
#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
    uv.y = 1.0 - uv.y;
#endif
    return texture(uBg, uv).rgb;
  }
  vec2 uv = clamp((p - uWall.xy) / uWall.zw, vec2(0.0), vec2(1.0));
  return texture(uBg, uv).rgb;
}

vec3 bgSoft(vec2 p, float r) {
  if (r < 0.35) return bgAt(p);
  vec3 c = bgAt(p) * 0.36;
  c += bgAt(p + vec2(r, 0.0)) * 0.16;
  c += bgAt(p - vec2(r, 0.0)) * 0.16;
  c += bgAt(p + vec2(0.0, r)) * 0.16;
  c += bgAt(p - vec2(0.0, r)) * 0.16;
  return c;
}

float sdBoxR(vec2 p, float radius) {
  vec2 hs = uSize * 0.5;
  float r = min(radius, min(hs.x, hs.y));
  vec2 q = abs(p - hs) - hs + r;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float sdBox(vec2 p) { return sdBoxR(p, uRadius); }

float hSquircle(float t) { return pow(max(0.0, 1.0 - pow(1.0 - t, 4.0)), 0.25); }
float hCircle(float t) { return sqrt(max(0.0, 1.0 - (1.0 - t) * (1.0 - t))); }

float profileDisp(float d) {
  float x = clamp(d / uBevel, 0.0, 1.0);
  float x1 = min(1.0, x + 1e-3), x0 = max(0.0, x - 1e-3);
  float a = atan((hSquircle(x1) - hSquircle(x0)) / (x1 - x0));
  float b = sign(a) * asin(min(1.0, sin(abs(a)) / uIor));
  return (uSlab + uBevel * hCircle(x)) * tan(a - b);
}

float bend(float d) {
  float span = max(uBevel - d, 0.0);
  float m = uSlope * span;
  for (int i = 0; i < 24; i++) {
    float s = span * float(i) / 24.0;
    m = min(m, profileDisp(d + s) + uSlope * s);
  }
  return m;
}

float ggx(vec3 n, vec3 v, vec3 l, float rough) {
  vec3 h = normalize(v + l);
  float a = max(rough * rough, 1e-3);
  float ndh = max(dot(n, h), 0.0), ndl = max(dot(n, l), 0.0), ndv = max(dot(n, v), 0.0);
  if (ndl <= 0.0 || ndv <= 0.0) return 0.0;
  float dd = ndh * ndh * (a * a - 1.0) + 1.0;
  float D = (a * a) / (3.14159265 * dd * dd);
  float k = a * 0.5;
  float G = (ndl / (ndl * (1.0 - k) + k)) * (ndv / (ndv * (1.0 - k) + k));
  return (D * G) / (4.0 * ndl * ndv);
}

void main() {
  vec2 p = (FlutterFragCoord().xy - uOrigin) / uScale;
  float d = sdBox(p);
  if (d > 1.0) {
    fragColor = uLive > 0.5 ? vec4(bgAt(p), 1.0) : vec4(0.0);
    return;
  }
  float aa = 1.0 - smoothstep(-1.0, 1.0, d);
  float thick = max(uThick, 1.0);

  float e = clamp(-d / thick, 0.0, 1.0);
  float h = sqrt(max(0.0, 1.0 - (1.0 - e) * (1.0 - e)));
  float slope = (1.0 - e) / max(h, 0.08);
  vec2 g = normalize(vec2(sdBox(p + vec2(1.0, 0.0)) - d, sdBox(p + vec2(0.0, 1.0)) - d) + 1e-6);
  vec3 n = normalize(vec3(-g * slope * 0.95, 1.0));
  vec3 v = vec3(0.0, 0.0, 1.0);
  float rim = 1.0 - h;

  float depth = max(-d, 0.0);
  float m = depth < uBevel ? bend(depth) : 0.0;
  float rDir = min(uRadius + uBevel, min(uSize.x, uSize.y) * 0.5 - 0.5);
  vec2 gDir = normalize(vec2(sdBoxR(p + vec2(0.5, 0.0), rDir) - sdBoxR(p - vec2(0.5, 0.0), rDir),
                             sdBoxR(p + vec2(0.0, 0.5), rDir) - sdBoxR(p - vec2(0.0, 0.5), rDir)) + 1e-6);
  float k = m / max(uMaxd, 1e-3);
  vec3 col;
  for (int i = 0; i < 3; i++) {
    float off = m + (float(i) - 1.0) * uDispPx * k;
    col[i] = bgSoft(p - gDir * off, 1.0)[i];
  }
  float ring = clamp((abs(gDir.x) + abs(gDir.y)) * k, 0.0, 1.0);
  col = mix(col, mix(vec3(dot(col, vec3(0.2126, 0.7152, 0.0722))), col, uRingSat), ring);

  vec3 around = bgSoft(p, 6.0);
  float lum = dot(around, vec3(0.2126, 0.7152, 0.0722));
  float adapt = smoothstep(0.45, 0.95, lum) * 0.16;
  col = mix(vec3(dot(col, vec3(0.2126, 0.7152, 0.0722))), col, uSat);
  col = mix(col, uTintCol.rgb, clamp(uTintCol.a + adapt, 0.0, 0.92));

  float f0 = pow((uIor - 1.0) / (uIor + 1.0), 2.0);
  float support = smoothstep(0.42, 1.0, rim);
  float lAng = atan(uLight.y, uLight.x);
  vec3 spec = vec3(0.0);
  vec3 l = normalize(vec3(uLight, 0.82));
  for (int i = 0; i < 4; i++) {
    float a = lAng + float(i) * 1.5708 + 0.34;
    vec3 li = normalize(vec3(cos(a) * 0.94, sin(a) * 0.94, 0.30 + float(i) * 0.035));
    float w = 1.0 - float(i) * 0.19;
    vec3 warm = mix(vec3(1.0, 0.985, 0.96), vec3(0.955, 0.975, 1.0), float(i) / 3.0);
    vec3 hv = normalize(v + li);
    float fr = f0 + (1.0 - f0) * pow(1.0 - max(dot(hv, v), 0.0), 5.0);
    spec += warm * ggx(n, v, li, 0.32) * fr * w;
  }
  col += min(spec * uSpec * 0.014, vec3(0.85)) * support;

  float contour = exp(-pow(abs(d + 0.8) / 1.0, 2.0));
  vec3 env = bgSoft(p + g * 2.0, 1.5);
  float envL = dot(env, vec3(0.2126, 0.7152, 0.0722));
  vec3 deep = mix(vec3(envL), env, 1.35) * 0.55;
  vec3 bright = mix(env, vec3(1.0), 0.7);
  float diag = dot(g, normalize(vec2(-1.0, -1.0)));
  float glint = pow(max(diag, 0.0), 1.6) + 0.6 * pow(max(-diag, 0.0), 1.6);
  float up = max(glint, (1.0 - smoothstep(0.35, 0.75, envL)) * 0.5);
  vec3 edge = mix(deep, bright, up);
  col = mix(col, edge, contour * mix(0.3, 0.5, up));

  if (uLive > 0.5) {
    fragColor = vec4(mix(bgAt(p), clamp(col, 0.0, 1.0), aa), 1.0);
    return;
  }
  fragColor = vec4(clamp(col, 0.0, 1.0) * aa, aa);
}
