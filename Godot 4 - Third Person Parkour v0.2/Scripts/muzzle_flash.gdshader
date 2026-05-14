shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.75, 0.2, 1.0);
uniform float tip_x : hint_range(0.0, 1.0) = 0.0;

uniform float latch_intensity : hint_range(0.0, 2.0) = 0.0;
uniform vec2 latch_screen_uv = vec2(0.5, 0.5);
uniform vec2 gun_screen_uv = vec2(0.75, 0.85);
uniform vec4 latch_color : source_color = vec4(1.0, 0.2, 0.8, 1.0);

// Controls how tight/wide the glow falloff is
uniform float glow_radius : hint_range(0.01, 2.0) = 0.5;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = tex;

    // --- Flash effect (unchanged) ---
    float dist = abs(UV.x - tip_x);
    float gradient = clamp(1.0 - dist * 2.0, 0.0, 1.0);
    COLOR.rgb += flash_color.rgb * flash_intensity * tex.a * gradient;

    // --- Latch glow: directional lighting using UV pseudo-normal ---

    // Direction from gun center to latch in screen UV space
    vec2 to_latch = latch_screen_uv - gun_screen_uv;
    vec2 light_dir = length(to_latch) > 0.0001 ? normalize(to_latch) : vec2(0.0, 1.0);

    // Treat the UV offset from sprite center as a 2D surface normal.
    // Pixels on the side facing the latch will have a positive dot product.
    vec2 uv_centered = UV - vec2(0.5);
    float uv_len = length(uv_centered);
    vec2 pseudo_normal = uv_len > 0.001 ? uv_centered / uv_len : vec2(0.0);

    // Rim factor: edge pixels glow stronger (like fresnel)
    float rim = smoothstep(0.0, 0.5, uv_len);

    float facing = clamp(dot(pseudo_normal, light_dir), 0.0, 1.0);
    float light = facing * (0.35 + rim * 0.65);

    COLOR.rgb += latch_color.rgb * latch_intensity * light * tex.a;
}