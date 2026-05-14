shader_type canvas_item;

  uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
  uniform float pixel_size : hint_range(1.0, 32.0) = 1.0;
  uniform vec2 viewport_size = vec2(1280.0, 720.0);

  void fragment() {
      vec2 pixelated_uv = floor(UV * viewport_size / pixel_size) * pixel_size / viewport_size;
      COLOR = texture(SCREEN_TEXTURE, pixelated_uv);
  }
