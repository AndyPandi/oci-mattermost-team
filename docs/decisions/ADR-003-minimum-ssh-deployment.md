# ADR-003: 안전한 SSH 최소 배포와 IP 소유권

- 날짜: 2026-11-12
- 상태: Accepted

## 배경
2단계는 다른 PoC의 협업 환경을 반복 배포할 기반이다. 이번 승인에는 코드와 정적 검증만 포함되고 클라우드 Apply는 포함하지 않는다.

## 결정
- 고정 50 GiB boot-only, Oracle Linux 9, amd64 Team Edition 11.7.0과 PostgreSQL 17.9 digest를 사용한다. 공식 Team Edition manifest가 amd64만 제공하여 A1/ARM은 제외한다.
- 1 OCPU/8 GiB는 잠정 기본값이다. 선택 AD의 live shape 범위와 이미지 최소 크기로 검증하고 quota/capacity/free-IP는 보장하지 않는다.
- OS/저장소는 Terraform 상수와 schema 설명/그룹 제목으로 표시한다. 문서화되지 않은 readOnly 속성을 만들지 않는다.
- 기존 네트워크는 read-only, 전용 NSG만 추가한다. 새 네트워크의 private-only는 NAT 미구현이므로 거부한다.
- 기존 reserved IP는 자동 채택하지 않는다. provider의 public_ip 자원은 IP 수명 자체를 소유하므로 import/reassignment/destroy가 기존 자원에 위험하다. 기존 IP를 훔치지 않는 안전한 별도 association 수명 설계 전까지 UI에서 선택하지 못하게 한다. 새 reserved IP만 stack이 생성/삭제한다.
- SSH localhost 모드만 구현하며 HTTPS와 아카이브는 다음 승인 단계로 분리한다.
- Compose는 공식 패턴과 문서를 참조하여 독립 작성한다. upstream 파일을 복제하지 않으며 프로젝트 전체 라이선스를 추정하지 않는다.

## 대안과 결과
upstream Enterprise 기본값과 PostgreSQL 18 경로를 그대로 복사하는 대신 명시적 Team Edition과 PG17 경로를 사용한다. 기존 IP를 CLI provisioner로 변경하는 대안은 소유권·경쟁조건·Destroy 보존 검증이 어려워 제외한다. Docker 공식 RHEL 9 절차를 Oracle Linux 9에 적용하되 Oracle Linux 공식 지원이라고 주장하지 않고 VM 실증을 필수 관문으로 둔다.
