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

배포 버튼과 실행 명령은 실제 검증 이후 제공합니다. 문서의 설계도를 실행 가능한 코드로 해석하지 마세요.

## 데이터와 보안
아카이브는 서비스 이전용 DB 백업과 다릅니다. 대화와 첨부파일을 서버 없이 읽을 수 있도록 연결 정보를 보존하는 것이 목표입니다. DM·비공개 채널의 반출 범위는 별도 승인해야 합니다.

OCI 자원 비용은 배포자 부담입니다. VM/부트 볼륨 삭제 전에 외부 다운로드와 열람을 확인해야 합니다. 개인키·실제 환경값·Terraform state·백업 파일은 Git에 올리지 않습니다.

## 라이선스
프로젝트 자체 배포 라이선스는 공개 전 확정합니다. Mattermost 이미지, PostgreSQL, Caddy 및 재사용 소스의 라이선스는 각각 별개입니다. 상위 프로젝트의 라이선스가 본 저장소 전체에 자동 적용되는 것은 아닙니다.
