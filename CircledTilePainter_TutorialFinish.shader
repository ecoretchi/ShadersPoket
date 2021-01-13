Shader "Unlit/CircledTilePainter"
{
	Properties
	{
		_GridSize("Grid Size", Vector) = (30,30,0,0)
		_Radius("Radius", float) = 1

		_CenterTilePosX("Center Tile PosX", float) = -1
        _CenterTilePosY("Center Tile PosY", float) = -1

		_TileTex("Tile Texture", 2D) = "white" {}
        _TileColor("Tile Color", Color) = (1,1,1,1)

        _CenterTileColor("Tile Color", Color) = (1,1,1,1)

        _MoveRestrictionTex("Move Restriction", 2D) = "white" {}
	}

	SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline"}
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionHCS  : SV_POSITION;
                float3 normal : NORMAL;
            };

            uniform float2 _GridSize;
			uniform float _Radius;
           
            uniform float _CenterTilePosX;
            uniform float _CenterTilePosY;
		
            TEXTURE2D(_TileTex);
            SAMPLER(sampler_TileTex);

            TEXTURE2D(_MoveRestrictionTex);
            SAMPLER(sampler_MoveRestrictionTex);
            
            CBUFFER_START(UnityPerMaterial)
            float4 _TileTex_ST;
            float4 _MoveRestrictionTex_ST;
            half4 _TileColor;
            half4 _CenterTileColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv* _GridSize, _TileTex) ;               
                OUT.normal = IN.normal;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 col = half4(0,0,0,0);

                if( _Radius < 1 || _CenterTilePosX < 0 || _CenterTilePosY < 0)
                    return col;

                float2 centerTile = float2( _CenterTilePosX , _CenterTilePosY);

                float2 dir = ceil(IN.uv) - ceil(centerTile + 1);
 
                float r1 = dot(dir,dir); // d.x * dir.x + dir.y * dir.y; // R^2 

                float r2 =  _Radius + 0.3f ; // add correlation offset

                if ( r1 <= r2 * r2 )
                {
                    half4 tileColor =  (r1 == 0 ) ? _CenterTileColor : _TileColor ;
	                col = SAMPLE_TEXTURE2D(_TileTex, sampler_TileTex, IN.uv) * tileColor;
                   

                    float2 uv = ceil( IN.uv )  / ( _GridSize + 1);
                    half4 colMask = SAMPLE_TEXTURE2D(_MoveRestrictionTex, sampler_MoveRestrictionTex, uv);
                    if(colMask.a>0.9)
                    {
                        float fiY  = dot(IN.normal, float3(0, 1, 0));
			            float threshold = smoothstep(0.75, 0.99, abs(fiY));

	                    col.a = 0;
                    }

                    float fiY  = dot(IN.normal, float3(0, 1, 0));
			        float threshold = smoothstep(0.75, 0.99, abs(fiY));

	                col.a = lerp(col.a, 0, 1 - threshold);
                }

                return col;
            }
            ENDHLSL
        }

        Pass
        {
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionHCS  : SV_POSITION;
            };

            uniform float2 _GridSize;

            TEXTURE2D(_MoveRestrictionTex);
            SAMPLER(sampler_MoveRestrictionTex);
            

            CBUFFER_START(UnityPerMaterial)
            float4 _TileTex_ST;
            float4 _MoveRestrictionTex_ST;
            half4 _TileColor;
            half4 _CenterTileColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MoveRestrictionTex) ;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = ceil( IN.uv * _GridSize)  / (_GridSize + 1);
                half4 col = SAMPLE_TEXTURE2D(_MoveRestrictionTex, sampler_MoveRestrictionTex, uv);
                if(col.a>0.9)
                    return half4(1,0,0,0.6);
                return half4(0,0,1,0.2); 
            }
            ENDHLSL
        }
    }

}
