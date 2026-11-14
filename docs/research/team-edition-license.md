# Mattermost Team Edition 라이선스 근거

확인일: 2026-11-14. 공개 공식 문서와 v11.7.0 태그의 배포물 라이선스 원문을 읽은 조사다. 법률 자문이 아니다. 최신 제품 문서와 고정 버전 소스는 시간 범위가 다르다.

## 대상과 검증 경계

- compose.yaml의 대상: mattermost/mattermost-team-edition:11.7.0@sha256:a9f01466ea96b559688fd67b07e6a1d381530a7888c74b87c4358869e5f1f06b. PostgreSQL 17.9-alpine과 함께 기존 digest를 그대로 유지한다.
- 아래는 해당 버전의 공식 컴파일 라이선스 **소스 파일** 확인이다. 이번 조사에서 컨테이너 레이어/배포 tarball 안의 파일을 추출하거나 VM에서 바이너리 edition을 실행 확인하지 않았다. 설치된 이미지·edition·라이선스의 런타임 확인은 별도다.
- API, 플러그인, AI/MCP, 사용자 상한을 실행 검증하지 않았다. 기능 비교 문서는 특정 플러그인 버전의 entitlement나 작동 증거를 대신하지 않는다.

## 공식 Team 컴파일 배포물: MIT

