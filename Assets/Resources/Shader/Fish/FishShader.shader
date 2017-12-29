Shader "Unlit/FishShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Weight("Weight", Vector) = (0, 0, 0, 0)
		_Period("Period", Vector) = (1, 1, 1, 1)
		_Offset("Offset", Vector) = (0, 0, 0, 0)
		_Extra("Extra", Vector) = (0, 0, 0, 0)
		_Block("Block", Vector) = (0, 1, 0, 0)
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

			#pragma multi_compile_instancing
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;

				UNITY_VERTEX_INPUT_INSTANCE_ID 
			};


			sampler2D _MainTex;
			float4 _MainTex_ST;

			float4 _Weight, _Period, _Offset, _Extra, _Block;
			
			v2f vert (appdata v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o); 

				float4 offset = 0;

#if defined(UNITY_INSTANCING_ENABLED)
				float a = UNITY_GET_INSTANCE_ID(v);
#else
				float a = 1;
#endif
				
				float zWeight = saturate((_Block.x * 0.1 - v.vertex.z) * _Block.y);

				float zWeight1 = 0.25;
				float zWeight2 = 0.25 * zWeight;

				offset.x += sin(_Time.y * (_Period.x) + a + _Offset.x) * _Weight.x * 0.1 * zWeight1;

				float angleB = sin(_Time.y * (_Period.y) + a + _Offset.y) * _Weight.y * 0.1;
				float cosB = cos(angleB);
				float sinB = sin(angleB);
				offset.x += (cosB * v.vertex.x + sinB * v.vertex.z - v.vertex.x) * zWeight2;
				offset.z += (-sinB * v.vertex.x + cosB * v.vertex.z - v.vertex.z) * zWeight2;

				float angleC = sin(_Time.y * (_Period.z) + a + _Offset.z + v.vertex.z * _Extra.z) * _Weight.z * 0.1;
				float cosC = cos(angleC);
				float sinC = sin(angleC);
				offset.x += (cosC * v.vertex.x + sinC * v.vertex.y - v.vertex.x) * zWeight2;
				offset.y += (-sinC * v.vertex.x + cosC * v.vertex.y - v.vertex.y) * zWeight2;

				offset.x += sin(_Time.y * (_Period.w) + a + _Offset.w + v.vertex.z * _Extra.w) * _Weight.w * 0.1 * zWeight2;

				v.vertex += offset;


				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
