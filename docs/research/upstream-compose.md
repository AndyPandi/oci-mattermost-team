# 공식 Compose 재사용 검토

조사일: 2026-11-12. 아래 main 링크는 변경될 수 있어 실제 복제 시 commit SHA를 고정해야 한다.

## 기존 솔루션
- https://github.com/mattermost/docker : 공식 Docker 배포 솔루션. 구 mattermost-docker 저장소는 deprecated라고 README가 안내한다.
- https://github.com/mattermost/docker/blob/main/docker-compose.yml
- https://github.com/mattermost/docker/blob/main/env.example
- https://github.com/mattermost/docker/blob/main/LICENSE : Compose 저장소 Apache-2.0. 이미지/애플리케이션의 라이선스와 구분.

## 확인 결과와 재사용 계획
- 기본 Compose는 postgres와 mattermost 서비스, 환경변수, bind mount, restart 정책을 제공한다. 이 패턴을 기반으로 삼고 불필요한 재작성은 줄인다.
- env.example 기본 MATTERMOST_IMAGE는 Enterprise이다. 반드시 mattermost-team-edition을 명시하고 런타임 빌드를 확인해야 한다.
- 조회 시 예제는 PostgreSQL 18-alpine 및 Mattermost 11.7.0을 표시했다. 검증된 프로젝트 버전 조합으로 간주하지 않는다.
- 조회 시 PostgreSQL 컨테이너 마운트 대상은 /var/lib/postgresql이다. 예전 버전의 /var/lib/postgresql/data와 무조건 혼용하지 않는다.
- Mattermost config/data/logs/plugins/client/plugins가 분리되어 있다. 호스트 부트 볼륨 경로로 지정하고 UID/GID와 Oracle Linux SELinux를 맞춘다.
- 예제 mem_limit은 PostgreSQL 16G, Mattermost 4G다. 메모리 예약량은 아니지만 소형 VM에서 그대로 사용하지 않고 전체 예산/부하를 검증한다.
- depends_on만으로 DB 준비 완료를 보장하지 않는다. healthcheck/재시도 및 재부팅 시작 순서를 설계한다.
- 기본 프록시 관련 예제는 Nginx다. Caddy 자동 HTTPS/갱신은 프로젝트에서 별도 구성·검증해야 한다.
- 예제 DB 자격증명을 그대로 쓰지 않는다. VM에서 랜덤 생성하고 Git/state/cloud-init 로그/명령 인자에 노출하지 않는다.

## 라이선스 처리
이번 단계에서는 상위 코드/설정 파일을 복사하지 않고 참조만 기록했다. 다음 단계에서 복제·수정 시 원본 commit, LICENSE, 관련 NOTICE 및 변경 고지를 보존한다. 프로젝트 전체 라이선스는 소유자가 공개 전에 결정한다.
