<!-- project-ssot:docs-constitution version=3 -->
# 문서 헌법

이 문서는 `oci-mattermost-team`의 문서 체계를 정의합니다.
사람과 AI 에이전트는 이 문서를 공통 문서 표준으로 사용합니다.

## 핵심 원칙

### Single Source of Truth

현재 프로젝트 상태는 반드시 `docs/project-state.md`에만 기록합니다.

현재 단계, 현재 기능, 현재 우선순위, 현재 제약, 기술 부채, 로드맵을 다른 문서에 중복해서 기록하지 않습니다.

### 문서 역할 분리

각 문서는 하나의 역할만 가집니다.

- `docs/project-state.md`: 지금 사실인 현재 상태
- `docs/architecture/*`: 지금 시스템이 동작하는 방식
- `docs/decisions/*`: 중요한 결정이 내려진 이유
- `docs/journal/*`: 완료된 작업이 일어난 시점과 이력
- `docs/ideas/YYYY-MM-brainstorming.md`: 공식 현재 상태가 아닌 브레인스토밍과 후보 아이디어

## 문서 우선순위

문서끼리 충돌하면 아래 순서를 따릅니다.

1. `docs/project-state.md`
2. `docs/architecture/*`
3. `docs/decisions/*`
4. `docs/journal/*`
5. `docs/ideas/*`

우선순위가 높은 문서가 이깁니다. 문서와 구현이 다르면, 구현이 명백히 잘못된 경우를 제외하고 문서를 수정 후보로 봅니다.

## 문서 구조

```text
docs/
├── README.md
├── project-state.md
├── ideas/
│   ├── YYYY-MM-brainstorming.md
│   ├── YYYY-MM-storyboard.md
│   ├── YYYY-MM-user-flows.md
│   └── YYYY-MM-notes.md
├── architecture/
│   └── system-overview.md
├── decisions/
│   └── ADR-XXX-*.md
└── journal/
    └── YYYY-MM.md
```

## `docs/project-state.md`

`docs/project-state.md`는 현재 상태의 Single Source of Truth입니다.

포함합니다.

- 프로젝트 목적
- 현재 아키텍처 요약
- 현재 기능
- 현재 우선순위
- 알려진 제약
- 기술 부채
- 로드맵

포함하지 않습니다.

- 작업 이력
- 회의록
- 임시 메모
- 과거 결정의 상세 배경
- 상세 컴포넌트 문서

### 현재 상태 근거 표시(선택)

중요한 현재 기능, 제약, 기술 부채에는 해당 목록 항목 바로 다음 줄에 선택형 근거 표시를 둘 수 있습니다.

```md
- 결제 API를 운영 환경에서 제공합니다.
  <!-- project-ssot:evidence {"claim_id":"payment-api","verified_on":"2026-07-20","sources":[{"kind":"repository","path":"src/payments/api.py"},{"kind":"repository","path":"tests/test_payments.py"},{"kind":"external","reference":"deploy-2026-07-20"}]} -->
```

- `claim_id`는 프로젝트 안에서 중복하지 않습니다.
- `repository` 근거는 프로젝트 내부의 실제 일반 파일만 가리킵니다.
- `external` 근거는 배포 번호나 운영 확인 번호처럼 사람이 추적할 수 있는 값을 기록합니다.
- `verified_on`은 해당 근거를 마지막으로 확인한 날짜입니다.
- 근거 표시는 검토를 돕지만 문장의 사실성을 자동으로 증명하지 않습니다.
- 현재 사실 본문은 계속 이 문서에만 두며, 근거 표시에 현재 상태를 중복하지 않습니다.

다음 검사기는 문서 속 명령이나 내용을 실행하지 않고 표시 형식, 중복 JSON 키와 근거, 날짜, 저장소 경로의 존재와 안전성, 흔한 비밀정보 형태를 확인합니다.

