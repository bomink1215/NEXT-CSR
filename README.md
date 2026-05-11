# 같이삽시다 🏠

> 1인 가구를 위한 초근거리 거래·소통 플랫폼
> **더 가볍게 사고(Buy), 더 즐겁게 사는(Live) 법**

고려대학교 정보대학 NE:XT Contest 2026 출품작

---

## 팀 정보
| 이름 | 학번 | 역할 |
|------|------|------|
| 이예주 (대표) | 2023320031 | 기획자, 개발자 |
| 김보민 | 2023320005 | 디자이너, 개발자 |
| 양재인 | 2023320013 | 기획자, 개발자 |
| 이영지 | 2023320039 | 디자이너, 개발자 |

---

## 핵심 기능

### 🛒 공동구매 & 소분
- 도보 5~15분 내 이웃과 대용량 생활용품 / 배달음식 나누기
- 실시간 참여 현황 및 1인 부담금 자동 계산
- 참여 즉시 채팅방 생성 → 직거래 일정 조율

### 🔄 물물교환
- 남는 물건 ↔ 필요한 물건 즉시 교환
- 채팅 기반 실시간 협의 → 거래 프로세스 연결
- 교환 상태 관리 (교환 가능 / 채팅 중 / 완료)

### 🏠 원룸 솔직 리뷰
- 실거주자 중심 리뷰 DB (광고 없음)
- 층간소음 / 결로 / 수압 / 집주인 성향 등 상세 후기
- 포인트 시스템: 리뷰 작성(+30P), 광고 시청(+10P), 열람(-50P)

### 👥 소규모 모임
- "오늘 저녁 혼밥 메이트", "집 앞 산책 파트너" 등 즉각 모임 생성
- 성별 / 연령 필터로 적합한 구성원만 참여
- 정원 마감 시 자동 차단 + 장소 안내 시스템 메시지

---

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── theme/
│   └── app_theme.dart          # 컬러/타이포그래피 테마
├── models/
│   ├── models.dart             # 데이터 모델
│   └── mock_data.dart          # 목업 데이터
├── widgets/
│   └── common_widgets.dart     # 공통 위젯
└── screens/
    ├── home_screen.dart        # 홈 (대시보드)
    ├── group_buy_screen.dart   # 공동구매
    ├── exchange_screen.dart    # 물물교환
    ├── review_screen.dart      # 원룸 리뷰
    ├── gather_screen.dart      # 모임
    └── chat_list_screen.dart   # 채팅
```

---

## 실행 방법

```bash
# 의존성 설치
flutter pub get

# 실행
flutter run

# 빌드 (Android)
flutter build apk --release

# 빌드 (iOS)
flutter build ipa --release
```

## 요구사항
- Flutter 3.x 이상
- Dart 3.x 이상
- Android SDK / Xcode (iOS 빌드 시)

## 주요 패키지
| 패키지 | 용도 |
|--------|------|
| google_fonts | Noto Sans KR 폰트 |
| cached_network_image | 이미지 캐싱 |
| badges | 알림 뱃지 |
| shimmer | 로딩 스켈레톤 |
