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
이번 단계에서는 상위 코드/설정 파일을 복사하지 않고 참조만 기록했다. 다음 단계에서 복제·수정 시 원본 commit, LICENSE, 관련 NOTICE 및 변경 고지를 보존한다. 자체 독립 작성 부분의 라이선스는 소유자 승인으로 MIT를 적용했다. 외부 소프트웨어는 THIRD_PARTY_NOTICES.md에 구분한다.

## 2단계 조사·채택 근거 (2026-11-12)
- upstream 참조 commit: 12bbeda5009e1d8381be294a88d1cb69dc624290. LICENSE Apache-2.0 확인. 이 단계도 원본 파일을 복제하지 않고 Compose를 독립 작성했다. 원본 attribution/NOTICE를 생략한 복제물이 아니다.
- Docker Registry v2 manifest 조회: mattermost/mattermost-team-edition:11.7.0 → sha256:a9f01466ea96b559688fd67b07e6a1d381530a7888c74b87c4358869e5f1f06b. 실행 플랫폼 linux/amd64만 확인(unknown attestation 제외).
- postgres:17.9-alpine → sha256:c7526c0f6c3f30260a563d7bcf8ad778effac59a44f8ffa86678c35418338609. amd64 포함. PG17은 /var/lib/postgresql/data에 mount한다. PG18의 변경된 경로와 혼용하지 않는다: https://hub.docker.com/_/postgres
- Mattermost 공식 요구사항 조회의 DB 최소값 PostgreSQL 15.0+에 대해 PG17 채택. 조합의 실제 런타임 검증은 별개: https://docs.mattermost.com/deployment-guide/software-hardware-requirements.html
- Docker 공식 RHEL9 설치: https://docs.docker.com/engine/install/rhel/ . dnf + Docker RHEL repo, GPG fingerprint 060A61C51B558A7F742B77AAC52FEB6B621E9F35를 사용한다. Oracle Linux9 자체를 Docker의 공식 지원 배포판으로 확인한 것은 아니다. OL9에서 RHEL9 RPM 호환 적용은 배포 테스트 전제이며 실패 시 Podman 제거/SELinux 해제를 자동 수행하지 않는다.
- OCI ap-chuncheon-1 read-only image list에서 Oracle-Linux-9.8-2026.10.30-0 (E4.Flex 호환)의 size-in-mbs=47719 확인. 50×1024 MiB 이내지만 실제 파일시스템 여유/launch 성공 증거는 아니다. 실제 compartment/image OCID는 기록하지 않았다.
- OCI provider 7.22.0 schema 및 공식 core_images/core_shapes/core_subnet/core_public_ip 문서로 속성 검증: https://registry.terraform.io/providers/oracle/oci/7.22.0/docs
- 초기 조사에서는 Resource Manager 문서 schema를 추출하여 검사했으나 재배포 권한이 불명확한 fixture는 제거했다. 현재 검사는 독립 작성 프로젝트 계약이며 Oracle schema 검증이 아니다. OS/storage는 설명과 그룹 제목에 고정 안내, 조건부 visible.eq 및 dependsOn 사용. 존재하지 않는 readOnly 속성을 쓰지 않는다: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/terraformconfigresourcemanager_topic-schema.htm
