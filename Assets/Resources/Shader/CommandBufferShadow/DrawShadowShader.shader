Shader "CommandBufferShadow/DrawShadowShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		// Blend SrcAlpha OneMinusSrcAlpha
		Blend One Zero

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 pPos : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
			};

			float4x4 _shadowVP;
			sampler2D _MainTex;
			sampler2D _CameraDepthNormalsTexture;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.pPos = mul(_shadowVP, worldPos);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = i.pPos.xy / i.pPos.w * 0.5 + 0.5;
				fixed4 color = tex2D(_MainTex, uv).rrrr;

				float2 screenUV = i.screenPos.xy / i.screenPos.w;
				// return fixed4(screenUV, 0, 1);
				float3 viewNorm;
                float depth;
                DecodeDepthNormal (tex2D (_CameraDepthNormalsTexture, screenUV), depth, viewNorm);
				// depth = LinearEyeDepth(depth);
				// return Linear01Depth(depth);
				float3 viewPos = float3((screenUV * 2.0 - 1.0) / float2(unity_CameraProjection._11, unity_CameraProjection._22) * depth, depth); 
				return fixed4(viewPos.xy, 0, 1);
				return fixed4(color.r, 0, 0, 1);
			}
			ENDCG
		}
	}
}
