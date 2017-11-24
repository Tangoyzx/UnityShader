Shader "PlanarShadow/PlanarShadow"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Light ("Light", Vector) = (0, 1, 0, 0)
		_HY ("HY", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float4 _Light;
			float _HY;
			
			v2f vert (appdata v)
			{
				v2f o;
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 lightDir = normalize(_Light.xyz - worldPos * _Light.w);
				float offsetY = worldPos.y - _HY;
				worldPos.xz -= lightDir.xz * offsetY / lightDir.y;
				worldPos.y = _HY;
				o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(0, 0, 0, 1);
			}
			ENDCG
		}
	}
}
