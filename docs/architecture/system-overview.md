# 구조 안내

## 배포 흐름
Resource Manager가 루트 Terraform과 schema.yaml을 읽는다. region/compartment/AD와 x86_64 Flex shape를 선택하고, 호환 Oracle Linux 9 최신 AVAILABLE 이미지를 조회한다. 이미지 최소 부트 크기 50 GiB 초과와 shape 메모리/OCPU 범위 위반은 precondition에서 거부한다. 이미지 이름은 output으로 남긴다. OS 이미지는 시간에 따라 바뀌므로 변경 Plan을 반드시 검토한다.

신규 네트워크는 10.42.0.0/16 VCN, 10.42.1.0/24 regional subnet, IGW, 전용 route table, 빈 security list, 전용 NSG다. NSG는 제한된 IPv4 SSH ingress와 outbound를 허용한다. 기존 네트워크는 subnet 조회와 전용 NSG 추가만 수행한다. 기존 list/route는 수정하지 않으며 합산 허용 규칙은 사용자가 점검한다. ephemeral, 새 reserved, 기존 네트워크의 no-public-IP를 지원한다. 기존 reserved IP는 가져오거나 변경하지 않는다.

## 게스트와 데이터
cloud-init은 비밀 없는 bootstrap 및 Compose 파일을 기록한다. bootstrap은 Oracle Linux 9 x86_64, 12 GiB 여유를 확인하고 Docker RHEL9 RPM repo/GPG fingerprint를 사용한다. 기존 Docker daemon JSON은 읽고 SELinux 옵션만 병합한다. SELinux를 끄지 않으며 bind mount는 :Z로 분리한다. Docker 그룹에 일반 사용자를 추가하지 않는다.

DB secret은 게스트에서 생성하여 /opt/mattermost/db-password 및 두 env 파일에 root-only로 보관한다. Terraform/state/user-data/출력/명령 인자로 전달하지 않는다. Docker root 권한과 inspect는 비밀을 볼 수 있으므로 접근을 제한한다. DB가 있는데 secret이 사라졌거나 손상됐으면 자동 재생성하지 않고 실패한다. PG 기본 초기 사용자는 superuser이므로 최소권한 DB 계정 분리는 후속 보안 작업이다.

고정 digest의 postgres:17.9-alpine은 /srv/mattermost/postgres → /var/lib/postgresql/data, Team Edition 11.7.0은 config/files/logs/plugins/client-plugins/bleve-indexes를 /srv/mattermost 아래에서 bind mount한다. 추가 volume resource는 없다. 50 GiB는 OCI API의 GiB 단위이며 OS/이미지/DB/첨부파일을 공유한다.

PostgreSQL healthcheck 후 Mattermost를 시작한다. systemd mattermost.service가 Compose --wait로 준비를 기다리고 실패 재시도하며 Docker/컨테이너 restart 정책으로 재부팅 지속성을 구성한다. VM에서의 실증 여부는 상태 문서를 따른다. json-file 로그는 서비스별 10 MiB × 3개, 앱 파일 로그는 비활성화한다. 최초 설치 공간 검사는 지속 모니터링이 아니며 첨부파일 증가를 제한하지 않는다.

## 접속·수명
Mattermost는 호스트 127.0.0.1:8065에만 바인딩한다. PostgreSQL은 호스트 포트가 없다. SSH -L 터널로 최초 관리자 등록과 사용을 수행한다. SiteURL은 http://localhost:8065다. 모든 참여자는 자기 터널이 필요하다. HTTPS, Caddy, 공개 웹, TXT/첨부파일 아카이브는 이 실행 경로에 포함하지 않는다.

Destroy는 VM/부트 데이터와 새 reserved IP를 제거할 수 있다. 기존 VCN/subnet/IP는 소유하지 않아 삭제하지 않는다. state 제거는 백업이 아니다. 사용자 다운로드와 DB의 일관된 외부 백업을 먼저 확인한다.

## 관련 문서
- [배포 설계](../decisions/ADR-002-deployment-and-archive.md)
- [최소 SSH 배포 결정](../decisions/ADR-003-minimum-ssh-deployment.md)
- [공식 소스와 검증](../research/upstream-compose.md)
- [상태 및 미검증 항목](../project-state.md)
