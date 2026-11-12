<!-- project-ssot:agents-contract begin version=3 -->
# 에이전트 작업 지침

## Project SSOT 문서 규칙

이 저장소는 docs 기반 Single Source of Truth 체계를 사용합니다.
프로젝트 변경 전 `docs/README.md`와 `docs/project-state.md`를 읽고, 현재 상태는 `docs/project-state.md`만을 기준으로 판단합니다.

## 문서 읽기 라우팅

질문이나 작업에 필요한 문서만 읽습니다.

| 질문 또는 작업 | 우선 참조 문서 |
| --- | --- |
| 현재 상태, 기능, 우선순위, 제약, 기술 부채 | `docs/project-state.md` |
| 전체 아키텍처와 시스템 동작 | `docs/architecture/system-overview.md` |
| 중요한 결정과 이유 | `docs/decisions/`의 관련 ADR |
| 완료된 작업과 이력 | `docs/journal/`의 관련 월별 파일 |
| 채택되지 않은 아이디어 | `docs/ideas/`의 관련 파일 |
| 문서 역할과 유지보수 규칙 | `docs/README.md` |

세부 architecture 문서는 `system-overview.md`에서 연결된 관련 문서만 읽고 파일명을 추측하지 않습니다.
상세 프로젝트 지식을 `AGENTS.md`에 중복하지 않습니다.

## 문서 쓰기 라우팅

- 현재 상태, 기능, 우선순위, 제약, 기술 부채, 로드맵이 바뀌면 `docs/project-state.md`를 갱신합니다.
- 시스템 구조나 동작이 바뀌면 관련 `docs/architecture/*`를 갱신합니다.
- 중요한 결정은 새 `docs/decisions/ADR-XXX-*.md`로 기록합니다.
- 완료된 작업은 `docs/journal/YYYY-MM.md`에 기록합니다.
- 미채택 아이디어는 `docs/ideas/YYYY-MM-*.md`에 기록하고, 채택되면 공식 문서로 승격합니다.

요청이나 확인된 구현으로 확정되지 않은 프로젝트 사실을 추측해 문서화하지 않습니다. 변경 범위가 실질적으로 모호하면 SSOT 변경을 추론으로 확대하지 말고 모호함을 보고합니다.
하나의 변경이 여러 역할에 해당하면 관련 SSOT 문서를 모두 갱신합니다. 상세 규칙은 `docs/README.md`를 따릅니다.
<!-- project-ssot:agents-contract end -->
