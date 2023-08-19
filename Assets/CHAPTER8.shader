
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


	// diffuse material is type 0
	// metal material is type 1
	// dialectric material is type 2
	class material {
		int type;
		vec3 albedo;
		float roughness; // controls roughness for metals
		//float refIdx; // index of refraction for dialectric

		void make(int _type, vec3 _albedo, float _roughness) {
			type = _type;
			albedo = _albedo;
			roughness = _roughness;
		}

	};


	class Sphere {

		vec3 center;
		float radius;
		material mat;

		// constructor ish
		void make(vec3 _center, float _radius, material _material) {

		center = _center;
		radius = _radius;
		mat = _material;
		}
	};

	class hit_record {

		float t;
		vec3 p;
		vec3 normal;
		material mat;

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

		void makeM (material _mat) {
			mat = _mat;
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
				rec.makeM(sph.mat);
				return true;
			}

			temp = (-b + sqrt(b*b - a*c)) / a;
			if (temp < t_max && temp > t_min) {

				rec.makeT(temp);
				rec.makeP(r.point_at_parameter(rec.t));
				rec.makeN((rec.p - sph.center) / sph.radius);
				rec.makeM(sph.mat);
				return true;
			}

		}
		return false;

	}

	float rand(in float2 uv) {
		float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233)*2.0)) * 43758.5453));
		return abs(noise.x + noise.y) * 0.5;
	}

	float fract(const float x)
	{
		return x - floor(x);
	}

	float2 fract(const float2 f)
	{
		return float2(f.x - floor(f.x),f.y - floor(f.y));
	}

	float3 fract(const float3 f)
	{
		return float3(f.x - floor(f.x),f.y - floor(f.y),f.z - floor(f.z));
	}

	float hash11(float p)
	{
		p = fract(p * .1031);
		p *= p + 33.33;
		p *= p + p;
		return fract(p);
	}

	float3 hash31(const float p)
{
    float3 p3 = fract(p * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

	float3 hash33(float3 p3) {

		p3 = fract(p3 * float3(.1031, .1030, .0973));
		p3 += dot(p3, p3.yxz + 33.33);
		return fract((p3.xxy + p3.yxx) * p3.zyx);
	}

	float square_length(float3 vec) 
	{
		return vec.x * vec.x + vec.y * vec.y + vec.z * vec.z;
	}


	static float hashed = 235706.14367;
	float3 random3(const float seed)
	{
		hashed = hash11(seed + hashed *  883);
		const float3 t3 = hash31(seed + hashed *  727);

		return t3;
	}

	float3 random_unit_sphere(const float seed)
	{
		float3 vec = 0;

		do
		{
			vec = 2.0 * random3(float3(seed + vec.z*100,100*vec.x+seed,vec.y*100+seed)) - 1;
		}
		while (square_length(vec) >= 1.0);

		return vec;
	}


	void getsphere(int i, out Sphere sph) {
		// diffuse
		if (i == 0) {

			material mat;
			mat.make(0, vec3(0.8,0.3,0.3), 0);
			sph.make(vec3(_floatchooser, 0.0, -1.0), 0.5, mat); // last element is diffuse or metal
		}
		if (i == 1) {

			material mat;
			mat.make(0, vec3(0.8,0.8,0.0), 0);
			sph.make(vec3(0.0, -100.5, -1.0), 100.0, mat);
		}
		// metal
		if (i == 2) {

			material mat;
			mat.make(1, vec3(0.8,0.6,0.2), 1.0);
			sph.make(vec3(1.0, 0.0, -1.0), 0.5, mat);
		}
		if (i == 3) {
			
			material mat;
			mat.make(1, vec3(0.8,0.8,0.8), 0.3);
			sph.make(vec3(-1.0, 0.0, -1.0), 0.5, mat);
		}
	}

	vec3 reflect(vec3 v, vec3 n) {
		return v - 2*dot(v,n)*n;
	}

	bool hit_world(ray r, float t_min, float t_max, out hit_record rec) {
	
		bool hit_anything = false;
		rec.t = t_max; // closest so far
		hit_record temp_rec;
		int numberOfSpheres = 4;

		for (int i = 0; i < numberOfSpheres; i++) {
			
			Sphere sph;
			getsphere(i, sph);

			if(hitSphere(sph, r, t_min, rec.t, temp_rec)) {
				hit_anything = true;
				rec = temp_rec;
			}

		}

		return hit_anything;
	}

	bool scatter(ray rIn, hit_record rec, float2 random, out vec3 attenuation, out ray rScattered) {

		if(rec.mat.type == 0) {
			vec3 target = rec.p + rec.normal + random_unit_sphere(random);
			rScattered.make(rec.p, target - rec.p);
			attenuation = rec.mat.albedo;
			return true;
		}

		if(rec.mat.type == 1) {
			vec3 reflected = reflect(normalize(rIn.direction), rec.normal);
			rScattered.make(rec.p, reflected); 
			attenuation = rec.mat.albedo;
			return (dot(rScattered.direction, rec.normal) > 0);
			
		}
		else return false;

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

	col3 color (ray r, float2 random) { 

		hit_record rec;
		vec3 accumCol = {1.0, 1.0, 1.0};

		bool foundhit = hit_world(r, 0.001, 10000.0, rec);
		int maxC = _floatchooser3; // number of bounces 
		while (foundhit && (maxC>0)) {
			maxC--;

			ray scatterRay;
			vec3 attenuation;
			if(scatter(r, rec, random, attenuation, scatterRay)){
				
				accumCol *= attenuation;
				r = scatterRay;
				//foundhit = hit_world(r, 0.001, 10000.0, rec);
			}
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
		int nx = 2000;
		int ny = 1000;

		Camera cam;
		cam.makeOrigin(_vec3chooser);
		cam.makeVertical(vertical);
		cam.makeHorizontal(horizontal);
		cam.makeLLC(lower_left_corner);

		vec3 col = vec3(0,0,0);
		for (int s = 0; s < numberOfSamples; s++) {
			
			//float u = i.uv.x + hash11(s) / nx;
			//float v = i.uv.y + hash11(s) / ny;

			float u = i.uv.x + rand(float2(i.uv.x, s)) / nx;
			float v = i.uv.y + rand(float2(i.uv.y, s)) / ny;

			ray r = getRay(cam, u, v);
			vec3 p = r.point_at_parameter(2.0);
			col += color(r, hash33(float3(s,u,v)));
		}

		col /= float(numberOfSamples);

		// gamma
		col = vec3(sqrt(col[0]), sqrt(col[1]), sqrt(col[2]));

		return fixed4(col,1);

	} 
////////////////////////////////////////////////////////////////////////////////////


ENDCG

}}}