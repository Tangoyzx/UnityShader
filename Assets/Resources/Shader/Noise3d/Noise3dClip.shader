Shader "Noise3d/Noise3dClip"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Noise("Noise", 3D) = "black" {}
		_ClipRange("ClipRange", Range(0, 1)) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Cull Off

		Pass
		{
			Tags {"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float3 noise_uv : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
				float3 normal : TEXCOORD4;
				float3 viewPos : TEXCOORD5;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler3D _Noise;
			float4 _MainTex_ST;
			float _ClipRange;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.viewPos = UnityObjectToViewPos(v.vertex);
				o.noise_uv = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.screenPos = ComputeScreenPos(o.vertex);
				o.lightDir = WorldSpaceLightDir(v.vertex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 noiseCol = tex3D(_Noise, i.noise_uv * 0.2);
				float2 screenUV = i.screenPos.xy / i.screenPos.w;
				screenUV.y = screenUV.y * _ScreenParams.y / _ScreenParams.x - (_ScreenParams.y / _ScreenParams.x - 1) * 0.5;
				
				float c = 1 - length(abs(screenUV-0.5)) * 0.8 + 0.0;
				float bb = smoothstep(24, 13, -i.viewPos.z);
				c *= bb;
				float nearKill = smoothstep(11, 9, -i.viewPos.z);
				// return nearKill;

				clip(noiseCol.r - max(c, nearKill));

				float diffuse = dot(normalize(i.lightDir), normalize(i.normal)) * 0.5 + 0.5;
				
				return tex2D(_MainTex, i.uv) * diffuse;
			}
			ENDCG
		}
	}
}