[에디션 문서](https://docs.mattermost.com/product-overview/editions-and-offerings)는 Team을 다음과 같이 설명한다:

> It is deployed as a single Linux binary with PostgreSQL and is licensed under MIT.

[라이선스 정책](https://docs.mattermost.com/product-overview/faq-license)의 Team 행:

> Mattermost Team Edition (Open Source)
> Open Source MIT License.

[v11.7.0 MIT-COMPILED-LICENSE.md](https://github.com/mattermost/mattermost/blob/v11.7.0/server/build/MIT-COMPILED-LICENSE.md) ([직접 원문](https://raw.githubusercontent.com/mattermost/mattermost/v11.7.0/server/build/MIT-COMPILED-LICENSE.md), HTTP 200 확인):

> Note: this license does not cover source code, for information on source code licensing see LICENSE.txt in the Mattermost source code.

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software

> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software;

따라서 이 MIT 대상 배포물은 상용·사내 운영에 쓸 수 있고 수정·재배포·판매도 가능하되 고지를 유지해야 한다. 평가용으로만 제한하는 조항이나 인원 수 조항은 없다. 무보증(AS IS), 제3자 구성요소의 별도 라이선스와 [상표 정책](https://mattermost.com/trademark-standards-of-use/)을 별도로 검토한다. 이름·로고 사용권이나 공식 지원을 자동 부여하는 설명이 아니다.

## 서버 소스·자체 빌드는 별도

[v11.7.0 LICENSE.txt](https://github.com/mattermost/mattermost/blob/v11.7.0/LICENSE.txt) ([직접 원문](https://raw.githubusercontent.com/mattermost/mattermost/v11.7.0/LICENSE.txt), HTTP 200 확인):

> You are licensed to use compiled versions of the Mattermost platform produced by Mattermost, Inc. under an MIT LICENSE

> You may be licensed to use source code to create compiled versions not produced by Mattermost, Inc. in one of two ways:
> 1. Under the Free Software Foundation’s GNU AGPL v3.0, subject to the exceptions outlined in this policy; or
> 2. Under a commercial license available from Mattermost, Inc. by contacting commercial@mattermost.com

> You are licensed to use the source code in Admin Tools and Configuration Files (server/templates/, server/i18n/, server/public/, webapp/ and all subdirectories thereof) under the Apache License v2.0.

AGPL 서버 소스를 수정·배포하거나 수정 서버를 네트워크로 제공할 때는 해당 소스 제공 등 조건을 검토해야 한다. 소스 정책의 예외, Apache 대상 및 별도 라이선스 파일도 확인해야 하므로 전체 저장소를 일괄 MIT 또는 일괄 AGPL로 표현하지 않는다. Enterprise의 별도 상용 계약을 이 일반 문구로 덮어쓰지도 않는다.

## Team, Enterprise Entry, 평가판의 차이

[에디션 문서](https://docs.mattermost.com/product-overview/editions-and-offerings):

> Once you’ve installed Mattermost Enterprise Edition in your preferred environment, you can run it as-is in a free mode, known as Entry, or activate a trial or subscription to unlock additional features.

Team과 Entry는 같은 배포물이 아니다. Team에서 Enterprise 기능으로 전환하는 것은 단순히 현재 Team 이미지에 키만 넣는다는 의미가 아니다. Enterprise 패키지/이미지 및 계약 검토가 필요하다. Enterprise에서 Entry·평가판·구독은 해당 배포물의 서로 다른 모드다.

[Enterprise Edition License](https://mattermost.com/enterprise-edition-license/) (HTTP 200 확인)의 Free Version 조건:

> The Free Version is licensed solely for evaluation, testing, and non-production purposes. You may not use the Free Version in any production environment or mission-critical system.

> This license is limited to a maximum of one hundred (100) end users and does not include support of any kind.

> You will not distribute and/or sell the Free Version without prior written agreement from Mattermost.

제품 페이지는 Entry를 작은 팀의 업무 흐름 시작에 소개하고 라이선스 FAQ는 구독 기능이 비활성일 때 영구 무료 사용 가능하다고 설명한다. 그러나 무료라는 설명은 위 용도 제한을 없애지 않는다. 운영 사용을 계획하면 적용 계약/별도 합의와 공급자 확인이 필요하다. Team MIT에는 이 Enterprise Free Version 제한을 전이하지 않는다. 평가판의 기능 잠금 해제 역시 영구 운영 허가의 증거가 아니다.

## 사용자 수와 기능 비교 해석

에디션 문서의 Team 설명:

> Team Edition is intended for small teams, hobbyists, or personal use under 250 activated users where single sign-on (SSO) is not required. It is not recommended for government or sensitive commercial workloads.

이 권장 대상과 MIT 권한을 구분한다. 250명 미만이라는 제품 설명을 MIT의 법적 인원 상한으로 만들지 않으며, 반대로 실제 11.7.0의 기술적 한도가 없다고 단정하지 않는다. VM 1 OCPU/8 GiB 성능·운영 적합성도 이 문구로 보증하지 않는다.

Entry의 “less than 50 users”는 적합 규모 설명이고, Enterprise Free Version 계약의 최대 100명은 계약 조건이다. Entry의 10,000 메시지 표시/검색 이력 제한과 별표의 “Limits will take effect in a future release”도 Team이나 11.7.0에 일괄 적용하지 않는다. 이력 비표시와 DB 삭제도 다르다.

검증된 공개 비교 링크(HTTP 200):
- [에디션 및 제공 형태](https://docs.mattermost.com/product-overview/editions-and-offerings): Team/Entry/상용 구분.
- [가격·유료 기능 비교](https://mattermost.com/pricing/): 유료 tier 비교이며 모든 Team 기능을 열거하는 표는 아니다.
- [공식 라이선스 정책](https://docs.mattermost.com/product-overview/faq-license): 소프트웨어·서비스·상표 정책 안내.

SSO·컴플라이언스·HA·AI/API/플러그인은 기능별 문서, 출시 버전, 실제 edition/라이선스 조건을 각각 확인한다. 이 조사만으로 “모든 API 무료”, “모든 플러그인 유료”, “기능이 켜지면 운영 허가됨” 같은 결론을 내리지 않는다. 모델/API 사용료와 OCI 비용은 소프트웨어 라이선스와 별도다.

## 이 배포 저장소

Mattermost의 MIT는 이 Terraform/Compose 저장소 자체의 라이선스를 결정하지 않는다. 별도 Mattermost Archiver의 MIT 선택도 이 저장소로 전이되지 않는다. 현재 결정은 상태 문서에서 확인한다.
