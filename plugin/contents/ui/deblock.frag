// Light deblocking filter, run by the graphics card.
// Bilateral smoothing: each pixel is averaged with 8 neighbours (diagonals at
// "radius", axes at half of it), a neighbour only counting when its colour is
// close. Steps of a few levels (blocks and banding of low bitrate H.264) are
// smoothed, real edges stay sharp. A noise of one and a half levels then
// breaks the remaining steps.

varying highp vec2 qt_TexCoord0;
uniform sampler2D source;
uniform lowp float qt_Opacity;
uniform highp vec2 texel;
uniform highp float radius;
uniform highp float threshold;
uniform highp float amount;

void addTap(highp vec2 p, lowp vec3 c, inout highp vec3 sum, inout highp float wsum)
{
    lowp vec3 s = texture2D(source, p).rgb;
    highp vec3 d = abs(s - c);
    highp float w = 1.0 - smoothstep(threshold * 0.5, threshold, max(d.r, max(d.g, d.b)));
    sum += s * w;
    wsum += w;
}

void main()
{
    highp vec2 uv = qt_TexCoord0;
    lowp vec3 c = texture2D(source, uv).rgb;
    highp vec2 r1 = texel * radius;
    highp vec2 r2 = r1 * 0.5;
    highp vec3 sum = c;
    highp float wsum = 1.0;

    addTap(uv + vec2( r1.x,  r1.y), c, sum, wsum);
    addTap(uv + vec2(-r1.x,  r1.y), c, sum, wsum);
    addTap(uv + vec2( r1.x, -r1.y), c, sum, wsum);
    addTap(uv + vec2(-r1.x, -r1.y), c, sum, wsum);
    addTap(uv + vec2( r2.x,  0.0), c, sum, wsum);
    addTap(uv + vec2(-r2.x,  0.0), c, sum, wsum);
    addTap(uv + vec2( 0.0,  r2.y), c, sum, wsum);
    addTap(uv + vec2( 0.0, -r2.y), c, sum, wsum);

    highp vec3 col = mix(c, sum / wsum, amount);
    highp float n = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
    col += n * (1.5 / 255.0) * amount;
    gl_FragColor = vec4(col, 1.0) * qt_Opacity;
}
