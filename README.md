# OCI Mattermost Team

[한국어](README.md) · [English](README.en.md)

OCI에 Mattermost Team Edition 협업 환경을 배포하는 프로젝트입니다. 팀의 대화와 자료 공유를 위한 반복 가능한 배포 구성을 제공합니다.

이 저장소는 Oracle 또는 Mattermost의 공식 Marketplace 상품이 아닙니다.

## Deploy to Oracle Cloud

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https%3A%2F%2Fgithub.com%2FAndyPandi%2Foci-mattermost-team%2Farchive%2Frefs%2Fheads%2Fmain.zip)

**공개 저장소용 소스 자동 불러오기 버튼입니다.** OCI 로그인 → 대상 리전 확인 → 소스 불러오기 → 변수 입력 → Plan 검토 → Apply 순서로 진행합니다. 버튼 클릭만으로 자원이 생성되지는 않습니다. Apply부터 비용이 발생합니다.

Console 상단 리전을 먼저 선택하세요. 입력 region만 바꾸면 AD·VCN·subnet 목록이 갱신되지 않을 수 있습니다. 링크는 최신 main ZIP을 사용하므로 변경 사항을 검토하세요. 공개 버튼 전체 흐름은 아직 실증 전입니다.

자동 불러오기가 실패하면 Code → Download ZIP으로 소스를 받아 Resource Manager → Create stack → My configuration에서 수동 업로드하세요. 작업 디렉터리는 Terraform 파일과 schema.yaml이 있는 폴더입니다. 저장소가 비공개이면 익명 자동 불러오기는 사용할 수 없습니다. 토큰을 URL에 넣지 마세요.

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
5. 필요할 때 별도 [Mattermost Archiver](https://github.com/AndyPandi/mattermost-archiver)로 대화·첨부파일을 HTML 아카이브로 변환하여 외부 보관. 본 배포에 자동 설치되는 기능은 아닙니다.

## Resource Manager 배포 순서
구현/미검증 범위는 [현재 상태](docs/project-state.md)를 먼저 확인하세요. 아래는 운영자 절차이며 자동 Apply 승인이 아닙니다.

1. 위 Deploy to Oracle Cloud 버튼으로 공개 소스를 불러옵니다. 리전·Compartment와 Terraform 작업 디렉터리를 확인하세요. 수동 ZIP에는 *.tf, schema.yaml, compose.yaml, cloud-init/을 포함하고 .terraform, state, 실제 tfvars/키를 넣지 마세요.
2. Terraform 1.5 이상 런타임을 선택하고 이름, compartment/AD, x86_64 shape, OCPU/RAM을 입력합니다. Oracle Linux9와 50 GiB boot는 안내만 표시되며 변경 입력은 없습니다. 기본 1 OCPU/8 GiB는 잠정값입니다.
3. SSH 공개키 `.pub` 파일 하나를 업로드/드롭하거나 OpenSSH 공개키를 붙여넣고 IPv4 CIDR(/0–/32, 권장 관리자 공인 IP /32)을 입력합니다. 개인키는 로컬에 보관하세요. `0.0.0.0/0`도 입력할 수 있지만 TCP 22를 모든 IPv4에 허용하며 SSH 키 인증은 여전히 필요합니다. 설치 후 자동으로 닫히지 않습니다. 이후 스택 변수 `ssh_ingress_cidr`를 좁은 CIDR(권장 /32)로 변경하고 Plan을 검토한 뒤 Apply하세요. 신규 VCN 또는 같은 compartment의 기존 VCN/subnet을 선택합니다.
4. ephemeral / reserved_new / none과 private IP auto/manual을 선택합니다. 기존 reserved IP는 지원하지 않습니다. none은 기존 VPN/bastion/SSH 경로와 DNS·NAT 등 인터넷 egress를 먼저 준비해야 합니다. 신규 private-only는 거부됩니다. 기존 보안 목록은 NSG와 합산되므로 별도 검토하세요.
5. Plan에서 자원·비용·이미지 이름·기존 네트워크 불변을 확인합니다. **별도 배포 승인 후** Apply합니다. Apply 성공은 앱 준비 완료가 아닙니다.
6. SSH 접속 후 다음으로 상태를 확인합니다. 비밀이 포함되는 docker inspect / compose config / env 파일은 공유하지 마세요.

```sh
sudo cloud-init status --wait
sudo systemctl status mattermost.service --no-pager
sudo docker compose -f /opt/mattermost/compose.yaml ps
sudo df -h / /srv/mattermost
```

로컬 PC에서 ssh -N -L 127.0.0.1:8065:127.0.0.1:8065 opc@<ssh_host> 실행 후 http://localhost:8065 에서 최초 관리자 계정을 만듭니다. private-only는 먼저 VPN 또는 승인된 jump host를 연결하세요. 참여자별 SSH 터널이 필요하며 인터넷 공개 웹 주소가 아닙니다. bootstrap 실패 원인을 고친 뒤 sudo /usr/local/sbin/mattermost-bootstrap 으로 재시도할 수 있습니다. 분리된 DB 암호는 유지합니다. 기존 legacy DB는 자동 전환하지 않으며 SECURITY.md의 명시적 유지보수 절차가 필요합니다.

## 기존 스택 갱신과 리전 변경 주의
- 신규 배포 이름 기본값은 `mattermost`입니다. 기존 스택은 기존 `instance_name` 값을 명시적으로 유지하세요. 이름 변경은 표시 이름 변경을 만들 수 있습니다. 내부 네트워크 DNS 라벨은 호환성을 위해 유지합니다. 이름 정리를 위해 기존 VCN/subnet을 교체하지 마세요.
- Git push나 새 ZIP 다운로드만으로 기존 스택 설정은 바뀌지 않습니다. 기존 스택의 **Edit → Terraform configuration**에서 최신 ZIP을 다시 업로드하거나, 대상 Console 리전에서 별도 새 스택을 만드세요.
- Console 상단 리전과 입력 region을 맞추고 compartment → AD → VCN → subnet 순으로 다시 선택하세요. Chicago에서 Chuncheon으로 입력만 바꿨을 때 목록 자동 갱신은 보장하지 않습니다. 이전 AD/네트워크 값이 남으면 진행하지 마세요.
- 기존 저장 변수로 무심코 Apply하지 마세요. 특히 배포된 스택의 region 변경은 리전 이동 기능이 아닙니다. 새 Plan의 리전·AD·OCID·교체/삭제를 검토하세요.
- RM에서 Compute와 같은 키 생성/개인키 다운로드는 공식 지원 근거가 확인되지 않았습니다. 키가 없다면 로컬 SSH 도구로 만들고 `.pub`만 입력하세요.
- [공식 속성 근거·문서 충돌·Apply 없는 Console 확인 절차](docs/research/resource-manager-controls.md)

## 로컬 정적 검사
Terraform 1.7 이상(mock test; 검증 기준 1.9.8), Python3+PyYAML를 사용합니다.

```sh
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test
python3 tests/static_checks.py
python3 -m unittest discover -s tests -p "test_*.py"
```

검사는 OCI Apply를 실행하지 않습니다. 테스트는 mock provider만 사용합니다. Docker RHEL9 repo의 Oracle Linux 적용, 실제 Console 폼, 재부팅/복원은 별도 실증 관문입니다.

## 데이터와 보안
아카이브는 서비스 이전용 DB 백업과 다릅니다. 대화와 첨부파일을 서버 없이 읽을 수 있도록 연결 정보를 보존하는 것이 목표입니다. DM·비공개 채널의 반출 범위는 별도 승인해야 합니다.

OCI 자원 비용은 배포자 부담입니다. VM/부트 볼륨 삭제 전에 외부 다운로드와 열람을 확인해야 합니다. 개인키·실제 환경값·Terraform state·백업 파일은 Git에 올리지 않습니다.

## Mattermost Team Edition 라이선스

이 배포는 공식 **Team Edition 11.7.0** 이미지를 digest로 고정합니다. Enterprise/Entry 또는 평가판 이미지가 아닙니다.

- **상용·사내 업무 운영:** 공식 Team 컴파일 배포물의 MIT 라이선스는 상업적 사용과 실제 업무 운영을 허용하며 평가·비운영 전용으로 제한하지 않습니다. OCI 비용과 운영 책임은 별개입니다.
- **수정·재배포:** MIT 대상 배포물은 복사·수정·배포·판매할 수 있지만 모든 사본 또는 중요한 부분에 저작권 및 허가 고지를 유지해야 합니다. 무보증 조건, 포함된 제3자 라이선스 및 Mattermost 상표 정책도 확인하세요.
- **소스는 별도:** 공식 바이너리의 MIT를 서버 소스 전체에 적용하면 안 됩니다. v11.7.0 소스 정책은 AGPLv3/상용 라이선스와 디렉터리별 Apache-2.0 예외를 구분합니다. 소스 수정·자체 빌드 시 해당 조건과 AGPL의 소스 제공 의무(수정 서버의 네트워크 사용자 포함)를 별도 검토하세요.
- **인원·규모:** MIT 문구에는 사용자 수 제한이 없습니다. 공식 제품 문서는 Team을 활성 사용자 250명 미만의 소규모 팀에 적합하다고 설명하고 정부·민감한 상업 업무에는 권장하지 않습니다. 이는 MIT 사용권 제한이나 이 VM의 성능 보장이 아닙니다. 이 조사에서는 11.7.0의 기술적 사용자 상한을 실증하지 않았습니다.
- **Enterprise/Entry/평가판:** Entry는 Enterprise 배포물의 무료 모드이며 Team과 다릅니다. 현재 Enterprise Free Version 계약에는 평가·테스트·비운영 전용 및 최대 100명 조건이 있습니다. 작은 팀용이라는 소개나 무료 실행만으로 업무 운영이 허용된다고 판단하지 마세요. 평가판·구독은 각 계약을 확인해야 합니다.
- **기능:** 무료/유료 여부를 모든 API·플러그인에 일괄 적용하지 않습니다. SSO·컴플라이언스·HA·AI 등은 해당 기능의 에디션·버전·구독 조건과 별도 서비스 비용을 확인하세요. 최신 비교표는 고정 버전의 실행 검증이 아닙니다.

공식 근거: [라이선스 정책](https://docs.mattermost.com/product-overview/faq-license) · [에디션 비교](https://docs.mattermost.com/product-overview/editions-and-offerings) · [유료 기능 비교](https://mattermost.com/pricing/) · [11.7.0 MIT 원문](https://github.com/mattermost/mattermost/blob/v11.7.0/server/build/MIT-COMPILED-LICENSE.md).
[버전별 근거·계약과 문서의 차이](docs/research/team-edition-license.md)를 함께 확인하세요. 공개 문서에 근거한 설명이며 법률 자문이나 실행 실증이 아닙니다.

## 저장소 자체 라이선스
독립 작성 코드·테스트·문서는 [MIT License](LICENSE), Copyright (c) 2026 AndyPandi를 적용합니다. 외부 이미지·패키지·상표는 별도이며 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 확인하세요.

보안·업그레이드 전에 [SECURITY.md](SECURITY.md)를 확인하세요. 관리자 SSH 개인키를 참여자에게 공유하지 말고 개별 회수 가능한 제한 접근을 마련하세요. 신규 DB는 bootstrap 관리자와 최소권한 앱 계정을 분리합니다. 기존 설치는 자동 전환하지 않으며 별도 유지보수 절차가 필요합니다. PostgreSQL/Mattermost 실제 런타임 검증은 남아 있습니다. digest 고정은 동적 OS/RPM 선택이나 취약점 부재를 보장하지 않습니다. 테스트는 자체 프로젝트 계약 검사이며 Oracle 공식 schema 검증이 아닙니다.
