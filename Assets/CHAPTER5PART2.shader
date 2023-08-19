
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
		float _floatchooser;;

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

		vec3 point_at_parameter(float t) {
			return origin + t * direction;
		}

	};


	class Sphere {

		vec3 center;
		float radius;

		// constructor ish
		void make(vec3 _center, float _radius) {

		center = _center;
		radius = _radius;

		}
	};

	class hit_record {

		float t;
		vec3 p;
		vec3 normal;

		void makeT (float _t) {
			t = _t;
		}

		void makeP (vec3 _p) {
			p = _p;
		}

		void makeN (vec3 _normal) {
			normal = _normal;
		}


	};

	bool hitSphere (Sphere sph, ray r, float t_min, float t_max, out hit_record rec) {

		vec3 oc = r.origin - sph.center;
		float a = dot(r.direction, r.direction);
		float b = dot(oc, r.direction);
		float c = dot(oc, oc) - sph.radius*sph.radius;
		float discriminant = b*b - a*c;
		if (discriminant > 0.0) {

			float temp = (-b - sqrt(b*b-a*c)) / a;
			if (temp < t_max && temp > t_min) {

				rec.makeT(temp);
				rec.makeP(r.point_at_parameter(rec.t));
				rec.makeN((rec.p - sph.center) / sph.radius);
				return true;
			}

			temp = (-b + sqrt(b*b - a*c)) / a;
			if (temp < t_max && temp > t_min) {

				rec.makeT(temp);
				rec.makeP(r.point_at_parameter(rec.t));
				rec.makeN((rec.p - sph.center) / sph.radius);
				return true;
			}

		}
		return false;

	}

	void getsphere(int i, out Sphere sph) {
		if (i == 0) {
			sph.make(vec3(_floatchooser, 0.0, -1.0), 0.5);
		}
		if (i == 1) {
			sph.make(vec3(0.0,-100.5, -1.0), 100.0);
		}
	}


	bool hit_world(ray r, float t_min, float t_max, out hit_record rec) {
	
		bool hit_anything = false;
		rec.t = t_max; // closest so far
		hit_record temp_rec;

		for (int i = 0; i < 2; i++) {
			
			Sphere sph;
			getsphere(i, sph);

			if(hitSphere(sph, r, t_min, rec.t, temp_rec)) {
				hit_anything = true;
				rec = temp_rec;
			}

		}

		return hit_anything;
	}


	col3 color (ray r) { 

		hit_record rec;

		if(hit_world(r, 0.0, 1000.0, rec)) { 
			return 0.5*vec3(rec.normal.x+1, rec.normal.y+1, rec.normal.z+1);
		}
		else { // the sky
			vec3 unit_vector = normalize(r.direction);
			float t = 0.5*(unit_vector.y + 1.0);
			return (1.0-t)*vec3(1.0,1.0,1.0) + t*vec3(0.5, 0.7, 1.0);
		}
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

		vec3 p = r.point_at_parameter(2.0);
		vec3 col = color(r); 
		return fixed4(col,1);

	} 
////////////////////////////////////////////////////////////////////////////////////


ENDCG

}}}