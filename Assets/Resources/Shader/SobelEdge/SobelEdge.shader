Shader "SobelEdge/SobelEdge"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		_LineColor ("LineColor", Color) = (0, 1, 1, 1)
	}
	SubShader
	{
		Tags {"Queue"="background" "RenderType"="opaque" }
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
				float2 uv : TEXCOORD0;
				float4 screenUV : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.screenUV = ComputeScreenPos(o.vertex);
				return o;
			}
			
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;

			fixed4 _LineColor;

			fixed4 frag (v2f i) : SV_Target
			{
				float3 lum = float3(0.2125,0.7154,0.0721);

				fixed3 midColor = tex2D(_MainTex, i.uv).rgb;

				float c00 = dot(tex2D(_MainTex, i.uv + float2(-1, -1) * _MainTex_TexelSize.xy).rgb, lum);
				float c01 = dot(tex2D(_MainTex, i.uv + float2(-1, 0) * _MainTex_TexelSize.xy).rgb, lum);
				float c02 = dot(tex2D(_MainTex, i.uv + float2(-1, 1) * _MainTex_TexelSize.xy).rgb, lum);
				float c10 = dot(tex2D(_MainTex, i.uv + float2(0, -1) * _MainTex_TexelSize.xy).rgb, lum);
				float c11 = dot(tex2D(_MainTex, i.uv + float2(0, 0) * _MainTex_TexelSize.xy).rgb, lum);
				float c12 = dot(tex2D(_MainTex, i.uv + float2(0, 1) * _MainTex_TexelSize.xy).rgb, lum);
				float c20 = dot(tex2D(_MainTex, i.uv + float2(1, -1) * _MainTex_TexelSize.xy).rgb, lum);
				float c21 = dot(tex2D(_MainTex, i.uv + float2(1, 0) * _MainTex_TexelSize.xy).rgb, lum);
				float c22 = dot(tex2D(_MainTex, i.uv + float2(1, 1) * _MainTex_TexelSize.xy).rgb, lum);

				float gx = -c00 - c01 - c01 - c02 + c20 + c21 + c21 + c22;
				float gy = c00 + c10 + c10 + c20 - c02 - c12 - c12 - c22;

				float edge = length(float2(gx, gy));

				edge = step(0.1, edge) * edge;
				float2 screenUV = i.screenUV.xy / i.screenUV.w;
				float fy = fmod(_Time.y, 2);
				float inSideShow = step(screenUV.y, fy);
				float a = max((screenUV.y - fy) * 2 + 1, 0) * inSideShow;
				midColor = midColor + (edge) * _LineColor.rgb * a; 
				
				return fixed4(midColor, 1);
			}
			ENDCG
		}
	}
	
}
