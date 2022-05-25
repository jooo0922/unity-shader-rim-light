Shader "Custom/rim"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert noambient // Lambert 라이팅 사용 및 환경광 영향 제거

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir; // 버텍스 -> 카메라 방향의 벡터. '뷰 벡터' 라고도 함.
        };

        void surf (Input IN, inout SurfaceOutput o) // Lambert 라이팅을 사용할 때에는 항상 구조체 이름을 'SufaceOutput' 으로 받아와야 함.
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = 0; // 프레넬(가장자리 영역의 반사광)을 잘 보이게 하려고 Albedo 에 검은색 (float3(0, 0, 0)과 같음) 을 넣은 것.
            
            // 참고로, o.Normal 에 아무값도 안 넣어줬더라도, 해당 모델의 버텍스에서 받아온 기본 노말값이 그대로 담겨있는 걸 가져온거임.
            float rim = dot(o.Normal, IN.viewDir); // 노말벡터와 뷰벡터를 내적계산하여 조명값을 구함. (아직은 카메라를 바라보는 면이 가장 밝은 상태)
            // o.Emission = 1 - rim; // 내적결과값을 뒤집어줘서 카메라를 바라보는 면이 가장 어둡고, 가장자리로 갈수록 밝아지도록 함. -> 프레넬!
            
            /*
                 위에 공식대로 그대로 o.Emission 에 넣어버리면,
                 프레넬에 너무 넓게 보임. 
                 즉 가장자리 흰테두리 영역이 너무 넓음. 

                 이거는 왜 그러냐면, p.330 첫번째 그래프처럼,
                 내적결과값이랑 실제 밝기값이 선형 관계, 즉 정비례하기 때문임.

                 이거를 p.330 두 번째 그래프처럼 
                 특정 구간부터 실제 밝기값이 확 올라가도록 해주면 
                 가장자리의 흰 테두리 영역이 그만큼 좁아질거임.

                 이를 구현하려면
                 내적결과값을 pow() 함수로 n제곱 해주면 됨.
            */
            o.Emission = pow(1 - rim, 3);

            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}

/*
    뷰 벡터란?

    뷰 벡터는 
    버텍스가 카메라를 바라보는 방향, 즉
    버텍스 -> 카메라 방향의 벡터를 의미함.

    위에서 보듯 Input 구조체에서 가져올 수 있는 걸 보면,
    유니티 엔진에서 제공하는 데이터라는 걸 알 수 있음.

    램버트 라이팅에서는 
    조명벡터와 노말벡터를 내적연산해서 조명값을 계산했지만.
    
    림 라이트 구현 시,
    조명벡터의 역할을 뷰 벡터가 대신함.

    그래서 뷰 벡터와 노말벡터를 내적연산하여
    조명값을 구함. 

    그런데, 이렇게 하면 카메라가 바라보는 방향,
    즉, 가운데로 올수록 밝기값이 더 밝아지는데,
    이거는 프레넬과 반대잖아? 
    
    그냥 카메라 자체가 조명이 되어버리는 셈!
    우리가 지금 원하는 건 이런 라이팅이 아님!

    그래서 실제 o.Emission 에 내적계산한 조명값을 넣어줄 때에는
    1 - rim 해서 결과값을 반대로 뒤집는거임.

    이렇게 하면 가운데로 올수록 밝기값이 어두워지고,
    가장자리로 갈수록 밝기값이 밝아지는 Fresnel 을 구현할 수 있게 됨.
*/