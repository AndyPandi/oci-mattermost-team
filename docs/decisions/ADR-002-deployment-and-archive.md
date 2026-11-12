# ADR-002: Compose와 부트 볼륨 기반 협업 환경

- 날짜: 2026-11-12
- 상태: Accepted (설계 결정이며 구현 완료가 아님)

## 배경
PoC마다 관계자들의 대화·자료 공유 수단을 쉽게 배포하고, 종료 후 서버 없이 읽을 수 있는 기록을 남기려는 요구다. Mattermost 자체의 평가 또는 서버 간 마이그레이션이 목적은 아니다.

## 결정
- OCI Resource Manager Terraform 및 schema.yaml로 클릭 중심 배포 UI를 제공한다.
- Oracle Linux 9 계열 VM에서 Docker Engine/Compose와 공식 Team Edition 이미지를 사용한다.
- PostgreSQL과 첨부파일은 추가 디스크가 아닌 **기본 50GB 부트 볼륨의 호스트 디렉터리**에 보관한다. 컨테이너 경로에 bind mount한다.
- 설계 경로 예시: /srv/mattermost/files, postgres, config, plugins, client-plugins, caddy. PostgreSQL 내부 경로는 채택 메이저 버전에 맞춰 결정한다.
- SSH 터널은 localhost 웹 바인딩과 관리자 SSH 허용 CIDR로 보호한다.
- HTTPS는 Caddy reverse proxy와 Let’s Encrypt 자동 갱신. 인증서 데이터를 영속화하고 검증 트래픽과 앱 접근 정책을 분리한다.
- 새 VCN 생성과 기존 subnet 사용을 지원하되 기존 공유 자원을 임의 수정하지 않는다.
- 아카이빙은 대상 채널 TXT 및 첨부파일 묶음. 작성 시각/시간대, 작성자, 메시지 ID, 스레드 및 파일 상대 경로를 보존한다. 이름 충돌·누락·대용량·반출 권한을 검증한다.
- 개발 저장소는 비공개, 검증 및 비밀정보 검사 후 공개 전환한다.

## 대안과 결과
- VM 직접 설치 대신 공식 Compose 기반 재현성을 선택했다. OCI와 Caddy 통합까지 공식 제공된다는 뜻은 아니다.
- 추가 Block Volume은 사용자 요구에 따라 제외. 부트 디스크 손실은 데이터 손실이므로 외부 아카이브/백업이 필요하다.
- PostgreSQL/첨부파일의 복구용 백업과 사람이 읽는 TXT 아카이브는 별개다. DB 디렉터리를 실행 중 단순 복사하지 않는다.
- LB/HA/관리형 DB, AI/MCP, HTML/PDF 아카이브는 초기 배포·TXT 요구에 포함하지 않는다.
- 종료 시 다운로드·열람 확인 전에는 원본을 삭제하지 않는다. 웹 최초 관리자 등록을 전체 인터넷에 노출하지 않는다.
