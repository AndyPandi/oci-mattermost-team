# OCI Mattermost Team

OCI PoC 관계자들의 대화와 자료 공유를 위한 Mattermost 협업 환경을 클릭 몇 번으로 배포하는 프로젝트입니다. **Mattermost 자체를 평가하는 PoC가 아니라, 다른 PoC의 실제 협업을 돕는 도구**를 목표로 합니다.

이 저장소는 Oracle 또는 Mattermost의 공식 Marketplace 상품이 아닙니다.

## 문서 안내
- [구현 상태·다음 단계·검증 체크리스트](docs/project-state.md) — 배포 가능 여부는 이 문서를 확인하세요.
- [구조 안내](docs/architecture/system-overview.md)
- [채택한 배포 설계](docs/decisions/ADR-002-deployment-and-archive.md)
- [공식 Compose 재사용 검토](docs/research/upstream-compose.md)
- [문서 관리 규칙](docs/README.md)

## 사용 경험 목표
1. GitHub의 Deploy to Oracle Cloud 버튼에서 OCI Resource Manager로 이동.
2. OCI 로그인 후 Compartment·인스턴스·네트워크·접속 모드 설정.
3. Apply 및 VM 내부 초기 설치 완료 확인.
4. 보호된 접속 경로에서 관리자 등록 후 관계자들과 협업.
5. PoC 종료 시 **채널별 TXT와 첨부파일**을 외부 저장소로 내려받아 보관.

## 개발용 Resource Manager 사용 흐름
구현/미검증 범위는 [현재 상태](docs/project-state.md)를 먼저 확인하세요. 아래는 운영자 절차이며 자동 Apply 승인이 아닙니다.

1. 저장소 권한이 있는 사용자가 소스를 ZIP으로 내려받아 Resource Manager → Create stack → My configuration에 업로드합니다. 루트에 *.tf와 schema.yaml, compose.yaml, cloud-init/이 함께 있어야 합니다. .terraform, state, 실제 tfvars/키를 포함하지 마세요. 비공개 저장소에 익명 Deploy 버튼은 제공하지 않습니다.
2. Terraform 1.5 이상 런타임을 선택하고 이름, compartment/AD, x86_64 shape, OCPU/RAM을 입력합니다. Oracle Linux9와 50 GiB boot는 안내만 표시되며 변경 입력은 없습니다. 기본 1 OCPU/8 GiB는 잠정값입니다.
3. SSH 공개키와 신뢰 CIDR(/24–/32, 권장 /32)을 입력합니다. 0.0.0.0/0는 거부됩니다. 신규 VCN 또는 같은 compartment의 기존 VCN/subnet을 선택합니다.
4. ephemeral / reserved_new / none과 private IP auto/manual을 선택합니다. 기존 reserved IP는 지원하지 않습니다. none은 기존 VPN/bastion/SSH 경로와 DNS·NAT 등 인터넷 egress를 먼저 준비해야 합니다. 신규 private-only는 거부됩니다. 기존 보안 목록은 NSG와 합산되므로 별도 검토하세요.
5. Plan에서 자원·비용·이미지 이름·기존 네트워크 불변을 확인합니다. **별도 배포 승인 후** Apply합니다. Apply 성공은 앱 준비 완료가 아닙니다.
6. SSH 접속 후 다음으로 상태를 확인합니다. 비밀이 포함되는 docker inspect / compose config / env 파일은 공유하지 마세요.

```sh
sudo cloud-init status --wait
sudo systemctl status mattermost.service --no-pager
sudo docker compose -f /opt/mattermost/compose.yaml ps
sudo df -h / /srv/mattermost
```

로컬 PC에서 ssh -N -L 8065:127.0.0.1:8065 opc@<ssh_host> 실행 후 http://localhost:8065 에서 최초 관리자 계정을 만듭니다. private-only는 먼저 VPN 또는 승인된 jump host를 연결하세요. 참여자별 SSH 터널이 필요하며 인터넷 공개 웹 주소가 아닙니다. bootstrap 실패 원인을 고친 뒤 sudo /usr/local/sbin/mattermost-bootstrap 으로 재시도할 수 있습니다. 기존 DB 암호는 유지합니다.

## 로컬 정적 검사
Terraform 1.7 이상(mock test; 검증 기준 1.9.8), Python3+PyYAML을 사용합니다.

```sh
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
python3 tests/static_checks.py
```

검사는 OCI Apply를 실행하지 않습니다. 테스트는 mock provider만 사용합니다. Docker RHEL9 repo의 Oracle Linux 적용, 실제 Console 폼, 재부팅/복원은 별도 실증 관문입니다.

## 데이터와 보안
아카이브는 서비스 이전용 DB 백업과 다릅니다. 대화와 첨부파일을 서버 없이 읽을 수 있도록 연결 정보를 보존하는 것이 목표입니다. DM·비공개 채널의 반출 범위는 별도 승인해야 합니다.

OCI 자원 비용은 배포자 부담입니다. VM/부트 볼륨 삭제 전에 외부 다운로드와 열람을 확인해야 합니다. 개인키·실제 환경값·Terraform state·백업 파일은 Git에 올리지 않습니다.

## 라이선스
프로젝트 자체 배포 라이선스는 공개 전 확정합니다. Mattermost 이미지, PostgreSQL, Caddy 및 재사용 소스의 라이선스는 각각 별개입니다. 상위 프로젝트의 라이선스가 본 저장소 전체에 자동 적용되는 것은 아닙니다.
