# ADR-007: IMDSv2 only

- 날짜: 2026-11-15
- 상태: Accepted

## 배경
기존 Terraform은 legacy metadata 차단 옵션을 생략하여 IMDSv2-only 정책을 보장하지 않았다. 외부에서 true인 VM 상태와 저장소 설정은 구분해야 한다.

## 결정
main instance_options에 are_legacy_imds_endpoints_disabled=true를 고정한다. opt-out과 다른 resource/image/cloud-init 변경은 하지 않는다. provider 7.22.0의 schema에는 Optional+Computed, no Default/no ForceNew가 있고 UpdateInstance 경로에 전달된다. 서비스 기본값 false라는 문서는 생략이 안전한 정책이 아님을 보여준다.

## 고려한 대안
생략 유지나 unsafe toggle은 정책 누락을 다시 허용하므로 채택하지 않는다.

## 결과
옵션 자체는 in-place update 대상이지만 실제 Plan은 다른 drift로 교체를 포함할 수 있다. GitHub 갱신만으로 기존 VM은 바뀌지 않는다. OL9 일반 지원을 추정하지 않고 실제 guest 버전/agent/v2/앱 확인을 분리한다. [공식 근거와 읽기 전용 확인 절차](../../SECURITY.md#imds-v2-only)를 따른다.
