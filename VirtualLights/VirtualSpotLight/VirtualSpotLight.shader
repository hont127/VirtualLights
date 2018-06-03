Shader "Custom/VirtualSpotLight"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_VirtualLightPos("Virtual Light Position", vector) = (0, 0, 0, 0)
		_VirtualLightForward("Virtual Light Forward Direction", vector) = (0, 0, 0, 0)
		_VirtualLightColor("Virtual Light Color", Color) = (0, 0, 0, 0)
		_Shininess("Shininess", range(0.1, 100)) = 1
		_KC_KL_KQ("KC(x), KL(y), KQ(z)", vector) = (0.1, 0.1, 0.1, 0)
		_SpotLightCosInnerCone("CosInnerCone", float) = 0.1
		_SpotLightCosOuterCone("CosOuterCone", float) = 0.15
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
			float4 _VirtualLightPos;
			float4 _VirtualLightForward;
			float4 _VirtualLightColor;
			float _Shininess;
			float4 _KC_KL_KQ;

			float _SpotLightCosInnerCone;
			float _SpotLightCosOuterCone;
			
			float SpotLight(float3 p, float3 lightPosition, float3 lightDir, float innerCone, float outerCone)
			{
				float3 V = normalize(p - lightPosition);
				float cosDirection = dot(V, lightDir);

				return smoothstep(outerCone, innerCone, cosDirection);
			}

			inline float Attenuation(float3 p, float3 lightPosition, float kc, float kl, float kq)
			{
				float d = distance(p, lightPosition);
				return 1 / (kc + kl * d + kq * d  * d);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				float4 worldPosition = mul(unity_ObjectToWorld, v.vertex);
				float4 N = normalize(mul(unity_ObjectToWorld, v.normal));
				float3 L = _VirtualLightPos - worldPosition;

				float3 V = normalize(_WorldSpaceCameraPos.xyz - worldPosition.xyz).xyz;
				float3 H = normalize(L + V);

				float4 diffuse = max(dot(N, L), 0);
				float specular = pow(max(0, dot(H, N)), _Shininess);

				float spotLightVolume = SpotLight(worldPosition, _VirtualLightPos, _VirtualLightForward, _SpotLightCosInnerCone, _SpotLightCosOuterCone);

				o.lightVolume = diffuse + specular;
				o.lightVolume = o.lightVolume * Attenuation(worldPosition, _VirtualLightPos, _KC_KL_KQ.x, _KC_KL_KQ.y, _KC_KL_KQ.z);
				o.lightVolume *= spotLightVolume;

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
