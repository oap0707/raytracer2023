﻿
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
	_floatchooser4("Refrac idx of glass", Range(-5,5)) = 1.5
	_vec3chooser("Camera lookFrom pos", Vector) = (-2,2,1)
	_vec3chooser2("Camera lookAt pos", Vector) = (0,0,-1)
	_vec3chooser3("Camera vup", Vector) = (0,1,0)
	_floatchooser5("Ratio", Range(-50,50)) = 2

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
		float _floatchooser4;
		float _floatchooser5;
		vec3 _vec3chooser;
		vec3 _vec3chooser2;
		vec3 _vec3chooser3;
		
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
		float roughness; // controls roughness for metals, fuzz in the tutorial
		float refIdx; // index of refraction for dialectric

		void make(int _type, vec3 _albedo, float _roughness, float _refIdx) {
			type = _type;
			albedo = _albedo;
			roughness = _roughness;
			refIdx = _refIdx;
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
		void makeCam(vec3 _origin, vec3 llc, vec3 _horizontal, vec3 _vertical) {
			origin = _origin;
			lower_left_corner = llc;
			horizontal = _horizontal;
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

	/////////////////////////////////
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

	float hash12(float2 p)
{
    float3 p3 = fract(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
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
	//////////////////////////////////////

	void getsphere(int i, out Sphere sph) {
		// diffuse

		// Chapter 10 Camera Part 1
		//float R = cos(pi/4);
		//if (i == 0) {
		
			//material mat;
			//mat.make(0, vec3(0,0,1), 0, 0);
			//sph.make(vec3(-R, 0.0, -1.0), R, mat); // last element is diffuse or metal
		//}

		//if (i == 1) {
		
			//material mat;
			//mat.make(0, vec3(1,0,0), 0, 0);
			//sph.make(vec3(R, 0.0, -1), R, mat); // last element is diffuse or metal
		//}


		if (i == 0) {
		
			material mat;
			mat.make(0, vec3(0.1,0.2,0.5), 0, 0);
			sph.make(vec3(_floatchooser, 0.0, -1.0), 0.5, mat); // last element is diffuse or metal
		}
		if (i == 1) {
		
			material mat;
			mat.make(0, vec3(0.8,0.8,0.0), 0, 0);
			sph.make(vec3(0.0, -100.5, -1.0), 100.0, mat);
		}
		// metal
		if (i == 2) {

			material mat;
			mat.make(1, vec3(0.8,0.6,0.2), 0, 0);
			sph.make(vec3(1.0, 0.0, -1.0), 0.5, mat);
		}
		// dialectric
		if (i == 3) {

			material mat;
			mat.make(2, vec3(0.0,0.0,0.0), 0, _floatchooser4);
			sph.make(vec3(-1.0, 0.0, -1.0), 0.5, mat);
		}
		if (i == 4) {
		
			material mat;
			mat.make(2, vec3(0.0,0.0,0.0), 0, _floatchooser4);
			sph.make(vec3(-1.0, 0.0, -1.0), -0.45, mat);
		}
	}

	float schlick(float cosine, float refIdx) {

		float r0 = (1.0-refIdx) / (1.0+refIdx);
		r0 = r0*r0;
		return r0+(1.0-r0)*pow((1.0-cosine), 5.0);
	}


	bool refract(vec3 v, vec3 n, float niOverNt, out vec3 refracted) {
		vec3 uv = normalize(v);
		float dt = dot(uv, n);
		float discriminant = 1.0-niOverNt*niOverNt*(1.0-dt*dt);
		if(discriminant > 0.0)
		{
			refracted = niOverNt*(uv-n*dt)-n*sqrt(discriminant);
			return true;
		}
		return false;
	}

	vec3 reflect(vec3 v, vec3 n) {
		return v - 2*dot(v,n)*n;
	}

	bool hit_world(ray r, float t_min, float t_max, out hit_record rec) {
	
		bool hit_anything = false;
		rec.t = t_max; // closest so far
		hit_record temp_rec;
		int numberOfSpheres = 5; 

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
			rScattered.make(rec.p, reflected + rec.mat.roughness * random_unit_sphere(random));
			attenuation = rec.mat.albedo;
			return (dot(rScattered.direction, rec.normal) > 0);
			
		}

		if(rec.mat.type == 2) {

			attenuation = vec3(1.0, 1.0, 1.0);
			vec3 outwardNormal;
			float niOverNt;
			vec3 reflected = reflect(rIn.direction, rec.normal);
			vec3 refracted;
			float reflectProb;
			float cosine;

			if(dot(rIn.direction, rec.normal) > 0.0) {
				outwardNormal = -rec.normal;
				niOverNt = rec.mat.refIdx;
				cosine = rec.mat.refIdx * dot(rIn.direction, rec.normal) / length(rIn.direction); 
			}
			else {
				outwardNormal = rec.normal;
				niOverNt = 1.0 / rec.mat.refIdx;
				cosine = -dot(rIn.direction, rec.normal) / length(rIn.direction); 
			}

			if(refract(rIn.direction, outwardNormal, niOverNt, refracted)) {
				reflectProb = schlick(cosine, rec.mat.refIdx);
			}
			else {
				//rScattered.make(rec.p, reflected);
				reflectProb = 1.0;
			}

			if (hash12(random) < reflectProb) {
				rScattered.make(rec.p, reflected);
			}
			else {
				rScattered.make(rec.p, refracted);
			}

			return true;
		}

		return false;
	}

	//const float pi = 3.14159265358979;

	void makeCam(vec3 lookFrom, vec3 lookAt, vec3 vup, float vfov, float aspect, out Camera cam) {

		float theta = vfov * 3.14159265358979 / 180.0;
		float halfHeight = tan(theta * 0.5);
		float halfWidth = aspect * halfHeight;
		vec3 w = normalize(lookFrom - lookAt);
		vec3 u = normalize(cross(vup, w));
		vec3 v = cross(w, u);
		vec3 lower_left_corner = vec3(-halfWidth, -halfHeight, -1.0);
		lower_left_corner = lookFrom - halfWidth*u -halfHeight*v - w;
		vec3 horizontal = 2*halfWidth*u;
		vec3 vertical = 2*halfHeight*v;

		cam.makeCam(lookFrom, lower_left_corner, horizontal, vertical);
	}

	ray getRay(Camera cam, float s, float t) {
		ray r;
		r.make(cam.origin, cam.lower_left_corner + s*cam.horizontal + t*cam.vertical - cam.origin);
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
		int nx = 200;
		int ny = 100;

		//makeCame(_vec3chooser, _vec3chooser2, _vec3chooser3, 90, _floatchooser5);

		Camera cam;
		makeCam(vec3(-2,2,1), vec3(0,0,-1), vec3(0,1,0), 90, (float(nx)/float(ny)), cam);

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