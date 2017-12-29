// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable
// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// http://www.popekim.com/2012/10/siggraph-2012-screen-space-decals-in.html

Shader "CommandBufferShadow/CommandBufferShadowDrawer"
{
	Properties
	{
		_MainTex ("Diffuse", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"


			struct appdata {
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 screenPos : TEXCOORD0;
				float3 ray : TEXCOORD1;


				float3 worldPos : TEXCOORD2;
			};

			float4x4 _ShadowVP;
			sampler2D _CustomDepthTexture;
			float2 _ShadowCameraParams;
			sampler2D _ShadowTex;

			sampler2D _CameraDepthTexture;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (v.vertex);
				o.screenPos = ComputeScreenPos(o.pos);
				o.ray = UnityObjectToViewPos(v.vertex).xyz * float3(-1,-1,1);


				return o;
			}

			

			fixed4 frag(v2f i) : SV_Target
			{
				// return fixed4(1, 0, 0, 1);
				// return i.pos.z / i.pos.w;
				i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
				float2 uv = i.screenPos.xy / i.screenPos.w;
				// float depth = SAMPLE_DEPTH_TEXTURE(_CustomDepthTexture, uv);
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				depth = Linear01Depth (depth);
				float4 vpos = float4(i.ray * depth,1);
				float3 wpos = mul (unity_CameraToWorld, vpos).xyz;
				float3 opos = mul (unity_WorldToObject, float4(wpos,1)).xyz;

				clip (float3(0.5,0.5,0.5) - abs(opos.xyz));
				// return float4(opos.xy, 0, 1);

				float2 shadowUV = opos.xy + 0.5;
				float shadowDepth = opos.z + 0.5;
				float shadowTexDepth = 1 - tex2D(_ShadowTex, shadowUV);
				// return tex2D(_ShadowTex, shadowUV);
				
				float inShadow = step(shadowTexDepth, shadowDepth - 0.5);

				return float4(0, 0, 0, inShadow * 0.5);
				// return float4(shadowTexDepth, 0, 0, 0.5);
				// return fixed4(opos.xy * 0.5 + 0.5, 0, 1);
				// return fixed4(1, 0, 0, 1);


				// return fixed4(1, 0, 0, 0.5);
			}
			ENDCG
		}		

	}

	Fallback Off
}
