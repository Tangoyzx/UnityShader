Shader "Translucency/TranslucencyShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "Bump" {}
		_ThicknessMap("InverseAOMap", 2D) = "white" {}

		_LTDistortion("Distortion", Range(0, 1)) = 0.2
		_LTPower("Power", Range(1, 20)) = 1
		_LTScale("Scale", Range(0, 2)) = 1

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			
			#include "../TangoCommon.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldLightDir : TEXCOORD1;
				float3 worldViewDir : TEXCOORD2;
				TANGENT_COORDS(3, 4, 5);
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _BumpMap;
			sampler2D _ThicknessMap;

			float _LTDistortion;
			float _LTPower;
			float _LTScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				WORLD_SPACE_TANGENT_VERTEX(v, o);

				o.worldLightDir = WorldSpaceLightDir(v.vertex);
				o.worldViewDir = WorldSpaceViewDir(v.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 normal = UnpackNormal(tex2D(_BumpMap, i.uv));
				normal = float3(0, 0, 1);
				WORLD_SPACE_TANGENT_FRAGMENT(i, normal);

				float thickness = tex2D(_ThicknessMap, i.uv).r;
				thickness = 1 - thickness;

				float3 worldLightDir = normalize(i.worldLightDir);

				float dotNL = dot(worldLightDir, worldNormal);
				dotNL = dotNL * 0.5 + 0.5;

				float3 L = worldLightDir;
				float3 N = worldNormal;
				float3 V = normalize(i.worldViewDir);

				float3 H = normalize(L + N * _LTDistortion);

				float3 I = pow(saturate(dot(V, -H)), _LTPower) * _LTScale;

				float3 col = (I * thickness + saturate(dotNL)) * _LightColor0.rgb;
				// float3 col = (saturate(dotNL)) * _LightColor0.rgb;
				// float3 col = (I * thickness) * _LightColor0.rgb;
				// float3 col = (dotNL) * _LightColor0.rgb;

				
				return float4(col, 1);
			}
			ENDCG
		}
	}
}
