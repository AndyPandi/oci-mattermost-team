# ADR-006: 자체 MIT와 신규 DB 최소권한 분리

- 날짜: 2026-11-14
- 상태: Accepted

## 배경
소유자가 자체 MIT 적용과 보안 보완을 승인했다. Oracle 문서에서 복사한 fixture의 재배포 권한은 불명확했고 기존 PostgreSQL 초기 앱 사용자는 superuser였다.

## 결정
독립 작성 부분에 MIT Copyright (c) 2026 AndyPandi를 적용하고 제3자 구성요소를 별도 고지한다. 복사 fixture는 현재 트리에서 제거하고 독립 작성 명령형 프로젝트 계약으로 교체한다. Git 이력 재작성은 승인 범위가 아니므로 수행하지 않는다.

신규 DB는 별도 mmadmin과 앱 소유 DB의 mmuser를 사용한다. 앱에는 superuser/role 생성/DB 생성/replication/RLS 우회 권한을 부여하지 않는다. read-only 초기화 스크립트는 빈 데이터 디렉터리에만 적용한다. 기존 설치는 자동 migration·secret 회전·강등하지 않으며 별도 백업/검증 유지보수로 다룬다.

## 대안
앱 superuser 유지보다 역할 분리를 선택했다. 기존 설치 자동 강등은 확장/소유권·복구 위험으로 제외했다. 검증되지 않은 전체 capability 제거는 PostgreSQL entrypoint 호환성 위험으로 제외했다.

## 결과
실행 검증 범위와 이력의 외부 fixture 잔존을 공개한다. MIT 및 digest는 외부 라이선스 준수나 보안 무위험을 보장하지 않는다.
