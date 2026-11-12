# 프로젝트 상태

현재 상태의 유일한 기준 문서. 갱신: 2026-11-12.

## 목적
다양한 OCI PoC를 수행하는 관계자에게 반복 배포 가능한 협업 환경을 제공한다. PoC 종료 시 채널별 TXT + 첨부파일을 일괄 다운로드한다. 다른 Mattermost로 import하는 것은 사용자 목표가 아니다.

## 현재 구현
- 2단계 코드: Terraform root/provider lock, 조건부 Resource Manager schema, Oracle Linux bootstrap, SSH localhost Compose, mock/정적 검사. **실제 Apply·VM 배포·기능 테스트는 미실행**.
- 입력: 이름/compartment/AD/shape/OCPU/RAM/SSH key/제한 CIDR, 신규·기존 네트워크, ephemeral·새 reserved·공인 IP 없음, private IP 자동·수동. OS/50 GiB는 변경 불가 안내.
- 기존 reserved IP adoption, HTTPS/Caddy, TXT+첨부파일 아카이브는 미구현. 기존 IP는 변경/삭제하지 않음.
- 기존 Marketplace 인스턴스는 본 저장소 구현 검증 결과가 아님.

## 확정한 요구사항
- 개발은 비공개로 진행하고 구현·테스트 후 공개 전환. 저장소 공개 범위를 이 작업에서 변경하지 않음.
- Oracle Linux 9 계열 + Docker Engine/Compose + 공식 Mattermost Team Edition 이미지 + PostgreSQL. HTTPS 모드는 Caddy + Let’s Encrypt 자동 발급·갱신.
- **기본 50GB Boot Volume만 사용**, 추가 Block Volume/attachment 생성 금지. DB와 첨부파일은 호스트 디렉터리에 bind mount. 실제 이미지 최소 크기와 디스크 여유는 검증 필요.
- SSH 터널 / 직접 HTTPS 모드. 신규 VCN / 기존 VCN·subnet 선택. 기존 공유 네트워크를 임의로 변경하지 않음.
- 관리자 암호는 Terraform 입력에서 제외하고 보호된 최초 접속에서 생성.
- 아카이브는 채널별 TXT + 첨부파일, 메시지와 파일 관계·작성자·시간·스레드 보존. DM/비공개 반출은 별도 승인.

## 현재 우선순위
1. 별도 승인 후 Resource Manager UI 렌더링과 실제 Plan/Apply, Oracle Linux9 Docker/SELinux/healthcheck 실증.
2. 신규/기존/새 reserved/no-public 네트워크, 재부팅·데이터 유지·백업 복원 검증.
3. HTTPS 및 채널 TXT+첨부파일 아카이브 단계 구현.

## 알려진 제약·미결정
- Team Edition 11.7.0 amd64와 PostgreSQL 17.9-alpine을 실제 registry manifest digest로 고정했다. PG17 경로는 /var/lib/postgresql/data. ARM/A1 제외.
- Docker 공식 설치 문서는 RHEL9 대상이다. Oracle Linux9 적용 코드의 실제 설치/SELinux 동작은 아직 검증하지 못했다. Docker RPM 버전과 최신 OL9 이미지 선택은 mutable이며 변경 Plan/패키지 검토가 필요하다.
- 기존 subnet의 DNS/egress/SSH 경로와 합산 security list는 운영자가 보장해야 한다. no-public은 기존 VPN/bastion 및 NAT 등 outbound 경로 필수, 신규 private-only는 거부한다.
- quota/shape capacity/미사용 private IP는 정적 검사로 보장하지 않는다. schema 공식 JSON 구조 검증은 통과했지만 실제 OCI Console 렌더링 검증은 별개다.
- 도메인 및 ACME 검증 방식 미확정. 앱 IP 제한과 CA 검증을 분리하여 갱신 경로 유지 필요.
- 50GB에 OS·이미지·DB·첨부파일·로그·아카이브 임시 공간이 모두 포함된다.
- 비공개 ZIP은 익명 배포 버튼에서 다운로드할 수 있다고 가정하지 않는다. 개발 중 ZIP 업로드/인증 Git 경로를 검증하고 공개 후 버튼 E2E 검사.
- Team Edition mmctl export 범위는 버전별 실측 필요. TXT 변환은 기존 도구 또는 API 검토 후 선정. 유료 compliance export와 구분.
- 자체 프로젝트 공개 라이선스는 미결정. Compose는 독립 작성했고 upstream 소스는 복사하지 않았다. SSH deploy key로 push 가능 여부는 확인 가능하지만 GitHub 공개/비공개 설정 자체를 조회한 증거는 아니다.

## 검증 체크리스트
완료 표시에는 명령/버전/결과 근거를 남긴다.
- [x] Terraform 1.9.8 fmt/init -backend=false/validate, OCI provider 7.22.0, mock plan 15건, YAML/shell/내장 Python/변수 일치 검사 통과. 공식 RM schema(Draft7) 정적 검증 통과. 실제 Console UI는 미검증.
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
- README에 현재용 스택 생성/ZIP 업로드 버튼과 공개 후 zipUrl 자동 불러오기 버튼을 분리했다. 비공개 소스 자동 다운로드는 미지원이며 공개 범위 변경이나 토큰 노출은 하지 않았다. 링크 구조는 공식 문서 기준, 실제 로그인·콘솔·ZIP 자동 수집 E2E는 미검증.
