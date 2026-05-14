shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0, 0.36, 1.0, 1.0);
uniform vec4 emission_color : source_color = vec4(0.6, 0.05, 0.9, 1.0);
uniform float emission_energy : hint_range(0.0, 30.0) = 8.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_depth : hint_range(0.0, 1.0) = 0.35;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
uniform float rim_strength : hint_range(0.0, 5.0) = 2.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	pulse = pulse * pulse_depth + (1.0 - pulse_depth);

	// Fresnel rim — bright edge toward camera
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - ndotv, rim_power);

	ALBEDO = base_color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;

	vec3 core_emit = emission_color.rgb * emission_energy * pulse;
	vec3 rim_emit  = base_color.rgb * rim * rim_strength * pulse;
	EMISSION = core_emit + rim_emit;
	ALPHA = base_color.a;
}
