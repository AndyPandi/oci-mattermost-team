# 프로젝트 상태

현재 상태의 유일한 기준 문서. 갱신: 2026-11-14.

## 목적
OCI에 Mattermost Team Edition 협업 환경을 반복 배포한다. 대화·자료 공유와 필요 시 별도 도구를 통한 오프라인 아카이브를 위한 배포 구성이 목적이며, 다른 Mattermost로 import하는 것은 사용자 목표가 아니다.

## 현재 구현
- 2단계 코드: Terraform root/provider lock, 조건부 Resource Manager schema, Oracle Linux bootstrap, SSH localhost Compose, mock/정적 검사. 사용자가 Oracle Linux 9 VM에서 Compose healthy와 API OK를 확인했다고 보고했다. 이번 변경에서는 OCI 쓰기/Apply/VM SSH 없이 로컬 검사만 실행했다.
- 입력: 이름/compartment/AD/shape/OCPU/RAM/SSH key/IPv4 CIDR(/0–/32), 신규·기존 네트워크, ephemeral·새 reserved·공인 IP 없음, private IP 자동·수동. OS/50 GiB는 변경 불가 안내.
- 기존 reserved IP adoption, HTTPS/Caddy, TXT+첨부파일 아카이브는 미구현. 기존 IP는 변경/삭제하지 않음.
- 기존 Marketplace 인스턴스는 본 저장소 구현 검증 결과가 아님.

- SSH CIDR은 유효한 IPv4 /0–/32를 허용하고 IPv6·잘못된 CIDR은 거부한다. 필수 입력이며 기본값 없이 관리자 IP /32를 권장한다. 명시적 `0.0.0.0/0`은 TCP 22를 모든 IPv4에 허용한다. 키 인증은 유지되며 설치 후 자동 차단하지 않는다. 스택 변수 `ssh_ingress_cidr`를 좁히고 Plan 검토 후 Apply해야 한다. 별도 opt-in gate는 없다.
- SSH 입력은 native `oci:core:ssh:publickey`/단일 공개키이며 Terraform string·검증은 유지한다. native 키 생성/개인키 다운로드는 지원 근거 미확인으로 추가하지 않았다.
- region은 Console 세션 리전을 기본값으로 사용하되 선택 가능하다. AD/VCN/subnet의 동적 리전 refresh는 공식 meta schema와 archived 예제가 충돌하여 미해결/Console 확인 대기다. compartment/VCN 필터는 유지한다. provider 리전의 AD 조회, 기존 VCN/subnet 읽기와 compartment·VCN·AD 방어를 추가했다.

## 확정한 요구사항
- 개발은 비공개로 진행하고 구현·테스트 후 공개 전환. 저장소 공개 범위를 이 작업에서 변경하지 않음.
- Oracle Linux 9 계열 + Docker Engine/Compose + 공식 Mattermost Team Edition 이미지 + PostgreSQL. HTTPS 모드는 Caddy + Let’s Encrypt 자동 발급·갱신.
- **기본 50GB Boot Volume만 사용**, 추가 Block Volume/attachment 생성 금지. DB와 첨부파일은 호스트 디렉터리에 bind mount. 실제 이미지 최소 크기와 디스크 여유는 검증 필요.
- SSH 터널 / 직접 HTTPS 모드. 신규 VCN / 기존 VCN·subnet 선택. 기존 공유 네트워크를 임의로 변경하지 않음.
- 관리자 암호는 Terraform 입력에서 제외하고 보호된 최초 접속에서 생성.
- 아카이브는 채널별 TXT + 첨부파일, 메시지와 파일 관계·작성자·시간·스레드 보존. DM/비공개 반출은 별도 승인.

## 현재 우선순위
1. Resource Manager SSH 컨트롤 렌더링·문자열 전달 및 Chicago→Chuncheon 목록 갱신을 실제 Console에서 확인. 필요 시 별도 승인 후 Plan/Apply; 사용자 VM 결과와 이번 폼 변경 검증을 구분.
2. 신규/기존/새 reserved/no-public 네트워크, 재부팅·데이터 유지·백업 복원 검증.
3. HTTPS 및 채널 TXT+첨부파일 아카이브 단계 구현.

