// PSX-стиль: "дрожание" вершин (vertex snapping) + аффинное текстурирование,
// как на PlayStation 1. Повесить ShaderMaterial с этим шейдером на меш.
// Параметры в инспекторе материала:
//   albedo_tex      - текстура (пиксельная, без фильтрации)
//   snap_resolution - чем меньше, тем сильнее дрожат вершины (PS1 ~ 160-320)
//   affine_amount   - 1.0 = полное аффинное искажение текстур, 0.0 = выкл
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform vec4 tint : source_color = vec4(1.0);
uniform float snap_resolution : hint_range(32.0, 640.0) = 240.0;
uniform float affine_amount : hint_range(0.0, 1.0) = 1.0;

varying float v_w;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	// привязка вершин к "сетке" низкого разрешения
	vec2 grid = vec2(snap_resolution, snap_resolution * 0.75);
	clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	POSITION = clip;
	v_w = clip.w;
	// аффинное текстурирование: умножаем UV на w в вершине...
	UV = mix(UV, UV * clip.w, affine_amount);
}

void fragment() {
	// ...и делим обратно во фрагменте — получаем PS1-искажение текстур
	vec2 uv = mix(UV, UV / v_w, affine_amount);
	vec4 tex = texture(albedo_tex, uv) * tint;
	ALBEDO = tex.rgb;
}
