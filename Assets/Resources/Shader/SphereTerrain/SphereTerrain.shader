Shader "SphereTerrain/SphereTerrain"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Radius("Radius", Float) = 5.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 normal : TEXCOORD2;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float3 origin;
			float _Radius;

			 inline half3 Unity_SafeNormalize(half3 inVec)
			{
				half dp3 = max(0.001f, dot(inVec, inVec));	
				return inVec * rsqrt(dp3);
			}

			float3 GetSphereProjPos(float4 localPos) {
				float radius = _Radius;
				float3 worldPos = mul(unity_ObjectToWorld, localPos).xyz;
				float totalY = worldPos.y + _Radius;
				float3 planePos = float3(worldPos.x - origin.x, 0, worldPos.z - origin.z);
				float3 planePosNormalize = Unity_SafeNormalize(planePos);

				float cosY = planePosNormalize.z;
				float radianXZ = length(planePos) / radius;

				float3 center = origin;
				center.y -= radius;
				float dy = (cos(radianXZ));
				float dx = sin(radianXZ) * planePosNormalize.x;
				float dz = sin(radianXZ) * planePosNormalize.z;
				return float3(dx, dy, dz) * totalY + center;
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				float3 worldPos = GetSphereProjPos(v.vertex);
				o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.lightDir = WorldSpaceLightDir(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				float dd = dot(normalize(i.lightDir), normalize(i.normal)) * 0.5 + 0.5;
				return col * dd;
			}
			ENDCG
		}
	}
}
