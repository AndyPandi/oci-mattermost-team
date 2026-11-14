# ADR-004: 공개키 native 입력과 리전 선택 방어

- 날짜: 2026-11-14
- 상태: Accepted

## 배경
SSH 파일 입력과 리전 변경 시 오래된 AD/VCN/subnet 선택 방지가 필요하다. 공식 RM 문서와 현재/archived Oracle 예제를 대조했으며 상세 근거는 [조사 문서](../research/resource-manager-controls.md)에 둔다.

## 결정
- 공식 `oci:core:ssh:publickey`를 사용하고 단일 공개키 문자열/기존 Terraform 검증을 유지한다.
- Compute의 브라우저 키 생성 UX를 RM도 지원한다고 추정하지 않는다. 개인키를 Terraform으로 생성하거나 state에 넣지 않는다.
- 공개 meta schema에서 거부되는 region/regionName dependency를 추측으로 넣지 않는다. archived AD 예제만으로 VCN/subnet 지원을 일반화하지 않는다. Console에서 확인될 때까지 선택 기능과 기존 compartment/VCN 필터를 유지한다.
- provider 리전의 AD 조회 및 기존 VCN/subnet 조회·postcondition으로 stale 선택을 Plan에서 차단한다. 기존 공유 네트워크는 변경하지 않는다.

## 고려한 대안
- 일반 file 컨트롤: Base64 의미가 달라 공개키 전용 컨트롤을 선택.
- TLS private key resource: 비밀이 Terraform state에 들어가므로 제외.
- regionName을 세 컨트롤 모두에 추가: 현재 공식 schema와 충돌하며 실제 Console 지원 증거가 없어 제외.
- 리전 선택 비활성화: 사용자 선택을 불필요하게 제한하므로 제외.

## 결과
입력 안전성과 Plan 검증은 강화되지만 UI 자동 새로고침 해결의 증거는 아니다. 최신 설정 업로드, 저장 변수 재선택, 새 Plan 검토와 Console 수동 확인 절차를 제공한다.
