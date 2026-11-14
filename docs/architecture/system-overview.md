# 구조 안내

## 배포 흐름
Resource Manager가 루트 Terraform과 schema.yaml을 읽는다. region/compartment/AD와 x86_64 Flex shape를 선택하고, 호환 Oracle Linux 9 최신 AVAILABLE 이미지를 조회한다. 이미지 최소 부트 크기 50 GiB 초과와 shape 메모리/OCPU 범위 위반은 precondition에서 거부한다. 이미지 이름은 output으로 남긴다. OS 이미지는 시간에 따라 바뀌므로 변경 Plan을 반드시 검토한다.

신규 네트워크는 10.42.0.0/16 VCN, 10.42.1.0/24 regional subnet, IGW, 전용 route table, 빈 security list, 전용 NSG다. NSG는 입력한 IPv4 CIDR(/0–/32)의 TCP 22 SSH ingress와 outbound를 허용한다. SSH CIDR은 기본값 없이 필수 입력이며 관리자 IP /32를 권장한다. 명시적 `0.0.0.0/0`은 모든 IPv4에 TCP 22를 허용하지만 키 인증은 여전히 필요하다. 설치 후 자동 폐쇄하지 않으며 스택 변수 `ssh_ingress_cidr`를 좁히고 Plan 검토 후 Apply해야 한다. 기존 네트워크는 VCN/subnet 조회와 전용 NSG 추가만 수행한다. 기존 list/route는 수정하지 않으며 합산 허용 규칙은 사용자가 점검한다. ephemeral, 새 reserved, 기존 네트워크의 no-public-IP를 지원한다. 기존 reserved IP는 가져오거나 변경하지 않는다.

## 폼과 리전 선택 방어
SSH는 `oci:core:ssh:publickey`와 `additionalProps.allowMultiple: false`로 공개키 한 개를 받는다. Terraform 변수는 string이며 OpenSSH 형식 검증 후 trimspace하여 metadata로 전달한다. 개인키 생성 resource/state/output은 없다. region 기본값은 `${session.region}`, provider는 `var.region`을 사용한다.

AD 목록 data source postcondition은 선택 AD가 provider 리전에 존재하는지 검사한다. 기존 VCN/subnet은 같은 provider endpoint에서 읽어야 하며 compartment와 subnet의 VCN·AD 일치를 검증한다. regional subnet의 빈/null AD는 허용한다. shape 조회와 NSG는 검증 data source에 의존한다. 다른 리전 OCID는 endpoint 조회에서 실패할 수 있으나 오류 형태는 OCI 권한/API에 따라 다르다. UI 자동 refresh를 보장하거나 OCID 문자열에서 리전을 추측하지 않는다.

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
- [SSH IPv4 전체 범위 선택 결정](../decisions/ADR-005-ssh-ipv4-cidr-choice.md)
- [RM 입력 안전성 결정](../decisions/ADR-004-resource-manager-input-safety.md)
- [RM 입력 컨트롤 근거와 Console 확인 절차](../research/resource-manager-controls.md)
- [공식 소스와 검증](../research/upstream-compose.md)
- [상태 및 미검증 항목](../project-state.md)

## 이름 호환성
신규 배포의 instance_name 기본값은 `mattermost`다. 이 값은 리소스 표시 이름에 사용되며 기존 스택 갱신 시 원래 값을 명시적으로 보존한다. 신규 네트워크의 기존 DNS 라벨 상수는 변경하지 않는다. 문구 정리만으로 VCN/subnet 교체를 유발하지 않도록 DNS 이름 변경은 별도 마이그레이션으로 취급한다.

- [Team Edition 라이선스 조사](../research/team-edition-license.md) — 공식 바이너리/소스/Enterprise 구분과 검증 경계.
