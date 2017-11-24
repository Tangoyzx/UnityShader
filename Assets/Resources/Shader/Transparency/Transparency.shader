// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Transparency/Transparency"
{
	Properties {
		_MainTex ("主贴图", 2D) = "white" {}
		_BumpMap ("法线贴图", 2D) = "bump" {}
		_Color ("主颜色", Color) = (1,1,1,1)
		_SpecColor ("高光颜色", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("高光亮度", Range (0.03, 1)) = 0.078125

		_Power ("次表面强度", Float) = 1.0
		_Distortion ("次表面法线偏移强度", Float) = 0.0
		_Scale ("次表面强度缩放", Float) = 0.5
		_SubColor ("次表面的颜色", Color) = (1.0, 1.0, 1.0, 1.0)
		_TexFwidth ("特殊参数", Vector) = (0, 0, 0, 0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }  
        LOD 200  
          
        Pass {  
            Tags { "LightMode"="ForwardBase"} 
              
            CGPROGRAM  
            #pragma multi_compile_fwdbase

            #pragma vertex vert  
            #pragma fragment frag  
               
            #include "UnityCG.cginc"  
            #include "Lighting.cginc"  
            #include "AutoLight.cginc"  

			sampler2D _MainTex, _BumpMap;
			float _Scale, _Power, _Distortion;
			fixed4 _Color, _SubColor, _TexFwidth;
			float4 _MainTex_ST;
			half _Shininess;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 tangentViewDir : TEXCOORD1;
				float3 tangentLightDir : TEXCOORD2;
				float4 pos : SV_POSITION;

				LIGHTING_COORDS(3, 4)
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				TANGENT_SPACE_ROTATION;

				o.tangentViewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
				o.tangentLightDir = mul(rotation, ObjSpaceLightDir(v.vertex));

				TRANSFER_VERTEX_TO_FRAGMENT(o); 

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 viewDir = normalize(i.tangentViewDir);
				float3 lightDir = normalize(i.tangentLightDir);
				float3 normal = UnpackNormal(tex2D(_BumpMap, i.uv));
				
				float4 col = tex2D(_MainTex, i.uv, _TexFwidth.x * 0.01, _TexFwidth.y * 0.01);

				//获取光照强度，其实算是最重要模仿透光系数的参数
				float atten = LIGHT_ATTENUATION(i);

				//计算透光的光照信息
				//计算透光的光线方向，加上法线的偏移
				half3 transLightDir = lightDir + normal * _Distortion;
				//由于是透光，所以光线方向要取反，然后算出与视线点乘，再做一些Power和Scale稍微Trick一下……
				float transDot = pow ( max (0, dot ( viewDir, -transLightDir ) ), _Power ) * _Scale;
				//综合光照强度、光纤视线点乘、材料厚薄系数、材料的颜色算出透光的颜色
				fixed3 transLight = (atten * 2) * ( transDot )  * _SubColor.rgb;
				//再综合上贴图的颜色、主颜色、光的颜色
				fixed3 transAlbedo = col * _Color * transLight * _LightColor0.rgb;

				//正常的光照计算
				half3 h = normalize (lightDir + viewDir);
				fixed diff = max (0, dot (normal, lightDir));
				float nh = max (0, dot (normal, h));
				float spec = pow (nh, _Shininess*128.0) * col.a;
				fixed3 diffAlbedo = (col * _Color * diff + _SpecColor.rgb * spec) * (atten * 2);

				return float4(diffAlbedo + transAlbedo + col * _TexFwidth.z, 1);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