## 알려진 제약·미결정
- Team Edition 11.7.0 amd64와 PostgreSQL 17.9-alpine을 실제 registry manifest digest로 고정했다. PG17 경로는 /var/lib/postgresql/data. ARM/A1 제외.
- Docker 공식 설치 문서는 RHEL9 대상이다. 사용자가 Oracle Linux9 Compose healthy/API OK를 보고했지만 설치 전 과정·SELinux·재부팅/복원은 별도 실증 범위다. Docker RPM 버전과 최신 OL9 이미지 선택은 mutable이며 변경 Plan/패키지 검토가 필요하다.
- 기존 subnet의 DNS/egress/SSH 경로와 합산 security list는 운영자가 보장해야 한다. no-public은 기존 VPN/bastion 및 NAT 등 outbound 경로 필수, 신규 private-only는 거부한다.
- quota/shape capacity/미사용 private IP는 정적 검사로 보장하지 않는다. 공식 컨트롤 definition 검증과 실제 OCI Console 렌더링은 별개다. 공개 meta schema는 SSH definition을 전체 union에서 누락하고 region dependency도 허용하지 않아 전체 schema 통과/리전 자동 갱신 완료로 보고하지 않는다.
- 도메인 및 ACME 검증 방식 미확정. 앱 IP 제한과 CA 검증을 분리하여 갱신 경로 유지 필요.
- 50GB에 OS·이미지·DB·첨부파일·로그·아카이브 임시 공간이 모두 포함된다.
- 비공개 ZIP은 익명 배포 버튼에서 다운로드할 수 있다고 가정하지 않는다. 개발 중 ZIP 업로드/인증 Git 경로를 검증하고 공개 후 버튼 E2E 검사.
- Team Edition mmctl export 범위는 버전별 실측 필요. TXT 변환은 기존 도구 또는 API 검토 후 선정. 유료 compliance export와 구분.
- 자체 프로젝트 공개 라이선스는 미결정. Compose는 독립 작성했고 upstream 소스는 복사하지 않았다. SSH deploy key로 push 가능 여부는 확인 가능하지만 GitHub 공개/비공개 설정 자체를 조회한 증거는 아니다.

## 검증 체크리스트
완료 표시에는 명령/버전/결과 근거를 남긴다.
- [x] Terraform 1.9.8 fmt/init -backend=false/validate, OCI provider 7.22.0, mock plan 34건, YAML/shell/내장 Python/변수 일치 검사 통과. 공식 RM 컨트롤별 definition(Draft7) 정적 검증 통과(전체 meta schema의 SSH union 누락은 조사 문서 참조). 실제 Console UI는 미검증.
- [ ] Oracle Linux 이미지 50GB 부트 지원, 파일시스템 사용 가능 용량 확인
- [ ] Team Edition 빌드·버전 확인, 기본 Enterprise 이미지 오사용 방지
- [ ] 신규/기존 네트워크 경로, 기존 자원 불변 확인
- [ ] SSH 제한, 8065/5432 외부 비공개, 최초 관리자 등록 보호
- [ ] 채널/DM/스레드/한글 메시지/동명 첨부파일/WebSocket 동작
- [ ] 컨테이너 재생성·VM 재부팅 후 DB/파일/설정 유지
- [ ] Caddy staging 발급·재발급/재시작 복구 및 갱신 설정 확인 (실제 장기 갱신 관찰과 구분)
- [ ] 로그 회전·여유 공간 검사·아카이브 공간 부족 시 안전 실패
- [ ] 대상 채널 TXT·첨부파일 외부 다운로드, 연결 관계·누락·시간대 확인
- [ ] DB 백업/복원 검증은 운영 복구 목적이며 사용자용 TXT와 구분
- [ ] Destroy/부트 볼륨 삭제 경고와 외부 아카이브 선행 확인
- [ ] 공개 전 비밀/내부 정보/라이선스 검토 및 README 버튼 전체 배포 검증

## 기술 부채
실제 VM E2E, PG 최소권한 계정 분리, 지속 디스크 모니터링/첨부파일 용량 정책, OS/RPM 완전 재현성, 외부 백업 복원 검증이 남아 있다. 최초 디스크 여유 검사는 지속 모니터링이 아니다.

## 배포 버튼 상태
- 한국어 README.md와 영어 README.en.md 각각에 공개용 zipUrl 자동 불러오기 버튼 하나만 제공한다. 수동 ZIP은 텍스트 대안으로 안내한다. 비공개 소스 자동 다운로드는 미지원이며 공개 범위 변경이나 토큰 노출은 하지 않았다. 링크 구조는 공식 문서 기준, 실제 로그인·콘솔·ZIP 자동 수집 E2E는 미검증.

## 배포 설명과 라이선스 근거
- 두 README와 RM 제목은 범용 OCI 배포로 안내한다. 신규 이름 기본값은 `mattermost`; 기존 스택은 저장된 이름을 유지하고 Plan을 검토한다. 기존 VCN/subnet DNS 라벨은 교체 위험을 피하려고 유지했다. 과거 ADR은 당시 배경을 보존한다.
- 공식 Team 바이너리 MIT와 AGPL 서버 소스, Enterprise 무료 모드 계약을 구분한 [조사](research/team-edition-license.md)를 제공한다. Team 11.7.0/PG17.9 digest는 변경하지 않았다. 문서·라이선스 검토는 런타임 에디션/사용자 상한/기능 실증이 아니다. 자체 저장소 라이선스는 계속 미결정이다.
