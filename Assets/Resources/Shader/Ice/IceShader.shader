Shader "Ice/IceShader"
{
	Properties
	{
		_Color ("Color(RGB)", Color) = (1,1,1,1)
		_MainTex ("Texture(RGB)", 2D) = "white" {}
		_NoiseTex ("Noise Texture(R)", 2D) = "white" {}
		_FrozenNorm("Frozen Normal Map(RGB)", 2D) = "bump" {}
		_FrozenNorPow("Frozen Normal Power" , Range(0,2)) = 1
		_FrozenSqueeze("Frozen Squeeze" , Range(0,1)) = 0.15
		_FrozenColor("Frozen Color(RGBA)", Color) = (0,0.5,1,0.2)
		_FrozenSpecular ("Frozen Specular",Range(0, 8) ) = 1
        _FrozenGloss ("Frozen Gloss", Range(0, 1)) = 0.6
		_Fresnel("Fresnel", Range(0.2, 10)) = 3
		_Blend("Blend" , Range(0,1)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags {"Queue"="Geometry " "LightMode"="ForwardBase" "RenderType"="Opaque"  }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"  

			struct a2v
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
			};
			struct v2f
			{
				half4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			};
			sampler2D _MainTex;
			half4 _MainTex_ST;
			fixed4 _Color;
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX (v.uv, _MainTex); 
				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				return col;
			}
			ENDCG
		}
		Pass
		{
            Tags { "Queue"="Transparent" "RenderType"="Transparent" "LightMode"="ForwardBase"}

			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fwdbase

			#pragma glsl
			#pragma target 3.0
			
            #include "UnityCG.cginc"  
			#include "AutoLight.cginc"
			#include "Lighting.cginc"



			struct a2v
			{
				half4 vertex : POSITION;
				half3 normal :NORMAL;
				half4 tangent : TANGENT; 
				half2 uv : TEXCOORD0;
			};

			struct v2f
			{
				half4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
                half4 worldPos : TEXCOORD1;  
                half3 normalDir : TEXCOORD2;  
                half3 tangentDir : TEXCOORD3; 
				half3 bitangentDir: TEXCOORD4;  
				half3 lightDir : TEXCOORD5;
				half3 viewDir : TEXCOORD6;
			};

			sampler2D _MainTex , _FrozenNorm , _NoiseTex;
			half4 _MainTex_ST , _FrozenNorm_ST;
			fixed4 _FrozenColor , _Color , _LightColor;

			half _FrozenSpecular;  
            half _FrozenGloss; 
			half _FrozenNorPow;
			half _FrozenSqueeze;
			half _Fresnel;
			half4 _LightDir;

			half _Blend;

			v2f vert (a2v v)
			{
				v2f o;

				o.uv.xy = TRANSFORM_TEX (v.uv, _MainTex);  
				o.uv.zw = TRANSFORM_TEX (v.uv, _FrozenNorm); 

				fixed noise = tex2Dlod (_NoiseTex , float4(o.uv.zw ,0,0)).r;
				v.vertex.xyz += v.normal * saturate(noise-(1-_Blend)) * _FrozenSqueeze ;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize(mul(unity_ObjectToWorld , float4(v.tangent.xyz, 0)).xyz);
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.viewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.lightDir = UnityWorldSpaceLightDir(o.worldPos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, normalize(i.normalDir));
				half3 worldViewDir = normalize(i.viewDir);
				half3 worldLightDir = normalize(i.lightDir);
				half3 halfDir =normalize(worldLightDir + worldViewDir); 

				half noise = tex2D(_NoiseTex , i.uv.zw);
				half3 norm = normalize(UnpackNormal(tex2D(_FrozenNorm, i.uv.zw)) * float3(_FrozenNorPow,_FrozenNorPow,1)); 
				half3 worldNormal = normalize(mul( norm, tangentTransform ));

				half blend = (1 - _Blend)*1.01;

				half frozenSize = step(0, noise - blend);

				half gloss = exp2(_FrozenGloss * 10 + 1);

				half3 spec = _LightColor0 * pow(saturate(dot(halfDir,worldNormal)),gloss) * _FrozenSpecular;

				fixed3 fresnel  = _FrozenColor * pow(1-saturate(dot(worldViewDir , worldNormal)) , _Fresnel) ;
				fixed3 blendEdge = _FrozenColor * pow(1-(noise - blend) , _Fresnel);
				fixed3 frozenCol = fresnel + spec + blendEdge;

				fixed3 col = (_FrozenColor.rgb + frozenCol * frozenCol * 2) * frozenSize;
				return fixed4(col , 1);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
