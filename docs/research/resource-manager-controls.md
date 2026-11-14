# Resource Manager 입력 컨트롤 조사 (2026-11-14)

## 공식 근거와 정확한 속성

- [Oracle Schema Documents](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/terraformconfigresourcemanager_topic-schema.htm): Supported Types, SSH key control, Dynamic prepopulation, Meta Schema for Validation의 전체 HTML/code block을 확인했다.
- SSH: `type: oci:core:ssh:publickey`. 공식 설명은 “adding one or more public SSH keys by dropping files or pasting key values”. 공식 예제의 `additionalProps.allowMultiple`을 `false`로 지정해 한 공개키만 받는다. Terraform `string`, 기존 OpenSSH 검증, `trimspace` 전달을 유지한다. 범용 `type: file`은 Base64이므로 사용하지 않는다.
- [Compute Launch 문서](https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/launchinginstance.htm)의 Add SSH keys는 명시적으로 **Generate a key pair for me / Save Private Key / Save Public Key**를 설명한다. RM SSH 컨트롤 문서에는 이에 해당하는 생성/다운로드 속성이 없다. RM의 “Generated SSH private key” 예시는 **출력의 sensitive 표시**이며 Create Stack 브라우저 키 생성 기능의 근거가 아니다.
- 따라서 **RM의 Compute와 동일한 native 생성/다운로드 지원은 확인되지 않았다**. 문서 부재를 전역적인 불가능 증명으로 과장하지 않는다. 이 구성은 공개키 업로드/붙여넣기만 제공하며 Terraform TLS 개인키 생성/state/출력은 추가하지 않는다. 실제 Console에서 생성 옵션이 나타나는지 별도 확인한다.

## 리전 연동: 충돌하는 근거

공개 meta schema의 정확한 구조:
- `availabilityDomainVariable`, `vcnVariable` → `dependsOnCompartment`: `dependsOn.compartmentId`만 허용, `additionalProperties: false`.
- `subnetVariable.dependsOn`: `compartmentId`, `vcnId` 필수. 선택 속성은 `hidePublicSubnet`, `hidePrivateSubnet`, `hideRegionalSubnet`, `hideAdSubnet`; `additionalProperties: false`.
- `regionVariable.default`는 `${session.region}`. 리전 변수의 값이 Console 세션 리전이나 모든 dropdown 조회 리전을 바꾼다는 보장은 없다.
- `dependsOn.region`과 `dependsOn.regionName`은 이 세 컨트롤 모두 공개 meta schema에서 거부된다.

Oracle 소유 예제도 조사했다:
- [hub-spoke schema](https://github.com/oracle-quickstart/oci-arch-hub-spoke/blob/b855731a0d50b4712e8220183afae862d928d614/schema.yaml)는 AD에 `dependsOn.regionName: ${region}`을 사용한다. 다만 schema 변경은 2021년이며 저장소는 조회 시 archived였다. wordpress-mds도 같은 예가 있으나 archived다. **이를 현재 VCN/subnet까지 지원한다는 근거로 확대하지 않는다.**
- 비보관(active) [OCI AI Blueprints](https://github.com/oracle-quickstart/oci-ai-blueprints/blob/main/cluster_creation_terraform/schema.yaml)와 [WebLogic Server](https://github.com/oracle-quickstart/oci-weblogic-server/blob/main/terraform/schema.yaml)의 VCN/subnet은 compartmentId/vcnId 필터를 사용하고 regionName 연동은 없다. WebLogic의 SSH도 native publickey 컨트롤이다.

따라서 세 필드 전체의 **지원되는 동적 리전 dependency를 입증하지 못했으며 추가하지 않았다**. region 선택을 숨기거나 비활성화하지 않는다. Console 리전과 입력 리전을 맞추고 AD/VCN/subnet을 다시 선택하는 운영 절차와 provider 조회 기반 Plan 방어를 제공한다. 이는 UI 자동 새로고침 수정 완료가 아니다.

## 테스트 범위와 upstream meta schema 결함

Oracle 문서에서 관찰한 meta schema에는 SSH definition의 전체 union 누락과 region dependency 제한이 있었다. 이는 문서 관찰이지 Console 구현 증명이 아니다. 과거 복사 fixture는 재배포 권한이 불명확하여 현재 소스에서 제거했다. `tests/static_checks.py`는 독립 작성한 명령형 프로젝트 계약 검사로 native SSH type/allowMultiple=false, 현재 compartment/VCN 필터, 리전 기본값·provider 연결을 보존한다. 공식 definition이나 전체 Oracle schema 검증을 수행하지 않는다. 과거 Git 이력에는 fixture가 남아 있으며 제거는 별도 승인 작업이다.

Terraform mock 검사는 stale AD, VCN/subnet compartment, subnet의 VCN/AD 불일치, regional/AD-specific 정상 subnet, 공개키 문자열·파일 끝 개행·개인키/복수키 거부를 포함한다. 실제 region endpoint의 404/권한 오류나 Console의 자동 목록 갱신은 mock으로 검증할 수 없다.

## Console 수동 확인 절차 (Apply 없이 먼저 확인)

1. 최신 ZIP을 **기존 스택 Edit → Terraform configuration 갱신**에 업로드하거나, 별도 새 스택 생성 화면에 업로드한다. Git push/ZIP 다운로드만으로 기존 스택은 갱신되지 않는다.
2. SSH `.pub` 하나 업로드/드롭 및 붙여넣기를 각각 확인한다. Terraform 값은 문자열이어야 한다. private key는 올리지 않는다. native 생성/다운로드 옵션이 실제 나타나는지도 기록한다.
3. Chicago Console/region에서 AD·VCN·subnet을 고른 뒤 region만 Chuncheon으로 변경해 세 목록과 이전 선택 초기화 여부를 기록한다. UI 자동 갱신은 미검증이므로 남은 Chicago 항목을 선택하지 않는다.
4. 목록이 안 바뀌면 Console 상단 리전을 Chuncheon으로 전환하고 그 리전의 새 Create Stack 화면에서 새 ZIP으로 시작한다. 기존 스택의 리전 이동으로 간주하지 않는다. compartment → AD → VCN → subnet 순서로 다시 선택한다.
5. 기존 스택의 저장된 변수는 자동으로 안전해지지 않는다. 특히 이미 배포한 스택의 region 변경은 다른 endpoint를 향하므로 무심코 Apply하지 않는다. 새 Plan의 provider region, AD, OCID, 교체/삭제를 검토한다. 실제 Plan/Apply는 별도 승인 범위다.
