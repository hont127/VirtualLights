Shader "Custom/VirtualCubeLight"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		_CubeLight_Origin("CubeLight Origin", vector) = (0,0,0,0)
		_CubeLight_PX("CubeLight P X", vector) = (0,0,0,0)
		_CubeLight_PY("CubeLight P Y", vector) = (0,0,0,0)
		_CubeLight_PZ("CubeLight P Z", vector) = (0,0,0,0)

		_VirtualLightColor("Virtual Light Color", Color) = (0, 0, 0, 0)
		_Shininess("Shininess", range(0.1, 100)) = 1
		_KC_KL_KQ("KC(x), KL(y), KQ(z)", vector) = (0.1, 0.1, 0.1, 0)
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
				float4 wPos : TEXCOORD1;
				float4 wNormal : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float4 _CubeLight_Origin;
			float4 _CubeLight_PX;
			float4 _CubeLight_PY;
			float4 _CubeLight_PZ;

			float4 _VirtualLightColor;

			float _Shininess;
			float4 _KC_KL_KQ;

#define ISINCUBE_ERROR = -0.00001

			inline float Attenuation(float3 p, float3 lightPosition, float kc, float kl, float kq)
			{
				float d = distance(p, lightPosition);
				return 1 / (kc + kl * d + kq * d  * d);
			}

			bool IsInCube(float3 p)
			{
				bool r = true;

				if (dot(_CubeLight_PX.xyz - _CubeLight_Origin.xyz, p - _CubeLight_Origin.xyz) < -0.0001)
					r = false;

				else if (dot(_CubeLight_Origin.xyz - _CubeLight_PX.xyz, p - _CubeLight_PX.xyz) < -0.0001)
					r = false;

				else if (dot(_CubeLight_PZ.xyz - _CubeLight_Origin.xyz, p - _CubeLight_Origin.xyz) < -0.0001)
					r = false;

				else if (dot(_CubeLight_Origin.xyz - _CubeLight_PZ.xyz, p - _CubeLight_PZ.xyz) < -0.0001)
					r = false;

				else if (dot(_CubeLight_PY.xyz - _CubeLight_Origin.xyz, p - _CubeLight_Origin.xyz) < -0.0001)
					r = false;

				else if (dot(_CubeLight_Origin.xyz - _CubeLight_PY.xyz, p - _CubeLight_PY.xyz) < -0.0001)
					r = false;

				return r;
			}

			float3 GetIntersectPoint(float3 planeNormal, float3 planePosition, float3 p0, float3 p1)
			{
				int sign1 = sign(dot(planeNormal, planePosition - p0));
				int sign2 = sign(dot(planeNormal, planePosition - p1));
				if (sign1 == sign2) return 0;//同侧异侧.

				float a = planeNormal.x;
				float b = planeNormal.y;
				float c = planeNormal.z;
				float d = -a * planePosition.x - b * planePosition.y - c * planePosition.z;

				float i0 = a * p0.x + b * p0.y + c * p0.z;
				float i1 = a * p1.x + b * p1.y + c * p1.z;
				float final_t = -(i1 + d) / ((i0 - i1)+0.000001);

				return float3(p0.x * final_t + p1.x * (1 - final_t), p0.y * final_t + p1.y * (1 - final_t), p0.z * final_t + p1.z * (1 - final_t));
			}

			float3 Project(float3 vec, float3 onNormal)
			{
				float3 result = 0;
				float num = dot(onNormal, onNormal);

				if (num < 0.000001)
				{
					result = 0;
				}
				else
				{
					result = onNormal * dot(vec, onNormal) / num;
				}

				return result;
			}

			float3 ProjectOnPlane(float3 vec, float3 planeNormal)
			{
				return vec - Project(vec, planeNormal);
			}

			float3 GetProjectionPoint(float3 planeNormal, float3 planeTangent, float3 planePosition, float tangentExtents, float binormalExtents, float3 p)
			{
				float3 projectionPoint = ProjectOnPlane(p, planeNormal);
				float3 binormal = cross(planeNormal, planeTangent);

				float pTangentSign = sign(dot(projectionPoint - planePosition, planeTangent));
				float3 pTangent = planeTangent * pTangentSign * min(distance(Project(projectionPoint, planeTangent), Project(planePosition, planeTangent)), tangentExtents);

				float pBinormalSign = sign(dot(projectionPoint - planePosition, binormal));
				float3 pBinormal = binormal * pBinormalSign * min(distance(Project(projectionPoint, binormal), Project(planePosition, binormal)), binormalExtents);

				return planePosition + pTangent + pBinormal;
			}

			float3 CubePointMapping(float3 p)
			{
				float4 relativeX = _CubeLight_PX - _CubeLight_Origin;
				float4 relativeY = _CubeLight_PY - _CubeLight_Origin;
				float4 relativeZ = _CubeLight_PZ - _CubeLight_Origin;

				float distanceX = distance(_CubeLight_PX, _CubeLight_Origin);
				float distanceY = distance(_CubeLight_PY, _CubeLight_Origin);
				float distanceZ = distance(_CubeLight_PZ, _CubeLight_Origin);

				float4 pxPoint = _CubeLight_Origin + relativeX + relativeY * 0.5 + relativeZ * 0.5;
				float4 pyPoint = _CubeLight_Origin + relativeY + relativeX * 0.5 + relativeZ * 0.5;
				float4 pzPoint = _CubeLight_Origin + relativeZ + relativeY * 0.5 + relativeX * 0.5;

				float4 nxPoint = pxPoint - relativeX;
				float4 nyPoint = pyPoint - relativeY;
				float4 nzPoint = pzPoint - relativeZ;

				float4 lightCenter = _CubeLight_Origin + relativeX * 0.5 + relativeY * 0.5 + relativeZ * 0.5;

				float3 xNormal = normalize(relativeX);
				float3 yNormal = normalize(relativeY);
				float3 zNormal = normalize(relativeZ);

				float3 projectionPointPX = GetProjectionPoint(xNormal, yNormal, pxPoint, distanceY * 0.5, distanceZ * 0.5, p);//PX
				float3 projectionPointPY = GetProjectionPoint(yNormal, xNormal, pyPoint, distanceX * 0.5, distanceZ * 0.5, p);//PY
				float3 projectionPointPZ = GetProjectionPoint(zNormal, yNormal, pzPoint, distanceY * 0.5, distanceX * 0.5, p);//PZ

				float3 projectionPointNX = GetProjectionPoint(-xNormal, yNormal, nxPoint, distanceY * 0.5, distanceZ * 0.5, p);//NX
				float3 projectionPointNY = GetProjectionPoint(-yNormal, xNormal, nyPoint, distanceX * 0.5, distanceZ * 0.5, p);//NY
				float3 projectionPointNZ = GetProjectionPoint(-zNormal, yNormal, nzPoint, distanceY * 0.5, distanceX * 0.5, p);//NZ

				float compareDistance = distance(projectionPointPX, p);
				float3 result = projectionPointPX;

				if (distance(projectionPointPY, p) < compareDistance)
				{
					 compareDistance = distance(projectionPointPY, p);
					 result = projectionPointPY;
				}

				if (distance(projectionPointPZ, p) < compareDistance)
				{
					compareDistance = distance(projectionPointPZ, p);
					result = projectionPointPZ;
				}

				if (distance(projectionPointNX, p) < compareDistance)
				{
					compareDistance = distance(projectionPointNX, p);
					result = projectionPointNX;
				}

				if (distance(projectionPointNY, p) < compareDistance)
				{
					compareDistance = distance(projectionPointNY, p);
					result = projectionPointNY;
				}

				if (distance(projectionPointNZ, p) < compareDistance)
				{
					compareDistance = distance(projectionPointNZ, p);
					result = projectionPointNZ;
				}

				return result;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.wPos = mul(unity_ObjectToWorld, v.vertex);
				o.wNormal = normalize(mul(unity_ObjectToWorld, v.normal));

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4 worldPosition = i.wPos;

				float3 virtualLightPos = CubePointMapping(worldPosition.xyz);

				float4 N = i.wNormal;
				float3 L = virtualLightPos - worldPosition;

				float3 V = normalize(_WorldSpaceCameraPos.xyz - worldPosition.xyz).xyz;
				float3 H = normalize(L + V);

				float4 diffuse = max(dot(N, L), 0);
				float specular = pow(max(0, dot(H, N)), _Shininess);

				float4 lightVolume = diffuse + specular;
				lightVolume = lightVolume * Attenuation(worldPosition, virtualLightPos, _KC_KL_KQ.x, _KC_KL_KQ.y, _KC_KL_KQ.z);

				fixed4 col = tex2D(_MainTex, i.uv);
				return col * _VirtualLightColor * lightVolume;
			}
			ENDCG
		}
	}
}
