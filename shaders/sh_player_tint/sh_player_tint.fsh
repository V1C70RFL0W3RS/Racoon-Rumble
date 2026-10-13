varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 u_mid;    // reemplazo del pelaje medio
uniform vec3 u_light;  // reemplazo del pelaje claro

// Colores clave del mapache original (0..1). TODO sprite debe usar exactamente estos.
const vec3 KEY_MID   = vec3(114.0, 109.0, 103.0) / 255.0; // #726D67
const vec3 KEY_LIGHT = vec3(177.0, 168.0, 161.0) / 255.0; // #B1A8A1
// Tolerancia chica y no igualdad exacta: las GPUs móviles tienen menos precisión.
const float TOL = 0.02;

void main()
{
    vec4 src = texture2D(gm_BaseTexture, v_vTexcoord);
    vec3 rgb = src.rgb;
    rgb = mix(rgb, u_mid,   step(distance(src.rgb, KEY_MID),   TOL));
    rgb = mix(rgb, u_light, step(distance(src.rgb, KEY_LIGHT), TOL));
    gl_FragColor = vec4(rgb, src.a) * v_vColour;
}