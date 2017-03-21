// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "CookBook/Joy/OutLine"
{
	Properties
	{
		_Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_OutlineColor ("Outline Color", Color) = (1, 1, 1, 1)
		_Power ("Power", Range(0, 1)) = 0
	}
	CGINCLUDE
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct a2v 
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal: NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal: TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _OutlineColor;
			float4 _Color;
			float _Power;
			
			v2f vert (a2v  v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = mul(v.normal, unity_WorldToObject);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;

				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldNormal = normalize(i.worldNormal);
				
				fixed diff = max(0, dot(worldNormal, worldLightDir));
				fixed3 diffColor = _LightColor0.rgb * diff;
				fixed3 ambient =  UNITY_LIGHTMODEL_AMBIENT.rgb;
			
				fixed4 final = fixed4(col.rgb * (ambient + diffColor), 1);

				return final;
			}

			fixed4 fragOutline(v2f i) : SV_Target
			{
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed rim =_Power + (1 - _Power) * (1 - saturate(dot(worldNormal, worldViewDir)));
				fixed4 col = _OutlineColor * rim;
				
				return col;
			}
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}

		Pass
		{	
			ZTest Greater

			CGPROGRAM
			#pragma vertex vert
			//轮廓渲染
			#pragma fragment fragOutline
			ENDCG
		}
	}
}
