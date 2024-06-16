// Made with Amplify Shader Editor v1.9.4.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ShellGrass"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		_colortop("color-top", Color) = (1,1,1,0)
		_colorbottom("color-bottom", Color) = (0,0,0,0)
		_colorthreshold("color-threshold", Range( 0 , 3)) = 1
		_albedo("albedo", 2D) = "white" {}
		_albedoopacity("albedo-opacity", Range( 0 , 1)) = 0.5
		_heightmap("height-map", 2D) = "white" {}
		_windmap("wind-map", 2D) = "white" {}
		_windstrength("wind-strength", Range( 0 , 0.5)) = 0.019
		_patchmap("patch-map", 2D) = "black" {}
		_patchcolortop("patch-color-top", Color) = (1,1,1,0)
		_patchcolorbottom("patch-color-bottom", Color) = (0,0,0,0)
		_patchstrength("patch-strength", Range( 0 , 1)) = 0.5


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="Unlit" }

		Cull Off
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			

			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#define _ALPHATEST_SHADOW_ON 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140011


			

			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
			#if ASE_SRP_VERSION >=140010
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _FORWARD_PLUS
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
			#include "Assets/shell-grass/shaders/HLSL/triangle-data.hlsl"
			StructuredBuffer<DrawTriangle> _DrawTriangles;
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _FORWARD_PLUS


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				float4 texcoord1 : TEXCOORD1;
				half4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				nointerpolation float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				float4 lightmapUVOrVertexSH : TEXCOORD8;
				float4 ase_texcoord9 : TEXCOORD9;
				float4 ase_texcoord10 : TEXCOORD10;
				float4 ase_texcoord11 : TEXCOORD11;
				float4 ase_texcoord12 : TEXCOORD12;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _patchcolortop;
			half4 _patchcolorbottom;
			half4 _windmap_ST;
			half4 _patchmap_ST;
			half4 _albedo_ST;
			half4 _colorbottom;
			half4 _colortop;
			half4x4 _LocalToWorld;
			half4 _heightmap_ST;
			half _windstrength;
			half _albedoopacity;
			half _patchstrength;
			half _colorthreshold;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _patchmap;
			sampler2D _windmap;
			sampler2D _GlobalInteractiveRT;
			half _GlobalEffectCamOrthoSize;
			sampler2D _albedo;
			sampler2D _heightmap;


			half3 trianglesFromBuffer10( int vertexID, out half3 normal, out half2 uv, out half height )
			{
				DrawTriangle tri = _DrawTriangles[vertexID / 3.0];
				DrawVertex v = tri.vertices[vertexID % 3];
				normal = v.normal;
				uv = v.uv;
				height = v.height;
				return v.position;
			}
			
			float3 ASEIndirectDiffuse( float2 uvStaticLightmap, float3 normalWS )
			{
			#ifdef LIGHTMAP_ON
				return SampleLightmap( uvStaticLightmap, normalWS );
			#else
				return SampleSH(normalWS);
			#endif
			}
			
			half3 AdditionalLightsFlat14x( float3 WorldPosition, half2 ScreenUV )
			{
				float3 Color = 0;
				#if defined(_ADDITIONAL_LIGHTS)
					#define SUM_LIGHTFLAT(Light)\
						Color += Light.color * ( Light.distanceAttenuation * Light.shadowAttenuation );
					InputData inputData = (InputData)0;
					inputData.normalizedScreenSpaceUV = ScreenUV;
					inputData.positionWS = WorldPosition;
					uint meshRenderingLayers = GetMeshRenderingLayer();	
					uint pixelLightCount = GetAdditionalLightsCount();	
					#if USE_FORWARD_PLUS
					for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
					{
						FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
						Light light = GetAdditionalLight(lightIndex, WorldPosition);
						#ifdef _LIGHT_LAYERS
						if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						#endif
						{
							SUM_LIGHTFLAT( light );
						}
					}
					#endif
					LIGHT_LOOP_BEGIN( pixelLightCount )
						Light light = GetAdditionalLight(lightIndex, WorldPosition);
						#ifdef _LIGHT_LAYERS
						if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						#endif
						{
							SUM_LIGHTFLAT( light );
						}
					LIGHT_LOOP_END
				#endif
				return Color;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				int vertexID10 = v.ase_vertexID;
				half3 normal10 = float3( 0,0,0 );
				half2 uv10 = float2( 0,0 );
				half height10 = 0.0;
				half3 localtrianglesFromBuffer10 = trianglesFromBuffer10( vertexID10 , normal10 , uv10 , height10 );
				half3 vertexToFrag26 = localtrianglesFromBuffer10;
				half3 vertexPos13 = vertexToFrag26;
				
				half3 normalizeResult206 = normalize( normal10 );
				half3 vertexToFrag27 = normalizeResult206;
				half3 vertexNormal14 = vertexToFrag27;
				
				half2 vertexToFrag25 = uv10;
				half2 vertexUV15 = vertexToFrag25;
				half2 vertexToFrag569 = ( ( vertexUV15 * _windmap_ST.xy ) + ( _windmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord3.xy = vertexToFrag569;
				half vertexToFrag24 = height10;
				o.ase_texcoord4.x = vertexToFrag24;
				half2 vertexToFrag465 = ( ( (vertexPos13).xz / ( _GlobalEffectCamOrthoSize * 2.0 ) ) + 0.5 );
				o.ase_texcoord3.zw = vertexToFrag465;
				half2 vertexToFrag884 = ( ( vertexUV15 * _patchmap_ST.xy ) + ( _patchmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord5.xy = vertexToFrag884;
				half2 vertexToFrag572 = ( ( vertexUV15 * _albedo_ST.xy ) + ( _albedo_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord5.zw = vertexToFrag572;
				half4x4 objectToWorldMatrix495 = _LocalToWorld;
				half temp_output_308_0 = length( objectToWorldMatrix495[0] );
				half3 appendResult309 = (half3(temp_output_308_0 , temp_output_308_0 , temp_output_308_0));
				half3 vertexToFrag573 = appendResult309;
				half3 objectScale315 = vertexToFrag573;
				half2 appendResult324 = (half2(( objectScale315 * half3( vertexUV15 ,  0.0 ) ).xy));
				half2 uvScaled894 = appendResult324;
				half2 vertexToFrag571 = ( ( uvScaled894 * _heightmap_ST.xy ) + ( _heightmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord6.xy = vertexToFrag571;
				half ase_lightIntensity = max( max( _MainLightColor.r, _MainLightColor.g ), _MainLightColor.b );
				half4 ase_lightColor = float4( _MainLightColor.rgb / ase_lightIntensity, ase_lightIntensity );
				half vertexToFrag586 = ase_lightColor.a;
				o.ase_texcoord6.z = vertexToFrag586;
				o.ase_texcoord7.xyz = vertexToFrag27;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.normalOS);
				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( ase_worldNormal, o.lightmapUVOrVertexSH.xyz );
				half3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord9.xyz = ase_worldTangent;
				o.ase_texcoord10.xyz = ase_worldNormal;
				half ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord11.xyz = ase_worldBitangent;
				float4 ase_clipPos = TransformObjectToHClip((v.positionOS).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord12 = screenPos;
				half3 customSurfaceDepth2_g14 = vertexPos13;
				half customEye2_g14 = -TransformWorldToView(TransformObjectToWorld(customSurfaceDepth2_g14)).z;
				o.ase_texcoord6.w = customEye2_g14;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.yzw = 0;
				o.ase_texcoord7.w = 0;
				o.ase_texcoord9.w = 0;
				o.ase_texcoord10.w = 0;
				o.ase_texcoord11.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vertexPos13;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = vertexNormal14;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.positionCS = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				float4 texcoord1 : TEXCOORD1;
				half4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				o.texcoord1 = v.texcoord1;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
				#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				half2 vertexToFrag569 = IN.ase_texcoord3.xy;
				half2 uvWind120 = vertexToFrag569;
				half4 tex2DNode58 = tex2D( _windmap, uvWind120 );
				half2 appendResult62 = (half2(tex2DNode58.r , tex2DNode58.g));
				half2 wind61 = appendResult62;
				half vertexToFrag24 = IN.ase_texcoord4.x;
				half alphaClip52 = vertexToFrag24;
				half2 vertexToFrag465 = IN.ase_texcoord3.zw;
				half2 uvInteractive542 = vertexToFrag465;
				half4 tex2DNode448 = tex2D( _GlobalInteractiveRT, uvInteractive542 );
				half4 interactiveRT534 = tex2DNode448;
				half smoothstepResult538 = smoothstep( 0.5 , 0.9 , interactiveRT534.r);
				half myVarName889 = smoothstepResult538;
				half2 windDistortion896 = ( wind61 * _windstrength * alphaClip52 * ( 1.0 - myVarName889 ) );
				half2 vertexToFrag884 = IN.ase_texcoord5.xy;
				half2 uvPatch517 = ( windDistortion896 + vertexToFrag884 );
				half patch521 = tex2D( _patchmap, uvPatch517 ).r;
				half4 lerpResult594 = lerp( _patchcolortop , _patchcolorbottom , patch521);
				half4 temp_cast_0 = (1.0).xxxx;
				half2 vertexToFrag572 = IN.ase_texcoord5.zw;
				half2 uvAlbedo109 = ( vertexToFrag572 + windDistortion896 );
				half4 lerpResult506 = lerp( temp_cast_0 , tex2D( _albedo, uvAlbedo109 ) , _albedoopacity);
				half4 albedo59 = lerpResult506;
				half3 appendResult127 = (half3(albedo59.rgb));
				half2 vertexToFrag571 = IN.ase_texcoord6.xy;
				half2 uvHeight115 = ( vertexToFrag571 + windDistortion896 );
				half height60 = tex2D( _heightmap, uvHeight115 ).r;
				half lerpResult531 = lerp( height60 , saturate( ( height60 * ( 1.0 - patch521 ) ) ) , _patchstrength);
				half smoothstepResult589 = smoothstep( 0.7 , 1.0 , tex2DNode448.r);
				half alpha77 = saturate( ( ( lerpResult531 * ( 1.0 - min( smoothstepResult589 , 0.6 ) ) ) - tex2DNode448.g ) );
				half occlussion333 = ( alphaClip52 * alpha77 );
				half4 lerpResult592 = lerp( _colorbottom , _colortop , saturate( ( occlussion333 / _colorthreshold ) ));
				half3 appendResult554 = (half3(lerpResult592.rgb));
				half3 grassColor335 = ( appendResult127 * appendResult554 );
				half vertexToFrag586 = IN.ase_texcoord6.z;
				half lightDirIntensity357 = vertexToFrag586;
				float ase_lightAtten = 0;
				Light ase_mainLight = GetMainLight( ShadowCoords );
				ase_lightAtten = ase_mainLight.distanceAttenuation * ase_mainLight.shadowAttenuation;
				half lightAtten220 = ( lightDirIntensity357 * ase_lightAtten );
				half3 vertexToFrag27 = IN.ase_texcoord7.xyz;
				half3 vertexNormal14 = vertexToFrag27;
				half dotResult201 = dot( vertexNormal14 , _MainLightPosition.xyz );
				half dotNL209 = ( lightAtten220 * (( dotResult201 * occlussion333 )*0.5 + 0.5) );
				half ase_lightIntensity = max( max( _MainLightColor.r, _MainLightColor.g ), _MainLightColor.b );
				half4 ase_lightColor = float4( _MainLightColor.rgb / ase_lightIntensity, ase_lightIntensity );
				half3 lightDirCol218 = ( ase_lightColor.rgb * lightAtten220 );
				half3 ase_worldTangent = IN.ase_texcoord9.xyz;
				half3 ase_worldNormal = IN.ase_texcoord10.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord11.xyz;
				half3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				half3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				half3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal263 = vertexNormal14;
				half3 bakedGI263 = ASEIndirectDiffuse( IN.lightmapUVOrVertexSH.xy, float3(dot(tanToWorld0,tanNormal263), dot(tanToWorld1,tanNormal263), dot(tanToWorld2,tanNormal263)));
				MixRealtimeAndBakedGI(ase_mainLight, float3(dot(tanToWorld0,tanNormal263), dot(tanToWorld1,tanNormal263), dot(tanToWorld2,tanNormal263)), bakedGI263, half4(0,0,0,0));
				half3 lightAmbient386 = ( bakedGI263 * occlussion333 );
				half3 lightCol222 = ( ( dotNL209 * lightDirCol218 ) + lightAmbient386 );
				half3 worldPosValue184_g13 = WorldPosition;
				half3 WorldPosition123_g13 = worldPosValue184_g13;
				float4 screenPos = IN.ase_texcoord12;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				half2 ScreenUV183_g13 = (ase_screenPosNorm).xy;
				half2 ScreenUV123_g13 = ScreenUV183_g13;
				half3 localAdditionalLightsFlat14x123_g13 = AdditionalLightsFlat14x( WorldPosition123_g13 , ScreenUV123_g13 );
				half3 lightAddCol216 = localAdditionalLightsFlat14x123_g13;
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				half fresnelNdotV362 = dot( vertexNormal14, ase_worldViewDir );
				half fresnelNode362 = ( 0.0 + 2.0 * pow( max( 1.0 - fresnelNdotV362 , 0.0001 ), 3.0 ) );
				half dotResult366 = dot( ase_worldViewDir , _MainLightPosition.xyz );
				half temp_output_914_0 = saturate( -dotResult366 );
				half scattering143 = ( ( fresnelNode362 * ( temp_output_914_0 * temp_output_914_0 ) ) * occlussion333 * lightDirIntensity357 );
				half4 temp_output_391_0 = saturate( ( ( lerpResult594 * half4( grassColor335 , 0.0 ) * half4( lightCol222 , 0.0 ) ) + half4( ( lightAddCol216 * occlussion333 ) , 0.0 ) + scattering143 ) );
				half4 lerpResult537 = lerp( temp_output_391_0 , ( 0.5 * temp_output_391_0 ) , smoothstepResult538);
				half customEye2_g14 = IN.ase_texcoord6.w;
				half cameraDepthFade2_g14 = (( customEye2_g14 -_ProjectionParams.y - 0.0 ) / 1.0);
				half clampResult7_g14 = clamp( ( 1.0 - ( unity_FogParams.w + ( unity_FogParams.z * cameraDepthFade2_g14 ) ) ) , 0.0 , 1.0 );
				half4 lerpResult871 = lerp( lerpResult537 , unity_FogColor , ( clampResult7_g14 * saturate( unity_FogParams.w ) ));
				half4 finalColor438 = lerpResult871;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = finalColor438.rgb;
				float Alpha = alpha77;
				float AlphaClipThreshold = alphaClip52;
				float AlphaClipThresholdShadow = ( 1.0 - alphaClip52 );

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.positionCS, Color);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			

			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#define _ALPHATEST_SHADOW_ON 1
			#pragma multi_compile_instancing
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140011


			

			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#include "Assets/shell-grass/shaders/HLSL/triangle-data.hlsl"
			StructuredBuffer<DrawTriangle> _DrawTriangles;


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				nointerpolation float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _patchcolortop;
			half4 _patchcolorbottom;
			half4 _windmap_ST;
			half4 _patchmap_ST;
			half4 _albedo_ST;
			half4 _colorbottom;
			half4 _colortop;
			half4x4 _LocalToWorld;
			half4 _heightmap_ST;
			half _windstrength;
			half _albedoopacity;
			half _patchstrength;
			half _colorthreshold;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _heightmap;
			sampler2D _windmap;
			sampler2D _GlobalInteractiveRT;
			half _GlobalEffectCamOrthoSize;
			sampler2D _patchmap;


			half3 trianglesFromBuffer10( int vertexID, out half3 normal, out half2 uv, out half height )
			{
				DrawTriangle tri = _DrawTriangles[vertexID / 3.0];
				DrawVertex v = tri.vertices[vertexID % 3];
				normal = v.normal;
				uv = v.uv;
				height = v.height;
				return v.position;
			}
			

			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				int vertexID10 = v.ase_vertexID;
				half3 normal10 = float3( 0,0,0 );
				half2 uv10 = float2( 0,0 );
				half height10 = 0.0;
				half3 localtrianglesFromBuffer10 = trianglesFromBuffer10( vertexID10 , normal10 , uv10 , height10 );
				half3 vertexToFrag26 = localtrianglesFromBuffer10;
				half3 vertexPos13 = vertexToFrag26;
				
				half3 normalizeResult206 = normalize( normal10 );
				half3 vertexToFrag27 = normalizeResult206;
				half3 vertexNormal14 = vertexToFrag27;
				
				half4x4 objectToWorldMatrix495 = _LocalToWorld;
				half temp_output_308_0 = length( objectToWorldMatrix495[0] );
				half3 appendResult309 = (half3(temp_output_308_0 , temp_output_308_0 , temp_output_308_0));
				half3 vertexToFrag573 = appendResult309;
				half3 objectScale315 = vertexToFrag573;
				half2 vertexToFrag25 = uv10;
				half2 vertexUV15 = vertexToFrag25;
				half2 appendResult324 = (half2(( objectScale315 * half3( vertexUV15 ,  0.0 ) ).xy));
				half2 uvScaled894 = appendResult324;
				half2 vertexToFrag571 = ( ( uvScaled894 * _heightmap_ST.xy ) + ( _heightmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord2.xy = vertexToFrag571;
				half2 vertexToFrag569 = ( ( vertexUV15 * _windmap_ST.xy ) + ( _windmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord2.zw = vertexToFrag569;
				half vertexToFrag24 = height10;
				o.ase_texcoord3.x = vertexToFrag24;
				half2 vertexToFrag465 = ( ( (vertexPos13).xz / ( _GlobalEffectCamOrthoSize * 2.0 ) ) + 0.5 );
				o.ase_texcoord4.xy = vertexToFrag465;
				half2 vertexToFrag884 = ( ( vertexUV15 * _patchmap_ST.xy ) + ( _patchmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord4.zw = vertexToFrag884;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.yzw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vertexPos13;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = vertexNormal14;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.normalOS );

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.positionCS = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				half2 vertexToFrag571 = IN.ase_texcoord2.xy;
				half2 vertexToFrag569 = IN.ase_texcoord2.zw;
				half2 uvWind120 = vertexToFrag569;
				half4 tex2DNode58 = tex2D( _windmap, uvWind120 );
				half2 appendResult62 = (half2(tex2DNode58.r , tex2DNode58.g));
				half2 wind61 = appendResult62;
				half vertexToFrag24 = IN.ase_texcoord3.x;
				half alphaClip52 = vertexToFrag24;
				half2 vertexToFrag465 = IN.ase_texcoord4.xy;
				half2 uvInteractive542 = vertexToFrag465;
				half4 tex2DNode448 = tex2D( _GlobalInteractiveRT, uvInteractive542 );
				half4 interactiveRT534 = tex2DNode448;
				half smoothstepResult538 = smoothstep( 0.5 , 0.9 , interactiveRT534.r);
				half myVarName889 = smoothstepResult538;
				half2 windDistortion896 = ( wind61 * _windstrength * alphaClip52 * ( 1.0 - myVarName889 ) );
				half2 uvHeight115 = ( vertexToFrag571 + windDistortion896 );
				half height60 = tex2D( _heightmap, uvHeight115 ).r;
				half2 vertexToFrag884 = IN.ase_texcoord4.zw;
				half2 uvPatch517 = ( windDistortion896 + vertexToFrag884 );
				half patch521 = tex2D( _patchmap, uvPatch517 ).r;
				half lerpResult531 = lerp( height60 , saturate( ( height60 * ( 1.0 - patch521 ) ) ) , _patchstrength);
				half smoothstepResult589 = smoothstep( 0.7 , 1.0 , tex2DNode448.r);
				half alpha77 = saturate( ( ( lerpResult531 * ( 1.0 - min( smoothstepResult589 , 0.6 ) ) ) - tex2DNode448.g ) );
				

				float Alpha = alpha77;
				float AlphaClipThreshold = alphaClip52;
				float AlphaClipThresholdShadow = ( 1.0 - alphaClip52 );

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask R
			AlphaToMask Off

			HLSLPROGRAM

			

			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#define _ALPHATEST_SHADOW_ON 1
			#pragma multi_compile_instancing
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140011


			

			#pragma vertex vert
			#pragma fragment frag

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#include "Assets/shell-grass/shaders/HLSL/triangle-data.hlsl"
			StructuredBuffer<DrawTriangle> _DrawTriangles;


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 positionWS : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				nointerpolation float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _patchcolortop;
			half4 _patchcolorbottom;
			half4 _windmap_ST;
			half4 _patchmap_ST;
			half4 _albedo_ST;
			half4 _colorbottom;
			half4 _colortop;
			half4x4 _LocalToWorld;
			half4 _heightmap_ST;
			half _windstrength;
			half _albedoopacity;
			half _patchstrength;
			half _colorthreshold;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _heightmap;
			sampler2D _windmap;
			sampler2D _GlobalInteractiveRT;
			half _GlobalEffectCamOrthoSize;
			sampler2D _patchmap;


			half3 trianglesFromBuffer10( int vertexID, out half3 normal, out half2 uv, out half height )
			{
				DrawTriangle tri = _DrawTriangles[vertexID / 3.0];
				DrawVertex v = tri.vertices[vertexID % 3];
				normal = v.normal;
				uv = v.uv;
				height = v.height;
				return v.position;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				int vertexID10 = v.ase_vertexID;
				half3 normal10 = float3( 0,0,0 );
				half2 uv10 = float2( 0,0 );
				half height10 = 0.0;
				half3 localtrianglesFromBuffer10 = trianglesFromBuffer10( vertexID10 , normal10 , uv10 , height10 );
				half3 vertexToFrag26 = localtrianglesFromBuffer10;
				half3 vertexPos13 = vertexToFrag26;
				
				half3 normalizeResult206 = normalize( normal10 );
				half3 vertexToFrag27 = normalizeResult206;
				half3 vertexNormal14 = vertexToFrag27;
				
				half4x4 objectToWorldMatrix495 = _LocalToWorld;
				half temp_output_308_0 = length( objectToWorldMatrix495[0] );
				half3 appendResult309 = (half3(temp_output_308_0 , temp_output_308_0 , temp_output_308_0));
				half3 vertexToFrag573 = appendResult309;
				half3 objectScale315 = vertexToFrag573;
				half2 vertexToFrag25 = uv10;
				half2 vertexUV15 = vertexToFrag25;
				half2 appendResult324 = (half2(( objectScale315 * half3( vertexUV15 ,  0.0 ) ).xy));
				half2 uvScaled894 = appendResult324;
				half2 vertexToFrag571 = ( ( uvScaled894 * _heightmap_ST.xy ) + ( _heightmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord2.xy = vertexToFrag571;
				half2 vertexToFrag569 = ( ( vertexUV15 * _windmap_ST.xy ) + ( _windmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord2.zw = vertexToFrag569;
				half vertexToFrag24 = height10;
				o.ase_texcoord3.x = vertexToFrag24;
				half2 vertexToFrag465 = ( ( (vertexPos13).xz / ( _GlobalEffectCamOrthoSize * 2.0 ) ) + 0.5 );
				o.ase_texcoord4.xy = vertexToFrag465;
				half2 vertexToFrag884 = ( ( vertexUV15 * _patchmap_ST.xy ) + ( _patchmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord4.zw = vertexToFrag884;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.yzw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vertexPos13;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = vertexNormal14;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.positionWS = positionWS;
				#endif

				o.positionCS = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				half2 vertexToFrag571 = IN.ase_texcoord2.xy;
				half2 vertexToFrag569 = IN.ase_texcoord2.zw;
				half2 uvWind120 = vertexToFrag569;
				half4 tex2DNode58 = tex2D( _windmap, uvWind120 );
				half2 appendResult62 = (half2(tex2DNode58.r , tex2DNode58.g));
				half2 wind61 = appendResult62;
				half vertexToFrag24 = IN.ase_texcoord3.x;
				half alphaClip52 = vertexToFrag24;
				half2 vertexToFrag465 = IN.ase_texcoord4.xy;
				half2 uvInteractive542 = vertexToFrag465;
				half4 tex2DNode448 = tex2D( _GlobalInteractiveRT, uvInteractive542 );
				half4 interactiveRT534 = tex2DNode448;
				half smoothstepResult538 = smoothstep( 0.5 , 0.9 , interactiveRT534.r);
				half myVarName889 = smoothstepResult538;
				half2 windDistortion896 = ( wind61 * _windstrength * alphaClip52 * ( 1.0 - myVarName889 ) );
				half2 uvHeight115 = ( vertexToFrag571 + windDistortion896 );
				half height60 = tex2D( _heightmap, uvHeight115 ).r;
				half2 vertexToFrag884 = IN.ase_texcoord4.zw;
				half2 uvPatch517 = ( windDistortion896 + vertexToFrag884 );
				half patch521 = tex2D( _patchmap, uvPatch517 ).r;
				half lerpResult531 = lerp( height60 , saturate( ( height60 * ( 1.0 - patch521 ) ) ) , _patchstrength);
				half smoothstepResult589 = smoothstep( 0.7 , 1.0 , tex2DNode448.r);
				half alpha77 = saturate( ( ( lerpResult531 * ( 1.0 - min( smoothstepResult589 , 0.6 ) ) ) - tex2DNode448.g ) );
				

				float Alpha = alpha77;
				float AlphaClipThreshold = alphaClip52;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			

			#define _ALPHATEST_SHADOW_ON 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140011


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
			#if ASE_SRP_VERSION >=140010
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Assets/shell-grass/shaders/HLSL/triangle-data.hlsl"
			StructuredBuffer<DrawTriangle> _DrawTriangles;


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				nointerpolation float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _patchcolortop;
			half4 _patchcolorbottom;
			half4 _windmap_ST;
			half4 _patchmap_ST;
			half4 _albedo_ST;
			half4 _colorbottom;
			half4 _colortop;
			half4x4 _LocalToWorld;
			half4 _heightmap_ST;
			half _windstrength;
			half _albedoopacity;
			half _patchstrength;
			half _colorthreshold;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _heightmap;
			sampler2D _windmap;
			sampler2D _GlobalInteractiveRT;
			half _GlobalEffectCamOrthoSize;
			sampler2D _patchmap;


			half3 trianglesFromBuffer10( int vertexID, out half3 normal, out half2 uv, out half height )
			{
				DrawTriangle tri = _DrawTriangles[vertexID / 3.0];
				DrawVertex v = tri.vertices[vertexID % 3];
				normal = v.normal;
				uv = v.uv;
				height = v.height;
				return v.position;
			}
			

			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				int vertexID10 = v.ase_vertexID;
				half3 normal10 = float3( 0,0,0 );
				half2 uv10 = float2( 0,0 );
				half height10 = 0.0;
				half3 localtrianglesFromBuffer10 = trianglesFromBuffer10( vertexID10 , normal10 , uv10 , height10 );
				half3 vertexToFrag26 = localtrianglesFromBuffer10;
				half3 vertexPos13 = vertexToFrag26;
				
				half3 normalizeResult206 = normalize( normal10 );
				half3 vertexToFrag27 = normalizeResult206;
				half3 vertexNormal14 = vertexToFrag27;
				
				half4x4 objectToWorldMatrix495 = _LocalToWorld;
				half temp_output_308_0 = length( objectToWorldMatrix495[0] );
				half3 appendResult309 = (half3(temp_output_308_0 , temp_output_308_0 , temp_output_308_0));
				half3 vertexToFrag573 = appendResult309;
				half3 objectScale315 = vertexToFrag573;
				half2 vertexToFrag25 = uv10;
				half2 vertexUV15 = vertexToFrag25;
				half2 appendResult324 = (half2(( objectScale315 * half3( vertexUV15 ,  0.0 ) ).xy));
				half2 uvScaled894 = appendResult324;
				half2 vertexToFrag571 = ( ( uvScaled894 * _heightmap_ST.xy ) + ( _heightmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord.xy = vertexToFrag571;
				half2 vertexToFrag569 = ( ( vertexUV15 * _windmap_ST.xy ) + ( _windmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord.zw = vertexToFrag569;
				half vertexToFrag24 = height10;
				o.ase_texcoord1.x = vertexToFrag24;
				half2 vertexToFrag465 = ( ( (vertexPos13).xz / ( _GlobalEffectCamOrthoSize * 2.0 ) ) + 0.5 );
				o.ase_texcoord2.xy = vertexToFrag465;
				half2 vertexToFrag884 = ( ( vertexUV15 * _patchmap_ST.xy ) + ( _patchmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord2.zw = vertexToFrag884;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.yzw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vertexPos13;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = vertexNormal14;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );

				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				half2 vertexToFrag571 = IN.ase_texcoord.xy;
				half2 vertexToFrag569 = IN.ase_texcoord.zw;
				half2 uvWind120 = vertexToFrag569;
				half4 tex2DNode58 = tex2D( _windmap, uvWind120 );
				half2 appendResult62 = (half2(tex2DNode58.r , tex2DNode58.g));
				half2 wind61 = appendResult62;
				half vertexToFrag24 = IN.ase_texcoord1.x;
				half alphaClip52 = vertexToFrag24;
				half2 vertexToFrag465 = IN.ase_texcoord2.xy;
				half2 uvInteractive542 = vertexToFrag465;
				half4 tex2DNode448 = tex2D( _GlobalInteractiveRT, uvInteractive542 );
				half4 interactiveRT534 = tex2DNode448;
				half smoothstepResult538 = smoothstep( 0.5 , 0.9 , interactiveRT534.r);
				half myVarName889 = smoothstepResult538;
				half2 windDistortion896 = ( wind61 * _windstrength * alphaClip52 * ( 1.0 - myVarName889 ) );
				half2 uvHeight115 = ( vertexToFrag571 + windDistortion896 );
				half height60 = tex2D( _heightmap, uvHeight115 ).r;
				half2 vertexToFrag884 = IN.ase_texcoord2.zw;
				half2 uvPatch517 = ( windDistortion896 + vertexToFrag884 );
				half patch521 = tex2D( _patchmap, uvPatch517 ).r;
				half lerpResult531 = lerp( height60 , saturate( ( height60 * ( 1.0 - patch521 ) ) ) , _patchstrength);
				half smoothstepResult589 = smoothstep( 0.7 , 1.0 , tex2DNode448.r);
				half alpha77 = saturate( ( ( lerpResult531 * ( 1.0 - min( smoothstepResult589 , 0.6 ) ) ) - tex2DNode448.g ) );
				

				surfaceDescription.Alpha = alpha77;
				surfaceDescription.AlphaClipThreshold = alphaClip52;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			

			#define _ALPHATEST_SHADOW_ON 1
			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define _ALPHATEST_ON 1
			#define ASE_SRP_VERSION 140011


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT

			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
			#if ASE_SRP_VERSION >=140010
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#include "Assets/shell-grass/shaders/HLSL/triangle-data.hlsl"
			StructuredBuffer<DrawTriangle> _DrawTriangles;


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				nointerpolation float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _patchcolortop;
			half4 _patchcolorbottom;
			half4 _windmap_ST;
			half4 _patchmap_ST;
			half4 _albedo_ST;
			half4 _colorbottom;
			half4 _colortop;
			half4x4 _LocalToWorld;
			half4 _heightmap_ST;
			half _windstrength;
			half _albedoopacity;
			half _patchstrength;
			half _colorthreshold;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _heightmap;
			sampler2D _windmap;
			sampler2D _GlobalInteractiveRT;
			half _GlobalEffectCamOrthoSize;
			sampler2D _patchmap;


			half3 trianglesFromBuffer10( int vertexID, out half3 normal, out half2 uv, out half height )
			{
				DrawTriangle tri = _DrawTriangles[vertexID / 3.0];
				DrawVertex v = tri.vertices[vertexID % 3];
				normal = v.normal;
				uv = v.uv;
				height = v.height;
				return v.position;
			}
			

			float4 _SelectionID;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				int vertexID10 = v.ase_vertexID;
				half3 normal10 = float3( 0,0,0 );
				half2 uv10 = float2( 0,0 );
				half height10 = 0.0;
				half3 localtrianglesFromBuffer10 = trianglesFromBuffer10( vertexID10 , normal10 , uv10 , height10 );
				half3 vertexToFrag26 = localtrianglesFromBuffer10;
				half3 vertexPos13 = vertexToFrag26;
				
				half3 normalizeResult206 = normalize( normal10 );
				half3 vertexToFrag27 = normalizeResult206;
				half3 vertexNormal14 = vertexToFrag27;
				
				half4x4 objectToWorldMatrix495 = _LocalToWorld;
				half temp_output_308_0 = length( objectToWorldMatrix495[0] );
				half3 appendResult309 = (half3(temp_output_308_0 , temp_output_308_0 , temp_output_308_0));
				half3 vertexToFrag573 = appendResult309;
				half3 objectScale315 = vertexToFrag573;
				half2 vertexToFrag25 = uv10;
				half2 vertexUV15 = vertexToFrag25;
				half2 appendResult324 = (half2(( objectScale315 * half3( vertexUV15 ,  0.0 ) ).xy));
				half2 uvScaled894 = appendResult324;
				half2 vertexToFrag571 = ( ( uvScaled894 * _heightmap_ST.xy ) + ( _heightmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord.xy = vertexToFrag571;
				half2 vertexToFrag569 = ( ( vertexUV15 * _windmap_ST.xy ) + ( _windmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord.zw = vertexToFrag569;
				half vertexToFrag24 = height10;
				o.ase_texcoord1.x = vertexToFrag24;
				half2 vertexToFrag465 = ( ( (vertexPos13).xz / ( _GlobalEffectCamOrthoSize * 2.0 ) ) + 0.5 );
				o.ase_texcoord2.xy = vertexToFrag465;
				half2 vertexToFrag884 = ( ( vertexUV15 * _patchmap_ST.xy ) + ( _patchmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord2.zw = vertexToFrag884;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.yzw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vertexPos13;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = vertexNormal14;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				o.positionCS = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				half2 vertexToFrag571 = IN.ase_texcoord.xy;
				half2 vertexToFrag569 = IN.ase_texcoord.zw;
				half2 uvWind120 = vertexToFrag569;
				half4 tex2DNode58 = tex2D( _windmap, uvWind120 );
				half2 appendResult62 = (half2(tex2DNode58.r , tex2DNode58.g));
				half2 wind61 = appendResult62;
				half vertexToFrag24 = IN.ase_texcoord1.x;
				half alphaClip52 = vertexToFrag24;
				half2 vertexToFrag465 = IN.ase_texcoord2.xy;
				half2 uvInteractive542 = vertexToFrag465;
				half4 tex2DNode448 = tex2D( _GlobalInteractiveRT, uvInteractive542 );
				half4 interactiveRT534 = tex2DNode448;
				half smoothstepResult538 = smoothstep( 0.5 , 0.9 , interactiveRT534.r);
				half myVarName889 = smoothstepResult538;
				half2 windDistortion896 = ( wind61 * _windstrength * alphaClip52 * ( 1.0 - myVarName889 ) );
				half2 uvHeight115 = ( vertexToFrag571 + windDistortion896 );
				half height60 = tex2D( _heightmap, uvHeight115 ).r;
				half2 vertexToFrag884 = IN.ase_texcoord2.zw;
				half2 uvPatch517 = ( windDistortion896 + vertexToFrag884 );
				half patch521 = tex2D( _patchmap, uvPatch517 ).r;
				half lerpResult531 = lerp( height60 , saturate( ( height60 * ( 1.0 - patch521 ) ) ) , _patchstrength);
				half smoothstepResult589 = smoothstep( 0.7 , 1.0 , tex2DNode448.r);
				half alpha77 = saturate( ( ( lerpResult531 * ( 1.0 - min( smoothstepResult589 , 0.6 ) ) ) - tex2DNode448.g ) );
				

				surfaceDescription.Alpha = alpha77;
				surfaceDescription.AlphaClipThreshold = alphaClip52;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			

        	#pragma multi_compile _ LOD_FADE_CROSSFADE
        	#define _ALPHATEST_SHADOW_ON 1
        	#pragma multi_compile_instancing
        	#define ASE_ABSOLUTE_VERTEX_POS 1
        	#define _ALPHATEST_ON 1
        	#define ASE_SRP_VERSION 140011


			

        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
			#if ASE_SRP_VERSION >=140010
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#include "Assets/shell-grass/shaders/HLSL/triangle-data.hlsl"
			StructuredBuffer<DrawTriangle> _DrawTriangles;


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				nointerpolation float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _patchcolortop;
			half4 _patchcolorbottom;
			half4 _windmap_ST;
			half4 _patchmap_ST;
			half4 _albedo_ST;
			half4 _colorbottom;
			half4 _colortop;
			half4x4 _LocalToWorld;
			half4 _heightmap_ST;
			half _windstrength;
			half _albedoopacity;
			half _patchstrength;
			half _colorthreshold;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _heightmap;
			sampler2D _windmap;
			sampler2D _GlobalInteractiveRT;
			half _GlobalEffectCamOrthoSize;
			sampler2D _patchmap;


			half3 trianglesFromBuffer10( int vertexID, out half3 normal, out half2 uv, out half height )
			{
				DrawTriangle tri = _DrawTriangles[vertexID / 3.0];
				DrawVertex v = tri.vertices[vertexID % 3];
				normal = v.normal;
				uv = v.uv;
				height = v.height;
				return v.position;
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				int vertexID10 = v.ase_vertexID;
				half3 normal10 = float3( 0,0,0 );
				half2 uv10 = float2( 0,0 );
				half height10 = 0.0;
				half3 localtrianglesFromBuffer10 = trianglesFromBuffer10( vertexID10 , normal10 , uv10 , height10 );
				half3 vertexToFrag26 = localtrianglesFromBuffer10;
				half3 vertexPos13 = vertexToFrag26;
				
				half3 normalizeResult206 = normalize( normal10 );
				half3 vertexToFrag27 = normalizeResult206;
				half3 vertexNormal14 = vertexToFrag27;
				
				half4x4 objectToWorldMatrix495 = _LocalToWorld;
				half temp_output_308_0 = length( objectToWorldMatrix495[0] );
				half3 appendResult309 = (half3(temp_output_308_0 , temp_output_308_0 , temp_output_308_0));
				half3 vertexToFrag573 = appendResult309;
				half3 objectScale315 = vertexToFrag573;
				half2 vertexToFrag25 = uv10;
				half2 vertexUV15 = vertexToFrag25;
				half2 appendResult324 = (half2(( objectScale315 * half3( vertexUV15 ,  0.0 ) ).xy));
				half2 uvScaled894 = appendResult324;
				half2 vertexToFrag571 = ( ( uvScaled894 * _heightmap_ST.xy ) + ( _heightmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord1.xy = vertexToFrag571;
				half2 vertexToFrag569 = ( ( vertexUV15 * _windmap_ST.xy ) + ( _windmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord1.zw = vertexToFrag569;
				half vertexToFrag24 = height10;
				o.ase_texcoord2.x = vertexToFrag24;
				half2 vertexToFrag465 = ( ( (vertexPos13).xz / ( _GlobalEffectCamOrthoSize * 2.0 ) ) + 0.5 );
				o.ase_texcoord3.xy = vertexToFrag465;
				half2 vertexToFrag884 = ( ( vertexUV15 * _patchmap_ST.xy ) + ( _patchmap_ST.zw * _TimeParameters.x ) );
				o.ase_texcoord3.zw = vertexToFrag884;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.yzw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = vertexPos13;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				v.normalOS = vertexNormal14;

				float3 positionWS = TransformObjectToWorld( v.positionOS.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

				o.positionCS = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 normalOS : NORMAL;
				uint ase_vertexID : SV_VertexID;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.positionOS;
				o.normalOS = v.normalOS;
				o.ase_vertexID = v.ase_vertexID;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.positionOS = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				o.ase_vertexID = patch[0].ase_vertexID * bary.x + patch[1].ase_vertexID * bary.y + patch[2].ase_vertexID * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.positionOS.xyz - patch[i].normalOS * (dot(o.positionOS.xyz, patch[i].normalOS) - dot(patch[i].vertex.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				o.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag( VertexOutput IN
				, out half4 outNormalWS : SV_Target0
			#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
			#endif
				 )
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				half2 vertexToFrag571 = IN.ase_texcoord1.xy;
				half2 vertexToFrag569 = IN.ase_texcoord1.zw;
				half2 uvWind120 = vertexToFrag569;
				half4 tex2DNode58 = tex2D( _windmap, uvWind120 );
				half2 appendResult62 = (half2(tex2DNode58.r , tex2DNode58.g));
				half2 wind61 = appendResult62;
				half vertexToFrag24 = IN.ase_texcoord2.x;
				half alphaClip52 = vertexToFrag24;
				half2 vertexToFrag465 = IN.ase_texcoord3.xy;
				half2 uvInteractive542 = vertexToFrag465;
				half4 tex2DNode448 = tex2D( _GlobalInteractiveRT, uvInteractive542 );
				half4 interactiveRT534 = tex2DNode448;
				half smoothstepResult538 = smoothstep( 0.5 , 0.9 , interactiveRT534.r);
				half myVarName889 = smoothstepResult538;
				half2 windDistortion896 = ( wind61 * _windstrength * alphaClip52 * ( 1.0 - myVarName889 ) );
				half2 uvHeight115 = ( vertexToFrag571 + windDistortion896 );
				half height60 = tex2D( _heightmap, uvHeight115 ).r;
				half2 vertexToFrag884 = IN.ase_texcoord3.zw;
				half2 uvPatch517 = ( windDistortion896 + vertexToFrag884 );
				half patch521 = tex2D( _patchmap, uvPatch517 ).r;
				half lerpResult531 = lerp( height60 , saturate( ( height60 * ( 1.0 - patch521 ) ) ) , _patchstrength);
				half smoothstepResult589 = smoothstep( 0.7 , 1.0 , tex2DNode448.r);
				half alpha77 = saturate( ( ( lerpResult531 * ( 1.0 - min( smoothstepResult589 , 0.6 ) ) ) - tex2DNode448.g ) );
				

				surfaceDescription.Alpha = alpha77;
				surfaceDescription.AlphaClipThreshold = alphaClip52;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.positionCS );
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float3 normalWS = normalize(IN.normalWS);
					float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					float3 normalWS = IN.normalWS;
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
				#endif
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "ASEMaterialInspector"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19403
Node;AmplifyShaderEditor.CommentaryNode;51;-5184,1952;Inherit;False;1674.458;480.7294;;11;14;13;52;26;206;27;24;15;25;10;11;Vertex Details;0,0,0,1;0;0
Node;AmplifyShaderEditor.VertexIdVariableNode;11;-5136,2112;Inherit;False;0;1;INT;0
Node;AmplifyShaderEditor.CustomExpressionNode;10;-4976,2112;Inherit;False;$DrawTriangle tri = _DrawTriangles[vertexID / 3.0]@$DrawVertex v = tri.vertices[vertexID % 3]@$$normal = v.normal@$uv = v.uv@$height = v.height@$return v.position@;3;Create;4;True;vertexID;INT;0;In;;Inherit;False;False;normal;FLOAT3;0,0,0;Out;;Inherit;False;False;uv;FLOAT2;0,0;Out;;Inherit;False;True;height;FLOAT;0;Out;;Inherit;False;trianglesFromBuffer;True;False;0;;False;4;0;INT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT2;0,0;False;3;FLOAT;0;False;4;FLOAT3;0;FLOAT3;2;FLOAT2;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;125;-8000,-2016;Inherit;False;2212.734;2429.807;;18;896;135;891;890;136;134;292;894;332;324;321;82;323;331;519;330;543;906;UV;0,0,0,1;0;0
Node;AmplifyShaderEditor.VertexToFragmentNode;26;-4688,2016;Inherit;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;543;-7936,-16;Inherit;False;1300;338.8;;11;542;0;465;466;453;467;452;454;445;455;407;interactiveUV;0,0,0,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;13;-4448,2016;Inherit;False;vertexPos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;407;-7888,112;Inherit;False;Global;_GlobalEffectCamOrthoSize;_GlobalEffectCamOrthoSize;11;0;Create;True;0;0;0;False;0;False;0;20;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;455;-7760,208;Inherit;False;Constant;_Float2;Float 2;12;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;445;-7792,32;Inherit;False;13;vertexPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;63;-5264,-2032;Inherit;False;2086.566;1033.432;;28;100;101;104;103;61;505;59;506;507;81;98;99;97;96;60;20;124;102;62;58;105;123;508;509;510;511;512;521;TexSamples;0,0,0,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;454;-7600,112;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;452;-7600,32;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;467;-7424,128;Inherit;False;Constant;_Float3;Float 3;12;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;453;-7424,32;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;103;-5184,-1584;Inherit;True;Property;_windmap;wind-map;7;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.CommentaryNode;326;-5184,2528;Inherit;False;1377.91;291.2949;;7;315;573;309;308;307;495;492;Object Scale;0,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;330;-7936,-496;Inherit;False;1582.523;439.822;;9;120;569;580;576;116;579;325;117;119;windUV;0,0,0,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;466;-7248,32;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;104;-4976,-1584;Inherit;False;texWind;-1;True;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.VertexToFragmentNode;25;-4688,2176;Inherit;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;119;-7888,-368;Inherit;False;104;texWind;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.VertexToFragmentNode;465;-7120,32;Inherit;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;15;-4448,2176;Inherit;False;vertexUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Matrix4X4Node;492;-5088,2608;Inherit;False;Property;_LocalToWorld;_LocalToWorld;14;0;Create;True;0;0;0;False;0;False;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.CommentaryNode;327;-5168,1392;Inherit;False;2639.479;431.0499;;18;546;903;77;470;500;534;550;549;589;544;448;72;531;528;556;526;523;882;Alpha;0,0,0,1;0;0
Node;AmplifyShaderEditor.TextureTransformNode;117;-7712,-368;Inherit;False;-1;False;1;0;SAMPLER2D;;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.SimpleTimeNode;579;-7360,-256;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;325;-7680,-448;Inherit;False;15;vertexUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;542;-6880,32;Inherit;False;uvInteractive;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;495;-4816,2608;Inherit;False;objectToWorldMatrix;-1;True;1;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;116;-7440,-416;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;580;-7168,-336;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VectorFromMatrixNode;307;-4576,2608;Inherit;False;Row;0;1;0;FLOAT4x4;1,0,0,1,1,1,1,0,1,0,1,0,0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;544;-4336,1568;Inherit;False;542;uvInteractive;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;576;-6992,-416;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LengthOpNode;308;-4400,2608;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;448;-4128,1568;Inherit;True;Global;_GlobalInteractiveRT;_GlobalInteractiveRT;15;0;Create;True;0;0;0;False;0;False;-1;None;;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexToFragmentNode;569;-6864,-416;Inherit;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;309;-4240,2608;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;534;-3824,1712;Inherit;False;interactiveRT;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;120;-6656,-416;Half;False;uvWind;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexToFragmentNode;573;-4096,2672;Inherit;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;536;-1168,624;Inherit;False;534;interactiveRT;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;105;-4432,-1552;Inherit;False;104;texWind;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;123;-4432,-1472;Inherit;False;120;uvWind;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;315;-4096,2608;Inherit;False;objectScale;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;541;-960,624;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SamplerNode;58;-4208,-1552;Inherit;True;Property;_windmapsample;wind-map-sample;0;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;508;-5184,-1392;Inherit;True;Property;_patchmap;patch-map;10;0;Create;True;0;0;0;False;0;False;None;None;False;black;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.GetLocalVarNode;323;-7904,-1968;Inherit;False;315;objectScale;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;82;-7904,-1888;Inherit;False;15;vertexUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SmoothstepOpNode;538;-848,624;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.9;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;101;-5184,-1776;Inherit;True;Property;_heightmap;height-map;6;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.DynamicAppendNode;62;-3936,-1552;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;519;-7952,-928;Inherit;False;1352.905;309.1595;;11;517;516;898;884;563;562;513;561;518;520;515;patchUV;0,0,0,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;509;-4960,-1392;Inherit;False;texPatch;-1;True;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;321;-7712,-1936;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexToFragmentNode;24;-4688,2256;Inherit;False;True;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;889;-624,544;Inherit;False;myVarName;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;331;-7952,-1360;Inherit;False;1511.977;343.8488;;11;567;568;895;115;897;133;571;112;113;111;114;heightUV;0,0,0,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;100;-4976,-1776;Inherit;False;texHeight;-1;True;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;890;-6544,-688;Inherit;False;889;myVarName;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-3776,-1552;Half;False;wind;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;515;-7920,-816;Inherit;False;509;texPatch;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.DynamicAppendNode;324;-7568,-1936;Inherit;False;FLOAT2;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;52;-4448,2256;Inherit;False;alphaClip;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;-7920,-1216;Inherit;False;100;texHeight;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;292;-6416,-768;Inherit;False;52;alphaClip;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;134;-6416,-928;Inherit;False;61;wind;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;136;-6512,-848;Inherit;False;Property;_windstrength;wind-strength;9;0;Create;True;0;0;0;False;0;False;0.019;0.019;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;891;-6368,-688;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;520;-7696,-880;Inherit;False;15;vertexUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureTransformNode;518;-7728,-816;Inherit;False;-1;False;1;0;SAMPLER2D;;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.SimpleTimeNode;561;-7696,-720;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;894;-7408,-1936;Half;False;uvScaled;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureTransformNode;112;-7728,-1216;Inherit;False;-1;False;1;0;SAMPLER2D;;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.GetLocalVarNode;895;-7920,-1312;Inherit;False;894;uvScaled;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;567;-7696,-1120;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;135;-6192,-848;Inherit;False;4;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;513;-7488,-880;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;562;-7488,-784;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;111;-7488,-1312;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;568;-7488,-1216;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;896;-6032,-848;Half;False;windDistortion;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;563;-7344,-848;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;113;-7312,-1264;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexToFragmentNode;884;-7232,-784;Inherit;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;898;-7232,-864;Inherit;False;896;windDistortion;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexToFragmentNode;571;-7184,-1264;Inherit;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;897;-7184,-1184;Inherit;False;896;windDistortion;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;516;-6960,-864;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;133;-6960,-1264;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;517;-6848,-864;Half;False;uvPatch;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;115;-6832,-1264;Half;False;uvHeight;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;512;-4432,-1264;Inherit;False;517;uvPatch;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;510;-4432,-1344;Inherit;False;509;texPatch;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;102;-4432,-1744;Inherit;False;100;texHeight;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;124;-4432,-1664;Inherit;False;115;uvHeight;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;511;-4208,-1344;Inherit;True;Property;_patchmapsample;patch-map-sample;0;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;20;-4208,-1744;Inherit;True;Property;_heightmapsample;height-map-sample;0;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;521;-3920,-1344;Half;False;patch;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-3920,-1744;Half;False;height;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;523;-5120,1552;Inherit;False;521;patch;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;526;-4928,1552;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;72;-4960,1440;Inherit;False;60;height;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;882;-4784,1520;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;589;-3824,1568;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.7;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;556;-4640,1520;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;528;-4640,1600;Inherit;False;Property;_patchstrength;patch-strength;13;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;549;-3632,1568;Inherit;False;2;0;FLOAT;0.6;False;1;FLOAT;0.6;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;531;-4336,1440;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;550;-3504,1568;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;903;-3824,1680;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;546;-3344,1440;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;500;-3168,1616;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;206;-4688,2096;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;470;-2992,1616;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexToFragmentNode;27;-4448,2096;Inherit;False;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;892;-544,-2574;Inherit;False;2046.212;519.5323;;14;397;443;394;393;395;396;501;503;502;551;552;893;901;904;Obsolete;1,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;588;-3760,2528;Inherit;False;804;242.8;;4;64;333;245;246;Occlussion;0,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;388;-7968,1456;Inherit;False;845.8259;231.9865;;5;386;384;385;263;264;Ambient;0,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;380;-5168,576;Inherit;False;1405.098;669.0739;;13;335;67;554;474;389;334;390;592;70;127;69;66;910;GrassColor;0,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;337;-7040,1456;Inherit;False;1077.278;221.3318;;6;387;269;222;239;211;268;LightColor;0,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;329;-7968,1104;Inherit;False;682.7114;299.6;;6;218;234;586;357;223;217;DirLight;0,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;328;-7968,1760;Inherit;False;1428.676;456.5637;;14;143;362;363;364;366;371;372;369;374;373;375;376;913;914;Scattering;0,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;270;-7968,608;Inherit;False;1217.79;379.8533;;9;208;473;471;209;238;240;202;232;201;dotNL;0,0,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;332;-7952,-1760;Inherit;False;1688.476;326.8521;;11;109;293;899;572;107;84;885;565;95;108;900;albedoUV;0,0,0,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;77;-2816,1616;Inherit;False;alpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;14;-4224,2096;Inherit;False;vertexNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;96;-5184,-1968;Inherit;True;Property;_albedo;albedo;4;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;97;-4976,-1968;Inherit;False;texAlbedo;-1;True;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.SamplerNode;99;-4208,-1936;Inherit;True;Property;_albedosample;albedo-sample;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;98;-4432,-1936;Inherit;False;97;texAlbedo;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;81;-4432,-1856;Inherit;False;109;uvAlbedo;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;505;-3936,-1856;Inherit;False;Property;_albedoopacity;albedo-opacity;5;0;Create;True;0;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;108;-7920,-1632;Inherit;False;97;texAlbedo;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.TextureTransformNode;95;-7728,-1632;Inherit;False;-1;False;1;0;SAMPLER2D;;False;2;FLOAT2;0;FLOAT2;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;565;-7488,-1600;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;885;-7920,-1712;Inherit;False;15;vertexUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;84;-7488,-1712;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;107;-7328,-1664;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.VertexToFragmentNode;572;-7200,-1664;Inherit;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;899;-7200,-1584;Inherit;False;896;windDistortion;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;293;-6976,-1664;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;900;-7696,-1536;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;217;-7920,1168;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;223;-7728,1232;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;268;-6704,1504;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;364;-7888,1888;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;371;-7920,2032;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;366;-7664,1984;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;372;-7552,1984;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;201;-7680,656;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;202;-7920,736;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;387;-6528,1568;Inherit;False;386;lightAmbient;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;240;-7376,656;Inherit;False;220;lightAtten;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;238;-7136,656;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;473;-7520,656;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;357;-7520,1152;Inherit;False;lightDirIntensity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexToFragmentNode;586;-7728,1152;Inherit;False;False;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;222;-6192,1504;Inherit;False;lightCol;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;232;-7920,656;Inherit;False;14;vertexNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;363;-7920,1808;Inherit;False;14;vertexNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LightAttenuation;212;-7216,1104;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerStateNode;502;208,-2384;Inherit;False;0;0;0;1;-1;None;1;0;SAMPLER2D;;False;1;SAMPLERSTATE;0
Node;AmplifyShaderEditor.GetLocalVarNode;503;32,-2384;Inherit;False;104;texWind;1;0;OBJECT;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.CustomExpressionNode;501;384,-2432;Half;False;    half2 nUV = UV + _Time.x * speed@$    half2 n = _windmap.Sample(ss, nUV).xy@$    half s = (sin(_Time.y * 1.6 + 1) - cos(_Time.y + n.x * 2)) * 0.5 + n.y * 0.5@$    n *= s * _windstrength@$    return n@;2;Create;3;True;UV;FLOAT2;0,0;In;;Inherit;False;True;speed;FLOAT2;0,0;In;;Inherit;False;True;ss;SAMPLERSTATE;;In;;Inherit;False;GrassWind;False;False;0;793145913100214469e1ebe668a56c27;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;SAMPLERSTATE;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;396;1136,-2384;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;395;560,-2384;Inherit;False;Property;_windcol;wind-col;8;0;Create;True;0;0;0;False;0;False;1,0.8394764,0.3754716,0;1,0.8394764,0.3754716,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;393;768,-2304;Inherit;False;61;wind;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DotProductOpNode;394;944,-2320;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;443;880,-2224;Inherit;False;220;lightAtten;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;397;880,-2160;Inherit;False;52;alphaClip;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;551;-256,-2400;Inherit;False;GradientASE;-1;;11;;0;0;0
Node;AmplifyShaderEditor.TexturePropertyNode;552;-496,-2400;Inherit;True;Property;_Gradientgrasscolor;[Gradient] grass-color;0;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.VertexToFragmentNode;906;-6032,-688;Inherit;False;False;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;263;-7744,1504;Inherit;False;Tangent;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;385;-7712,1584;Inherit;False;333;occlussion;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;264;-7952,1504;Inherit;False;14;vertexNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;213;-7216,1184;Inherit;False;SRP Additional Light;-1;;13;6c86746ad131a0a408ca599df5f40861;8,212,0,6,0,9,0,23,0,24,0,142,0,168,0,154,0;6;2;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;15;FLOAT3;0,0,0;False;14;FLOAT3;0,0,0;False;18;FLOAT;0.5;False;32;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;216;-7008,1184;Half;False;lightAddCol;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;386;-7344,1504;Half;False;lightAmbient;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;209;-6976,656;Half;False;dotNL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;109;-6848,-1664;Half;False;uvAlbedo;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;506;-3616,-1952;Inherit;False;3;0;COLOR;1,1,1,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;507;-3776,-1968;Inherit;False;Constant;_Float4;Float 4;13;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;59;-3472,-1936;Half;False;albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;79;608,304;Inherit;False;438;finalColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;18;608,496;Inherit;False;13;vertexPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;78;608,368;Inherit;False;77;alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;53;608,432;Inherit;False;52;alphaClip;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;909;576,560;Inherit;False;14;vertexNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FresnelNode;362;-7664,1808;Inherit;False;Standard;WorldNormal;ViewDir;False;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;2;False;3;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;369;-7120,1808;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;374;-7120,1904;Inherit;False;333;occlussion;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;376;-7120,1984;Inherit;False;357;lightDirIntensity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;143;-6752,1808;Inherit;False;scattering;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;913;-7088,2064;Inherit;False;209;dotNL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;373;-6896,1808;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;914;-7424,1984;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;375;-7280,1968;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;127;-4336,624;Inherit;False;FLOAT3;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;64;-3712,2576;Inherit;False;52;alphaClip;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;245;-3712,2656;Inherit;False;77;alpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;246;-3488,2576;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;333;-3328,2576;Inherit;False;occlussion;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;592;-4496,704;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;390;-5136,1136;Inherit;False;Property;_colorthreshold;color-threshold;3;0;Create;True;0;0;0;False;0;False;1;0;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;389;-4848,1056;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;474;-4704,1056;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;554;-4336,704;Inherit;False;FLOAT3;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-4160,624;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;335;-4016,624;Inherit;False;grassColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;69;-5136,880;Inherit;False;Property;_colortop;color-top;1;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;70;-5136,704;Inherit;False;Property;_colorbottom;color-bottom;2;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;334;-5136,1056;Inherit;False;333;occlussion;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;66;-5136,624;Inherit;False;59;albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;595;-2240,368;Inherit;False;Property;_patchcolortop;patch-color-top;11;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;593;-2208,544;Inherit;False;521;patch;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;596;-2240,192;Inherit;False;Property;_patchcolorbottom;patch-color-bottom;12;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;594;-1984,272;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;336;-1968,416;Inherit;False;335;grassColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;236;-1760,544;Inherit;False;216;lightAddCol;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;383;-1760,624;Inherit;False;333;occlussion;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;242;-1568,544;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;910;-4784,944;Inherit;False;60;height;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;915;882.7178,558.1385;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;239;-6992,1584;Inherit;False;218;lightDirCol;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;211;-6992,1504;Inherit;False;209;dotNL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;471;-7680,768;Inherit;False;333;occlussion;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;384;-7504,1504;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;539;-1168,496;Inherit;False;Constant;_Float0;Float 0;15;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;540;-992,496;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;872;-384,496;Inherit;False;unity_FogColor;0;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;874;-560,624;Inherit;False;13;vertexPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;537;-624,416;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;876;-384,624;Inherit;False;CustomFog;-1;;14;21d1f78c04be1ee4294c9f8557ac0592;0;2;9;FLOAT3;0,0,0;False;6;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;871;-80,416;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;438;64,416;Inherit;False;finalColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;391;-1168,416;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;241;-1312,416;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;905;-1584,640;Inherit;False;143;scattering;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;234;-7920,1296;Inherit;False;220;lightAtten;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;919;-6934.512,1081.482;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;918;-7216,1024;Inherit;False;357;lightDirIntensity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;220;-6784,1088;Inherit;False;lightAtten;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;218;-7520,1232;Inherit;False;lightDirCol;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;269;-6304,1504;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;210;-1728,416;Inherit;False;3;3;0;COLOR;1,1,1,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;208;-7376,736;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;338;-1968,496;Inherit;False;222;lightCol;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;True;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;8;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;9;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;-7072,80;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;912,304;Half;False;True;-1;2;ASEMaterialInspector;0;13;ShellGrass;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;0;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;3;Include;;False;;Native;False;0;0;;Include;;True;bab2c1bc8fefd114d9c9cdfb80ac4ad3;Custom;False;0;0;;Custom;StructuredBuffer<DrawTriangle> _DrawTriangles@;False;;Custom;False;0;0;;;0;0;Standard;22;Surface;0;0;  Blend;0;0;Two Sided;0;638539178777098898;Forward Only;0;0;Cast Shadows;1;638541344589310241;  Use Shadow Threshold;1;638538814754733709;Receive Shadows;1;638531434519534600;GPU Instancing;1;638538897553638387;LOD CrossFade;1;0;Built-in Fog;0;638537965233235574;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;638538902440676102;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;0;638540650190840201;0;10;False;True;True;True;False;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.CommentaryNode;904;560,-2496;Inherit;False;702.2446;101.7253;Wind Color;0;;0.5245282,0.3955834,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;901;48,-2512;Inherit;False;308.8;100;Wind;0;;0.5025774,0.8443158,0.9547169,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;893;-496,-2512;Inherit;False;500.08;103.6592;Gradient Grass;0;;0.4960943,1,0,1;0;0
WireConnection;10;0;11;0
WireConnection;26;0;10;0
WireConnection;13;0;26;0
WireConnection;454;0;407;0
WireConnection;454;1;455;0
WireConnection;452;0;445;0
WireConnection;453;0;452;0
WireConnection;453;1;454;0
WireConnection;466;0;453;0
WireConnection;466;1;467;0
WireConnection;104;0;103;0
WireConnection;25;0;10;3
WireConnection;465;0;466;0
WireConnection;15;0;25;0
WireConnection;117;0;119;0
WireConnection;542;0;465;0
WireConnection;495;0;492;0
WireConnection;116;0;325;0
WireConnection;116;1;117;0
WireConnection;580;0;117;1
WireConnection;580;1;579;0
WireConnection;307;0;495;0
WireConnection;576;0;116;0
WireConnection;576;1;580;0
WireConnection;308;0;307;0
WireConnection;448;1;544;0
WireConnection;569;0;576;0
WireConnection;309;0;308;0
WireConnection;309;1;308;0
WireConnection;309;2;308;0
WireConnection;534;0;448;0
WireConnection;120;0;569;0
WireConnection;573;0;309;0
WireConnection;315;0;573;0
WireConnection;541;0;536;0
WireConnection;58;0;105;0
WireConnection;58;1;123;0
WireConnection;538;0;541;0
WireConnection;62;0;58;1
WireConnection;62;1;58;2
WireConnection;509;0;508;0
WireConnection;321;0;323;0
WireConnection;321;1;82;0
WireConnection;24;0;10;4
WireConnection;889;0;538;0
WireConnection;100;0;101;0
WireConnection;61;0;62;0
WireConnection;324;0;321;0
WireConnection;52;0;24;0
WireConnection;891;0;890;0
WireConnection;518;0;515;0
WireConnection;894;0;324;0
WireConnection;112;0;114;0
WireConnection;135;0;134;0
WireConnection;135;1;136;0
WireConnection;135;2;292;0
WireConnection;135;3;891;0
WireConnection;513;0;520;0
WireConnection;513;1;518;0
WireConnection;562;0;518;1
WireConnection;562;1;561;0
WireConnection;111;0;895;0
WireConnection;111;1;112;0
WireConnection;568;0;112;1
WireConnection;568;1;567;0
WireConnection;896;0;135;0
WireConnection;563;0;513;0
WireConnection;563;1;562;0
WireConnection;113;0;111;0
WireConnection;113;1;568;0
WireConnection;884;0;563;0
WireConnection;571;0;113;0
WireConnection;516;0;898;0
WireConnection;516;1;884;0
WireConnection;133;0;571;0
WireConnection;133;1;897;0
WireConnection;517;0;516;0
WireConnection;115;0;133;0
WireConnection;511;0;510;0
WireConnection;511;1;512;0
WireConnection;20;0;102;0
WireConnection;20;1;124;0
WireConnection;521;0;511;1
WireConnection;60;0;20;1
WireConnection;526;0;523;0
WireConnection;882;0;72;0
WireConnection;882;1;526;0
WireConnection;589;0;448;1
WireConnection;556;0;882;0
WireConnection;549;0;589;0
WireConnection;531;0;72;0
WireConnection;531;1;556;0
WireConnection;531;2;528;0
WireConnection;550;0;549;0
WireConnection;903;0;448;2
WireConnection;546;0;531;0
WireConnection;546;1;550;0
WireConnection;500;0;546;0
WireConnection;500;1;903;0
WireConnection;206;0;10;2
WireConnection;470;0;500;0
WireConnection;27;0;206;0
WireConnection;77;0;470;0
WireConnection;14;0;27;0
WireConnection;97;0;96;0
WireConnection;99;0;98;0
WireConnection;99;1;81;0
WireConnection;95;0;108;0
WireConnection;565;0;95;1
WireConnection;565;1;900;0
WireConnection;84;0;885;0
WireConnection;84;1;95;0
WireConnection;107;0;84;0
WireConnection;107;1;565;0
WireConnection;572;0;107;0
WireConnection;293;0;572;0
WireConnection;293;1;899;0
WireConnection;223;0;217;1
WireConnection;223;1;234;0
WireConnection;268;0;211;0
WireConnection;268;1;239;0
WireConnection;366;0;364;0
WireConnection;366;1;371;0
WireConnection;372;0;366;0
WireConnection;201;0;232;0
WireConnection;201;1;202;0
WireConnection;238;0;240;0
WireConnection;238;1;208;0
WireConnection;473;0;201;0
WireConnection;473;1;471;0
WireConnection;357;0;586;0
WireConnection;586;0;217;2
WireConnection;222;0;269;0
WireConnection;502;0;503;0
WireConnection;501;2;502;0
WireConnection;396;0;395;0
WireConnection;396;1;394;0
WireConnection;396;2;443;0
WireConnection;396;3;397;0
WireConnection;394;0;393;0
WireConnection;394;1;393;0
WireConnection;263;0;264;0
WireConnection;216;0;213;0
WireConnection;386;0;384;0
WireConnection;209;0;238;0
WireConnection;109;0;293;0
WireConnection;506;0;507;0
WireConnection;506;1;99;0
WireConnection;506;2;505;0
WireConnection;59;0;506;0
WireConnection;362;0;363;0
WireConnection;362;4;364;0
WireConnection;369;0;362;0
WireConnection;369;1;375;0
WireConnection;143;0;373;0
WireConnection;373;0;369;0
WireConnection;373;1;374;0
WireConnection;373;2;376;0
WireConnection;914;0;372;0
WireConnection;375;0;914;0
WireConnection;375;1;914;0
WireConnection;127;0;66;0
WireConnection;246;0;64;0
WireConnection;246;1;245;0
WireConnection;333;0;246;0
WireConnection;592;0;70;0
WireConnection;592;1;69;0
WireConnection;592;2;474;0
WireConnection;389;0;334;0
WireConnection;389;1;390;0
WireConnection;474;0;389;0
WireConnection;554;0;592;0
WireConnection;67;0;127;0
WireConnection;67;1;554;0
WireConnection;335;0;67;0
WireConnection;594;0;595;0
WireConnection;594;1;596;0
WireConnection;594;2;593;0
WireConnection;242;0;236;0
WireConnection;242;1;383;0
WireConnection;915;0;53;0
WireConnection;384;0;263;0
WireConnection;384;1;385;0
WireConnection;540;0;539;0
WireConnection;540;1;391;0
WireConnection;537;0;391;0
WireConnection;537;1;540;0
WireConnection;537;2;538;0
WireConnection;876;9;874;0
WireConnection;871;0;537;0
WireConnection;871;1;872;0
WireConnection;871;2;876;0
WireConnection;438;0;871;0
WireConnection;391;0;241;0
WireConnection;241;0;210;0
WireConnection;241;1;242;0
WireConnection;241;2;905;0
WireConnection;919;0;918;0
WireConnection;919;1;212;0
WireConnection;220;0;919;0
WireConnection;218;0;223;0
WireConnection;269;0;268;0
WireConnection;269;1;387;0
WireConnection;210;0;594;0
WireConnection;210;1;336;0
WireConnection;210;2;338;0
WireConnection;208;0;473;0
WireConnection;1;2;79;0
WireConnection;1;3;78;0
WireConnection;1;4;53;0
WireConnection;1;7;915;0
WireConnection;1;5;18;0
WireConnection;1;6;909;0
ASEEND*/
//CHKSM=EB64B1F856574371B9DBEF5754EA004A3405FE97