```bash
python3 <project-ssot-skill-dir>/scripts/check_ssot_evidence.py <target-project-root>
```

기존 Contract v3 프로젝트에서는 근거 표시가 선택 사항입니다. 현재 기능, 알려진 제약, 기술 부채의 실제 목록 항목에 근거를 모두 요구하기로 프로젝트가 명시적으로 정한 경우에만 `--require`를 사용합니다.

## `docs/architecture/`

Architecture 문서는 시스템이 현재 어떻게 동작하는지 설명합니다.

고정 파일:

- `system-overview.md`: 전체 구조와 주요 흐름

필요하면 프로젝트의 책임 영역에 맞는 세부 architecture 문서를 만듭니다. 모든 세부 문서는 `system-overview.md`의 관련 문서 목록에서 역할과 함께 링크해야 합니다. 링크되지 않은 파일명을 추측하지 않습니다.

Architecture 문서는 현재 구조를 설명하며, 작업 단계나 우선순위를 기록하지 않습니다.

## `docs/decisions/`

Architecture Decision Record를 이곳에 저장합니다.

목적:

- 중요한 결정과 이유를 기록합니다.
- 결정이 바뀌면 기존 ADR을 고치지 않고 새 ADR을 작성합니다.

파일명 형식:

```text
docs/decisions/ADR-001-documentation-single-source-of-truth.md
docs/decisions/ADR-002-example-decision.md
docs/decisions/ADR-XXX-*.md
```

규칙:

- ADR 번호를 재사용하지 않습니다.
- ADR을 삭제하지 않습니다.
- 과거 ADR은 오타나 깨진 링크 외에는 수정하지 않습니다.
- 상태는 `Proposed`, `Accepted`, `Superseded`, `Rejected` 중 하나를 사용합니다.

ADR 구조:

```text
제목
날짜
상태
배경
결정
고려한 대안
결과
```

## `docs/journal/`

완료된 작업 이력을 이곳에 기록합니다.

파일명 형식:

```text
docs/journal/YYYY-MM.md
```

기록합니다.

- 완료된 작업
- 겪은 문제
- 작업 중 내려진 결정
- 당시 식별한 다음 단계
- 수동 운영 작업

Journal은 과거 이력입니다. 현재 상태 판단에는 `docs/project-state.md`를 사용합니다.

## `docs/ideas/`

채택되지 않은 아이디어, 후보 기능, 브레인스토밍 메모, 나중에 검토할 항목을 이곳에 기록합니다.

파일명 형식:

```text
docs/ideas/YYYY-MM-brainstorming.md
docs/ideas/YYYY-MM-storyboard.md
docs/ideas/YYYY-MM-user-flows.md
docs/ideas/YYYY-MM-notes.md
```

installer는 기본으로 `docs/ideas/YYYY-MM-brainstorming.md`만 생성합니다.
스토리보드, 사용자 흐름, 기타 메모가 필요할 때 나머지 파일을 추가합니다.
모든 ideas 문서는 첫머리에 반드시 공식 현재 상태가 아니라는 문구를 둡니다.

기록합니다.

- 아직 채택되지 않은 아이디어
- 후보 기능
- 브레인스토밍 메모
- 스토리보드와 후보 사용자 흐름
- 나중에 검토할 항목

기록하지 않습니다.

- 현재 우선순위
- 확정된 로드맵
- 현재 시스템 동작
- 완료된 작업 이력

아이디어가 실제 방향으로 채택되면 `docs/project-state.md`, `docs/architecture/*`, `docs/decisions/*` 중 맞는 위치로 승격합니다.
`docs/ideas/*`는 공식 현재 상태가 아니며, 충돌 시 항상 다른 문서보다 낮은 권위를 가집니다.

## 추론 및 모호성

