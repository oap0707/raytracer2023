
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
		[Toggle] _boolchooser("myBool", Range(0,1)) = 0  // [Toggle] creates a checkbox in gui and gives it 0 or 1
		_floatchooser("myFloat", Range(-1,1)) = 0
		_colorchooser("myColor", Color) = (1,0,0,1)
		_vec4chooser("myVec4", Vector) = (0,0,0,0)
		//_texturechooser("myTexture", 2D) = "" {} // "" er for bildefil, {} er for options
	}

		SubShader{ Pass	{

	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

	// redeclaring gui inputs
	int _boolchooser;
	float _floatchooser;
	float4 _colorchooser;// alternative use fixed4;  range of –2.0 to +2.0 and 1/256th precision. (https://docs.unity3d.com/Manual/SL-DataTypesAndPrecision.html)
	float4 _vec4chooser;
	//sampler2D _texturechooser;


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



////////////////////////////////////////////////////////////////////////////////////////////////////////
	class ray
	{
		vec3 origin;
		vec3 direction;
		void make(vec3 orig, vec3 dir)
		{
			origin = orig;
			direction = dir;
		}
		vec3 point_at_parameter(float t)
		{
			return origin + t * direction;
		}
	};


	float hit_sphere(vec3 center, float radius, ray r)
	{
		vec3 oc = r.origin - center;
		float a = dot(r.direction, r.direction);
		float b = 2.0 * dot(oc, r.direction);
		float c = dot(oc, oc) - radius * radius;
		float discriminant = b * b - 4 * a * c;
		if (discriminant < 0)
		{
			return -1.0;
		}
		else
		{
			return (-b - sqrt(discriminant)) / (2.0 * a);
		}
	}

	class camera
	{
		vec3 origin;
		vec3 lower_left_corner;
		vec3 horizontal;
		vec3 vertical;

		void make()
		{
			origin = vec3(0.0, 0.0, 0.0);
			lower_left_corner = vec3(-2.0, -1.0, -1.0);
			horizontal = vec3(4.0, 0.0, 0.0);
			vertical = vec3(0.0, 2.0, 0.0);
		}

		ray get_ray(float u, float v)
		{
			ray r;
			r.make(origin, lower_left_corner + u * horizontal + v * vertical - origin);
			return r;
		}
	};

	col3 skycolor(ray r) 
	{
		vec3 unit_direction = normalize(r.direction);
		float t = 0.5 * (unit_direction.y + 1.0);
		return (1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0);
	}

	class material
	{
		bool isMetal;
		vec3 albedo;
		float fuzz;

		void make(vec3 a, bool metal, float f)
		{
			albedo = a;
			isMetal = metal;
			fuzz = f;
		}
	};

	struct hit_record
	{
		float t;
		vec3 p;
		vec3 normal;
		material mat;
	};

	class sphere
	{
		vec3 center;
		float radius;
		material mat;
		void make(vec3 cen, float r, material m)
		{
			center = cen;
			radius = r;
			mat = m;
		}
		bool hit(ray r, float tmin, float tmax, out hit_record rec)
		{
			vec3 oc = r.origin - center;
			float a = dot(r.direction, r.direction);
			float b = dot(oc, r.direction);
			float c = dot(oc, oc) - radius * radius;
			float discriminant = b * b - a * c;
			if (discriminant > 0)
			{
				float temp = (-b - sqrt(b * b - a * c)) / a;
				if (temp < tmax && temp > tmin)
				{
					rec.t = temp;
					rec.p = r.point_at_parameter(rec.t);
					rec.normal = (rec.p - center) / radius;
					rec.mat = mat;
					return true;
				}
				temp = (-b + sqrt(b * b - a * c)) / a;
				if (temp < tmax && temp > tmin)
				{
					rec.t = temp;
					rec.p = r.point_at_parameter(rec.t);
					rec.normal = (rec.p - center) / radius;
					rec.mat = mat;
					return true;
				}
			}
			return false;
		}
	};

	bool hit_sphere(sphere sph, ray r, float tmin, float tmax, out hit_record rec)
	{
		vec3 oc = r.origin - sph.center;
		float a = dot(r.direction, r.direction);
		float b = dot(oc, r.direction);
		float c = dot(oc, oc) - sph.radius * sph.radius;
		float discriminant = b * b - a * c;
		if (discriminant > 0)
		{
			float temp = (-b - sqrt(b * b - a * c)) / a;
			if (temp < tmax && temp > tmin)
			{
				rec.t = temp;
				rec.p = r.point_at_parameter(rec.t);
				rec.normal = (rec.p - sph.center) / sph.radius;
				rec.mat = sph.mat;
				return true;
			}
			temp = (-b + sqrt(b * b - a * c)) / a;
			if (temp < tmax && temp > tmin)
			{
				rec.t = temp;
				rec.p = r.point_at_parameter(rec.t);
				rec.normal = (rec.p - sph.center) / sph.radius;
				rec.mat = sph.mat;
				return true;
			}
		}
		return false;
	}


	void getMat(int index, out material mat)
	{
		if (index == 0) { mat.make(vec3(0.8, 0.3, 0.3), false, 0.0); }
		if (index == 1) { mat.make(vec3(0.8, 0.8, 0.0), false, 0.0); }
		if (index == 2) { mat.make(vec3(0.8, 0.6, 0.2), true, 0.3); }
		if (index == 3) { mat.make(vec3(0.8, 0.8, 0.8), true, 0.1); }
	}

	void getsphere(int i, out sphere sph)
	{
		material mat;
		if (i == 0)
		{
			sph.center = vec3(0, 0, -1);
			sph.radius = 0.5;
			getMat(0, mat);
			sph.mat = mat;
		}
		if (i == 1) 
		{ 
			sph.center = vec3(0, -100.5, -1);
			sph.radius = 100;
			getMat(1, mat);
			sph.mat = mat;
		}
		if (i == 2) 
		{ 
			sph.center = vec3(1, 0, -1); 
			sph.radius = 0.5;
			getMat(2, mat);
			sph.mat = mat;
		}
		if (i == 3) 
		{ 
			sph.center = vec3(-1, 0, -1); 
			sph.radius = 0.5; 
			getMat(3, mat);
			sph.mat = mat; 
		}
	}

	bool hit(ray r, float tmin, float tmax, out hit_record rec)
	{
		hit_record temp_rec;
		bool hit_anything = false;
		float closest_so_far = tmax;
		sphere sph;

		for (int i = 0; i < 4; i++) 
		{
			getsphere(i, sph);

			if (hit_sphere(sph, r, tmin, closest_so_far, temp_rec))
			{
				hit_anything = true;
				closest_so_far = temp_rec.t;
				rec = temp_rec;
			}
		}
		return hit_anything;
	}

	float rand(float2 uv)
	{
		float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233) * 2.0)) * 43758.5453));
		return abs(noise.x + noise.y) * 0.5;
	}

	vec3 random_in_unit_sphere(float2 random)
	{
		vec3 p = vec3(10, 10, 10);

		while (sqrt(dot(p, p)) >= 1.0) {
			p = 2.0 * vec3(rand(random), rand(random + 1), rand(random - 1)) - vec3(1, 1, 1);

		}
		return p;
	}

	bool scatter(ray r_in, hit_record rec, out vec3 attenuation, out ray scattered)
	{
		if (rec.mat.isMetal) {
			vec3 reflected = reflect(normalize(r_in.direction), rec.normal);
			scattered.make(rec.p, reflected + rec.mat.fuzz*random_in_unit_sphere(float2(reflected.x, reflected.y)));
			attenuation = rec.mat.albedo;
			return (dot(scattered.direction, rec.normal) > 0);
		}
		if(!rec.mat.isMetal) {
			vec3 target = rec.p + rec.normal + random_in_unit_sphere(float2(rec.p.x, rec.p.y));
			scattered.make(rec.p, target - rec.p);
			attenuation = rec.mat.albedo;
			return true;
		}
		return false;
	}

	col3 color(ray r, float2 random)
	{
		float MAXFLOAT = 3.402823466e+38F;
		hit_record rec;
		vec3 accumCol = vec3(1, 1, 1);

		bool foundHit = hit(r, 0.001, MAXFLOAT, rec);
		int maxC = 50;	// number of bounces (?)

		while (foundHit && (maxC > 0))
		{
			maxC--;
			ray scattered;
			vec3 attenuation;

			if (scatter(r, rec, attenuation, scattered)) 
			{
				accumCol = attenuation * accumCol;
				r = scattered;
			}
			foundHit = hit(r, 0.001, MAXFLOAT, rec);
		}

		if (foundHit && maxC == 0)
		{
			return col3(0, 0, 0);
		}
		return accumCol * skycolor(r);
	}
	
	vec3 reflect(vec3 v, vec3 n) 
	{
		return v = 2 * dot(v, n) * n;
	}
	
	fixed4 frag(v2f i) : SV_Target
	{
		float x = i.uv.x;
		float y = i.uv.y;

		vec3 col = vec3(0, 0, 0);

		int nx = 200;
		int ny = 100;
		int ns = 100;
		int s = 0;

		camera cam;
		cam.make();

		while (s < ns)
		{
			float u = float(x + rand(float2(x + s, y))/ float(nx)) ;
			float v = float(y + rand(float2(y + s, x))/ float(ny)) ;
			ray r;
			r = cam.get_ray(u, v);
			vec3 p = r.point_at_parameter(2.0);
			col += color(r, rand(float2(s, s+1)));
			
			s++;
		}

		col /= float(ns);
		col = vec3(sqrt(col.x), sqrt(col.y), sqrt(col.z));
		return fixed4(col,1);
	}
		////////////////////////////////////////////////////////////////////////////////////


		ENDCG

		} }}