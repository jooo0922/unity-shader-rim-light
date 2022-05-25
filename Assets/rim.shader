Shader "Custom/rim"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {}
        _RimColor("RimColor", Color) = (1, 1, 1, 1)
        _RimPower("RimPower", Range(1, 10)) = 3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // Lambert 라이팅 사용 및 환경광 영향 제거
        #pragma surface surf Lambert // noambient // 순수한 프레넬은 확인했고, 이제 텍스쳐들까지 적용했으니 환경광을 켜줘서 다시 자연스럽게 렌더링해봄.

        sampler2D _MainTex;
        sampler2D _BumpMap; // 인터페이스에서 가져온 노말맵 텍스쳐를 담아둘 변수
        float4 _RimColor; // 내적결과값을 n제곱한 조명값(흑백이므로 컴포넌트 값 모두 동일)에 곱해줘서 프레넬에 색을 넣어주기 위해 받아오는 색상값
        float _RimPower; // 내적결과값을 몇 제곱해서 가장자리 영역을 얼만큼 좁힐건지 결정하기 위해 받아오는 지수값.

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap; // 텍스쳐 하나를 추가할 때마다 Input 구조체에서 해당 텍스쳐에 사용할 버텍스 uv좌표값을 새로 받아와야 함.
            float3 viewDir; // 버텍스 -> 카메라 방향의 벡터. '뷰 벡터' 라고도 함.
        };

        void surf (Input IN, inout SurfaceOutput o) // Lambert 라이팅을 사용할 때에는 항상 구조체 이름을 'SufaceOutput' 으로 받아와야 함.
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            // o.Albedo = 0; // 프레넬(가장자리 영역의 반사광)을 잘 보이게 하려고 Albedo 에 검은색 (float3(0, 0, 0)과 같음) 을 넣은 것.
            o.Albedo = c.rgb; // Albedo 를 다시 활성화해서, 색상맵 텍스쳐의 텍셀값을 할당함.

            // UnpackNormal() 함수는 변환된 노말맵 텍스쳐 형식인 DXTnm 에서 샘플링해온 텍셀값 float4를 인자로 받아 float3 를 리턴해줌.
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)); // 노말맵 텍스쳐의 텍셀값을 구조체의 o.Normal 에 집어넣음. 
            // 이제 밑에서 이 노말값을 가지고 프레넬에 필요한 내적연산을 해줄거임!

            // 참고로, o.Normal 에 아무값도 안 넣어줬더라도, 해당 모델의 버텍스에서 받아온 기본 노말값이 그대로 담겨있는 걸 가져온거임.
            // float rim = dot(o.Normal, IN.viewDir); // 노말벡터와 뷰벡터를 내적계산하여 조명값을 구함. (아직은 카메라를 바라보는 면이 가장 밝은 상태)
            /*
                내적은 항상 -1 ~ 1 사이의 값을 모두 포함해서, 
                내적 결과값이 음수값이 되는 부분이 많아지게 되서 
                어두운 부분이 너무 세지는 경향이 있음.

                내적결과값만 가지고 o.Emission 에 할당할거면
                큰 문제가 안되는데,

                o.Albedo 를 활성화하게 되면
                o.Emission 이랑 o.Albedo 색상값을 더하게 되는데,
                o.Emission 이 음수값 이다보니 
                아무리 더해줘도 o.Albedo 에 할당된 텍셀 색상값이 안나오고,
                그냥 똑같이 어두운 값이 찍히는 문제가 발생함.

                이외에도 여러 조명값을 추가할 시 제대로
                적용이 안되는 문제가 있기 때문에

                saturate(), max() 등의 내장함수로
                음수값을 전부 0으로 초기화해주는 게 좋음.
            */
            float rim = saturate(dot(o.Normal, IN.viewDir)); 

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
            // o.Emission = pow(1 - rim, 3);
            o.Emission = pow(1 - rim, _RimPower) * _RimColor; // 프레넬의 두께와 색상을 조절하기 위해 인터페이스에서 받아온 값을 사용함.

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