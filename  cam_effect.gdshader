shader_type canvas_item;

// Estos 'uniforms' son valores que podremos ajustar desde el editor.
uniform float barrel_power : hint_range(0.0, 1.0) = 0.15; // Qué tan curva es la imagen.
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.8; // Qué tan oscuras son las esquinas.
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Normaliza las coordenadas de la pantalla para que el centro sea (0,0).
    vec2 centered_uv = UV - 0.5;

    // Calcula la distancia desde el centro de la pantalla.
    float dist = length(centered_uv);

    // Aplica la fórmula de distorsión de barril.
    // Esto "empuja" los píxeles hacia afuera desde el centro.
    centered_uv *= 1.0 + pow(dist, 2.5) * barrel_power;

    // Vuelve a convertir las coordenadas al rango normal (0 a 1).
    vec2 distorted_uv = centered_uv + 0.5;

    // Lee el color del píxel de la pantalla en la nueva coordenada distorsionada.
    vec4 color = texture(SCREEN_TEXTURE, distorted_uv);

    // Calcula el efecto de viñeta (oscurece las esquinas).
    float vignette = 1.0 - pow(dist * vignette_intensity, 2.0);
    
    // Aplica la viñeta al color del píxel.
    color.rgb *= vignette;

    // Si la coordenada distorsionada se sale de la pantalla, hazla transparente para evitar bordes raros.
    if (distorted_uv.x < -0.01 || distorted_uv.x > 1.01 || distorted_uv.y < -0.01 || distorted_uv.y > 1.01) {
        color.a = 0.0;
    }

    // Asigna el color final al píxel de la pantalla.
    COLOR = color;
}
