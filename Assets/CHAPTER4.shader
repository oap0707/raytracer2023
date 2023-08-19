
// Fra https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509640(v=vs.85).aspx
//https://msdn.microsoft.com/en-us/library/windows/desktop/ff471421(v=vs.85).aspx
// rand num generator http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
// http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
// https://docs.unity3d.com/Manual/RenderDocIntegration.html
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html

Shader "Unlit/SingleColor"
{
	Properties
	{
	// inputs from gui, NB remember to also define them in "redeclaring" section
	_floatchooser("Move sphere along x axis", Range(-5,5)) = 0.0

	}

		SubShader{ Pass	{
			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		// redeclaring gui inputs
		float _floatchooser;

		typedef vector <float, 3> vec3;  // to get more similar code to book
		typedef vector <fixed, 3> col3;
	
	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};
	
	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}
	

	class ray {

		vec3 origin;
		vec3 direction;
		void make(vec3 _origin, vec3 _direction) {

		origin = _origin;
		direction = _direction;

		}

	};

	bool hit_sphere (vec3 center, float radius, ray r) {
	
		vec3 oc = r.origin - center;
		float a = dot(r.direction, r.direction);
		float b = 2.0 * dot(oc, r.direction);
		float c = dot(oc, oc) - radius*radius;
		float discriminant = b*b - 4*a*c;
		return (discriminant > 0);

	}


	col3 color (ray r) {
		
		if (hit_sphere(vec3(_floatchooser, 0,-1), 0.5, r)) { 
			return vec3(1,0,0);	
			}

		vec3 unit_vector = normalize(r.direction);
		float t = 0.5*(unit_vector.y + 1.0);
		return (1.0-t)*vec3(1.0,1.0,1.0) + t*vec3(0.5, 0.7,1.0); // can use lerp

	}


////////////////////////////////////////////////////////////////////////////////////////////////////////
	fixed4 frag(v2f i) : SV_Target
	{
		vec3 lower_left_corner = {-2, -1, -1};
		vec3 horizontal = {4, 0, 0};
		vec3 vertical = {0, 2, 0};
		vec3 origin = {0, 0, 0};

		float u = i.uv.x;
		float v = i.uv.y;

		ray r;
		r.make(origin, lower_left_corner + u*horizontal + v*vertical);
		col3 col = color(r);
		return fixed4(col,1);

	}
////////////////////////////////////////////////////////////////////////////////////


ENDCG

}}}