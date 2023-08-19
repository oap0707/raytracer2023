
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
	_floatchooser2("Nmbr of rays per pxl", Range(0,1000)) = 100
	_floatchooser3("Max nmbr of bounces", Range(0,1000)) = 20
	_vec3chooser("Camera position origin", Vector) = (0,0,0)

	}
		SubShader{ Pass	{
			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		typedef vector <float, 3> vec3;  // to get more similar code to book
		typedef vector <fixed, 3> col3;

		// redeclaring gui inputs
		float _floatchooser;
		float _floatchooser2;
		float _floatchooser3;
		vec3 _vec3chooser;
		
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

		// constructor ish
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

		// constructor ish
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

	class Camera {

		vec3 origin;
		vec3 lower_left_corner;
		vec3 horizontal;
		vec3 vertical;

		// constructor ish
		void makeOrigin(vec3 _origin) {
			origin = _origin;
		}

		void makeLLC(vec3 llc) {
			lower_left_corner = llc;
		}

		void makeHorizontal(vec3 _horizontal) {
			horizontal = _horizontal;
		}

		void makeVertical(vec3 _vertical) {
			vertical = _vertical;
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

	float rand(in float2 uv) {
		float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233)*2.0)) * 43758.5453));
		return abs(noise.x + noise.y) * 0.5;
	}

	vec3 random_in_unit_sphere() {
		vec3 p;
		int numberOfSamples = 100;
		for(int s=0; s < numberOfSamples; s++) {

			do {
				p = 2.0*vec3(rand(float2(s, 0)), rand(float2(s, 1)), rand(float2(s, 2))) - vec3(1.0,1.0,1.0);
			}
			while ((p.x * p.x + p.y * p.y + p.z * p.z) >= 1.0);
		}
		return p;
	}

	vec3 random_in_unit_sphere0(float2 random) {
		vec3 p;
		do {
			p = 2.0*vec3(rand(random), rand(random), rand(random)) - vec3(1.0,1.0,1.0);
		}
		//while ((p.x * p.x + p.y * p.y + p.z * p.z) >= 1.0);
		while (dot(p,p) >= 1.0);
		
		return p;
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

	ray getRay(Camera cam, float u, float v) {
		ray r;
		r.make(cam.origin, cam.lower_left_corner + u*cam.horizontal + v*cam.vertical - cam.origin);
		return r;
	
	}

	vec3 skyColor(ray r) {
		vec3 unit_direction = normalize(r.direction);
		float t = 0.5 * (unit_direction.y + 1.0);

		return (1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0);
	}


	col3 color2 (ray r, float2 random) { 

		hit_record rec;
		vec3 accumCol = {1.0, 1.0, 1.0};

		bool foundhit = hit_world(r, 0.001, 10000.0, rec);
		int maxC = _floatchooser3; // number of bounces 
		while (foundhit && (maxC>0)) {
			maxC--;
			vec3 target = rec.p + rec.normal + random_in_unit_sphere0(random);
			r.make(rec.p, target-rec.p);
			accumCol = 0.5*accumCol;
			foundhit = hit_world(r, 0.001, 10000.0, rec);
		}
		if (foundhit && maxC == 0) {
			return col3(0, 0, 0);
		}
		return accumCol*skyColor(r);

	}


////////////////////////////////////////////////////////////////////////////////////////////////////////
	fixed4 frag(v2f i) : SV_Target
	{
		vec3 lower_left_corner = {-2, -1, -1};
		vec3 horizontal = {4, 0, 0};
		vec3 vertical = {0, 2, 0};
		vec3 origin = {0, 0, 0};

		// number of samples means how many rays we send through each pixel
		int numberOfSamples = _floatchooser2;
		int nx = 200;
		int ny = 100;

		Camera cam;
		cam.makeOrigin(_vec3chooser);
		cam.makeVertical(vertical);
		cam.makeHorizontal(horizontal);
		cam.makeLLC(lower_left_corner);

		vec3 col = vec3(0,0,0);
		for (int s = 0; s < numberOfSamples; s++) {
			
			float random = rand(float2(s, 0+s));
			float u = i.uv.x + random / nx;
			float v = i.uv.y + random / ny;

			ray r = getRay(cam, u, v);
			vec3 p = r.point_at_parameter(2.0);
			col += color2(r, random);
		}

		col /= float(numberOfSamples);

		// gamma
		col = vec3(sqrt(col[0]), sqrt(col[1]), sqrt(col[2]));

		return fixed4(col,1);

	} 
////////////////////////////////////////////////////////////////////////////////////


ENDCG

}}}