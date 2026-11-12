# 구조 안내

## 현재 저장소 구조
README는 문서 진입점, docs/project-state.md는 현재 상태, ADR은 채택한 설계와 이유, journal은 이력이다. 실행 가능한 서비스 구조로 문서 설계를 오해하지 않는다.

## 관련 문서
- [배포·영속 저장·아카이브 설계 결정](../decisions/ADR-002-deployment-and-archive.md): 목표 컴포넌트와 흐름
- [공식 Compose 재사용 검토](../research/upstream-compose.md): 외부 구현을 참조할 때의 차이점
- [상태 및 검증 체크리스트](../project-state.md): 구현 여부와 미검증 항목

구현이 추가되면 해당 파일을 근거로 실제 시작 순서, 포트, 데이터 경로 및 실패 복구 동작을 이 문서에 기록한다.