승인된 결정만으로 구현 사실, 현재 아키텍처, 완료 이력을 추론하지 않습니다.
현재 상태 사실만으로 문서에 없는 아키텍처 세부사항을 만들어내지 않습니다.
완료 증거가 없으면 완료 이력에 기록하지 않습니다.
확인된 사실이 여러 역할에 걸치면 관련 SSOT 문서를 모두 갱신합니다.
변경 범위가 실질적으로 모호하면 기존 내용을 보존하고 모호함을 보고합니다.

## 변경 규칙

기능 추가:

- `docs/project-state.md`
- 필요한 경우 관련 `docs/architecture/*`
- 완료 후 `docs/journal/YYYY-MM.md`

기능 제거:

- `docs/project-state.md`
- 관련 `docs/architecture/*`
- 완료 후 `docs/journal/YYYY-MM.md`

아키텍처 변경:

- 새 ADR
- 관련 `docs/architecture/*`
- `docs/project-state.md`
- 완료 후 `docs/journal/YYYY-MM.md`

Database/storage 변경:

- `docs/architecture/system-overview.md` 또는 이 문서에서 링크한 기존 세부 architecture 문서
- 세부 문서를 새로 만들면 `docs/architecture/system-overview.md`의 관련 문서 목록에 링크와 역할 추가
- `docs/project-state.md`
- 필요한 경우 ADR
- 완료 후 `docs/journal/YYYY-MM.md`

외부 연동 변경:

- `docs/architecture/system-overview.md` 또는 이 문서에서 링크한 기존 세부 architecture 문서
- 세부 문서를 새로 만들면 `docs/architecture/system-overview.md`의 관련 문서 목록에 링크와 역할 추가
- `docs/project-state.md`
- 필요한 경우 ADR
- 완료 후 `docs/journal/YYYY-MM.md`

기술 부채 추가 또는 해결:

- `docs/project-state.md`
- 완료 후 `docs/journal/YYYY-MM.md`

## 문서 라우팅

`AGENTS.md`는 AI 에이전트의 가벼운 진입점이자 문서 라우팅 안내서입니다. 상세 프로젝트 지식을 중복하지 않습니다.

- 현재 상태, 기능, 우선순위, 제약, 기술 부채는 `docs/project-state.md`에서 확인합니다.
- 전체 아키텍처와 시스템 동작은 `docs/architecture/system-overview.md`에서 확인합니다.
- 중요한 결정과 이유는 `docs/decisions/`의 관련 ADR에서 확인합니다.
- 완료된 작업과 이력은 `docs/journal/`의 관련 월별 파일에서 확인합니다.
- 채택되지 않은 아이디어는 `docs/ideas/`의 관련 파일에서 확인합니다.
- 문서 역할과 유지보수 방식은 `docs/README.md`에서 확인합니다.

`docs/architecture/system-overview.md`는 고정된 architecture 진입점입니다. 프로젝트별 세부 architecture 문서는 이 문서에서 역할과 함께 링크하며, 링크되고 현재 질문이나 작업과 관련된 문서만 읽습니다. 링크되지 않은 파일명을 추측하지 않습니다.

## AI 작업 규칙

모든 AI 에이전트는 프로젝트 변경 작업 전에 아래 문서를 읽습니다.

1. `docs/README.md`
2. `docs/project-state.md`

현재 질문이나 작업이 아키텍처 또는 시스템 동작과 관련되면 `docs/architecture/system-overview.md`에서 시작하여, 이 문서가 링크한 세부 architecture 문서 중 현재 작업과 관련된 문서만 읽습니다. 링크되지 않은 파일명을 추측하지 않습니다.

작업 후:

- `docs/project-state.md`가 현재 상태와 일치하는지 확인합니다.
- 구조나 동작이 바뀌었으면 `docs/architecture/*`를 갱신합니다.
- 중요한 결정에는 ADR을 추가합니다.
- 완료된 작업은 `docs/journal/YYYY-MM.md`에 기록합니다.

## 최종 원칙

`docs/README.md`는 문서 헌법입니다.

`docs/project-state.md`는 현재 사실입니다.
