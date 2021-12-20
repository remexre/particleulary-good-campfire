#version 330

in vec2 texCoordsFrag;
in vec4 wsNormals;

out vec4 color;

void main() { color = vec4(((wsNormals + vec4(1)) / 2).rgb, 0.5); }
