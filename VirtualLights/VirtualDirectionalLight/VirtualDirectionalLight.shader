Shader "Custom/VirtualDirectionalLight"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_VirtualLightForward("Virtual Light Forward Direction", vector) = (0, 0, 0, 0)
		_VirtualLightColor("Virtual Light Color", Color) = (0, 0, 0, 0)
		_Shininess("Shininess", range(0.1, 100)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

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
				float3 normal :  NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 lightVolume : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _VirtualLightForward;
			float4 _VirtualLightColor;
			float _Shininess;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				float4 worldPosition = mul(unity_ObjectToWorld, v.vertex);
				float4 N = normalize(mul(unity_ObjectToWorld, v.normal));
				float3 L = -_VirtualLightForward;

				float3 V = normalize(_WorldSpaceCameraPos.xyz - worldPosition.xyz).xyz;
				float3 H = normalize(L + V);

				float4 diffuse = max(dot(N, L), 0);
				float specular = pow(max(0, dot(H, N)), _Shininess);

				o.lightVolume = diffuse + specular;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				return col * _VirtualLightColor * i.lightVolume;
			}
			ENDCG
		}
	}
}
