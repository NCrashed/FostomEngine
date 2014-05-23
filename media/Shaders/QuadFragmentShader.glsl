#version 330 core

// Ouput data
out vec4 color;

// Interpolated values from the vertex shaders
in vec2 UV;

in vec3 LightDirection_cameraspace;

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;

void main()
{
	// Material properties
	vec3 MaterialDiffuseColor = texture2D( myTextureSampler, UV ).rgb;

	color.rgb = MaterialDiffuseColor;
	color.a = texture2D( myTextureSampler, UV ).a;
}