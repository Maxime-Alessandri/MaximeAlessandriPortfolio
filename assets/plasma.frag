#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 iResolution;
    float iTime;
    vec3 uCustomColor;
    float uUseCustomColor;
    float uSpeed;
    float uDirection;
    float uScale;
    float uOpacity;
    vec2 uMouse;
    float uMouseInteractive;
};

void mainImage(out vec4 o, vec2 C) {
    vec2 center = iResolution.xy * 0.5;
    C = (C - center) / max(uScale, 0.001) + center;
    vec2 mouseOffset = (uMouse - center) * 0.0002;
    C += mouseOffset * length(C - center) * step(0.5, uMouseInteractive);
    float i = 0.0;
    float d = 0.0;
    float z = 0.0;
    float T = iTime * uSpeed * uDirection;
    vec3 O = vec3(0.0);
    vec3 p = vec3(0.0);
    vec3 S = vec3(0.0);
    vec2 r = iResolution.xy;
    for (i = 0.0; i < 40.0; i += 1.0) {
        p = z * normalize(vec3(C - 0.5 * r, r.y));
        p.z -= 4.0;
        S = p;
        d = p.y - T;
        p.x += 0.4 * (1.0 + p.y) * sin(d + p.x * 0.1) * cos(0.34 * d + p.x * 0.05);
        vec4 qConst = p.y + vec4(0.0, 11.0, 33.0, 0.0) - T;
        mat2 rot = mat2(cos(qConst.x), -sin(qConst.y), sin(qConst.z), cos(qConst.w));
        p.xz = rot * p.xz;
        vec2 Q = p.xz;
        d = abs(sqrt(dot(Q, Q)) - 0.25 * (5.0 + S.y)) / 3.0 + 8e-4;
        z += d;
        o = 1.0 + sin(S.y + p.z * 0.5 + S.z - length(S - p) + vec4(2.0, 1.0, 0.0, 8.0));
        O += (o.w / max(d, 0.0001)) * o.xyz;
    }
    o.xyz = tanh(O / 1e4);
}

bool finite1(float x) { return !(isnan(x) || isinf(x)); }
vec3 sanitize(vec3 c) {
    return vec3(
        finite1(c.r) ? c.r : 0.0,
        finite1(c.g) ? c.g : 0.0,
        finite1(c.b) ? c.b : 0.0
    );
}

void main() {
    vec2 fragCoord = vec2(qt_TexCoord0.x * iResolution.x, (1.0 - qt_TexCoord0.y) * iResolution.y);
    vec4 o = vec4(0.0);
    mainImage(o, fragCoord);
    vec3 rgb = sanitize(o.rgb);
    float intensity = (rgb.r + rgb.g + rgb.b) / 3.0;
    vec3 customColor = intensity * uCustomColor * 1.5;
    vec3 finalColor = mix(rgb, customColor, step(0.5, uUseCustomColor));
    float alpha = length(rgb) * uOpacity * qt_Opacity;
    fragColor = vec4(finalColor * alpha, alpha);
}
