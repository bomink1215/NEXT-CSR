# 같이삽시다 (gatchi_sapsida) — 프로젝트 코드 개요

> 이 문서는 새 대화 세션에서 AI에게 프로젝트 컨텍스트를 빠르게 전달하기 위한 메모입니다.
> 작업 시작 전에 이 파일을 먼저 읽어주세요.

## 프로젝트 기본 정보

- **이름**: `gatchi_sapsida` ("같이삽시다")
- **설명**: 1인 가구를 위한 초근거리 거래·소통 플랫폼 (동네 기반 공동구매 / 원룸 리뷰 / 모임 / 채팅)
- **스택**: Flutter (Dart SDK 3.3+) + Firebase (Firestore, Auth, Storage)
- **타겟**: 자취인 / 1인 가구
- **주요 패키지**:
  - `firebase_core ^3.0.0`
  - `cloud_firestore ^5.0.0`
  - `firebase_auth ^5.0.0`
  - `firebase_storage ^12.4.10`
  - `provider ^6.1.5+1`
  - `image_picker ^1.2.2`
  - `google_fonts ^6.2.1`

## 폴더 구조

```
lib/
├── main.dart                    # 앱 진입점 + Firebase 초기화
├── firebase_options.dart        # Firebase 설정
├── theme/app_theme.dart         # 색상 팔레트 + ThemeData
├── models/
│   ├── models.dart              # 데이터 모델 (GroupBuyPost, ExchangePost, RoomReview, GatherPost, ChatRoom, AppNotification)
│   ├── user_store.dart          # 사용자 상태 (ChangeNotifier + InheritedNotifier)
│   └── mock_data.dart           # 더미 데이터 (리뷰/알림은 아직 여기 의존)
├── screens/
│   ├── signup_screen.dart       # 회원가입 (닉네임 + 동네)
│   ├── home_screen.dart         # 홈 + 하단 5개 탭 네비게이션
│   ├── group_buy_screen.dart    # 🛒 공동구매
│   ├── exchange_screen.dart     # 🔄 물물교환
│   ├── review_screen.dart       # 🏠 원룸 리뷰
│   ├── gather_screen.dart       # 👥 모임
│   ├── chat_list_screen.dart    # 💬 채팅 목록 + ChatScreen
│   └── notification_screen.dart # 🔔 알림
├── widgets/common_widgets.dart  # 공용 위젯 (TagBadge, WalkBadge, StarRating, ParticipantProgress, ImagePickerModule, EmptyState, SectionHeader)
└── utils/storage_service.dart   # Firebase Storage 이미지 업로드/삭제
```

## 핵심 기능별 동작 방식

### 1. 회원가입 (`signup_screen.dart`)
- 익명 인증(`signInAnonymously`)으로 UID 발급
- Firestore `users/{uid}` 에 `{ name, location, createdAt, points: 0 }` 저장
- 가입 후 `UserStoreProvider`에 이름/동네 저장 → 홈 이동
- 동네 빠른 선택 칩: 안암동, 종암동, 정릉동, 길음동, 미아동, 성북동, 돈암동, 석관동, 장위동, 월곡동

### 2. 공동구매 (`group_buy_screen.dart`)
- Firestore `posts` 컬렉션에서 `type == 'groupBuy'` 필터링
- 카테고리: 식료품 / 생활용품 / 배달음식
- **참여 로직**: 트랜잭션으로 `currentParticipants` 증가 + `chatRooms/{postId}` 생성/업데이트 + 시스템 메시지 추가
- 작성자는 게시글 + 채팅방 batch delete 가능
- 1인 부담금은 `(총금액 / 인원수)` 올림 계산

### 3. 물물교환 (`exchange_screen.dart`)
- `posts` 컬렉션 `type == 'exchange'`
- 상태 enum: `open` / `chatting` / `done`
- 교환 제안 시 `chatRooms/{postId}_{userName}` 형식의 1:1 채팅방 생성
- 작성자 메뉴: "교환 완료로 변경" / "삭제하기"
- 이미지 업로드는 `StorageService.uploadPostImage('exchange', file)` 사용

### 4. 모임 (`gather_screen.dart`)
- `posts` 컬렉션 `type == 'gathering'`
- 성별 필터: `any` / `maleOnly` / `femaleOnly`
- 연령 필터: `any` / `twenties` / `thirties` / `mixed`
- 참여 시 트랜잭션으로 `members` 추가 + 인원 증가 + 그룹 채팅방 생성
- 빠른 카테고리: 혼밥 메이트, 산책, 카페, 게임, 스터디, 운동

### 5. 채팅 (`chat_list_screen.dart`)
- `chatRooms` 컬렉션에서 `members arrayContains 내 이름`으로 필터링
- 각 채팅방의 `messages` 서브컬렉션 실시간 스트리밍
- 메시지 버블 3가지: 시스템 / 일반(상대) / 내 메시지
- `ChatRoomType` enum: `groupBuy` / `exchange` / `gather`

### 6. 원룸 리뷰 (`review_screen.dart`) ⚠️
- **아직 MockData만 사용 (Firestore 미연동)**
- 포인트 시스템 UI만 존재: 리뷰 작성 +30P / 광고 시청 +10P / 열람 -50P
- 잠금 해제 다이얼로그는 SnackBar만 띄우고 실제 로직 없음
- `RoomReview`, `ReviewTag` (isPositive 플래그) 모델 사용

### 7. 알림 (`notification_screen.dart`) ⚠️
- **MockData 기반 (실제 알림 시스템 없음)**
- 읽음 처리 / 스와이프 삭제는 로컬 상태로만 동작
- `NotificationType` enum: `groupBuy` / `exchange` / `gather` / `review` / `system`

## Firestore 스키마 요약

```
users/{uid}
  ├─ name: string
  ├─ location: string
  ├─ createdAt: timestamp
  └─ points: int

posts/{postId}
  ├─ type: 'groupBuy' | 'exchange' | 'gathering'
  ├─ title, description, location, authorName, createdAt
  ├─ (groupBuy) category, totalPrice, unitPrice, maxParticipants, currentParticipants, isFull, members[]
  ├─ (exchange) offerItem, wantItem, imageUrl, status
  └─ (gathering) emoji, place, meetTime, maxMembers, currentMembers, members[], genderFilter, ageFilter

chatRooms/{roomId}
  ├─ title (또는 roomTitle), members[], lastMessage, lastMessageTime
  ├─ type, avatarEmoji, unreadCount, postId
  └─ messages/{msgId}
       ├─ text, senderName (또는 senderId)
       ├─ time (또는 timestamp)
       └─ isSystem
```

## 디자인 시스템 (theme/app_theme.dart)

```dart
primary       = #FF6B35 (오렌지)
primaryLight  = #FFE0D3
secondary     = #2EC4B6 (민트)
accent        = #FFBF47 (노랑)
background    = #FAF8F5
surface       = #FFFFFF
cardBg        = #F5F3EF
divider       = #EEECE8

buyColor      = #FF6B35 (공동구매)
exchangeColor = #9C6FDE (물물교환, 보라)
reviewColor   = #2EC4B6 (리뷰, 민트)
gatherColor   = #FF9800 (모임, 주황)

success = #4CAF50, error = #E53935
```

## 공용 위젯 (widgets/common_widgets.dart)

- `ImagePickerModule(onImageSelected, label)` — 이미지 피커 (웹/모바일 분기)
- `TagBadge(label, color, textColor?)` — 카테고리/상태 뱃지
- `WalkBadge(minutes)` — "도보 N분" 표시
- `ParticipantProgress(current, max, color)` — 참여율 프로그레스 바
- `SectionHeader(title, actionLabel?, onAction?)` — 섹션 헤더
- `StarRating(rating, size?)` — 별점 표시
- `EmptyState(emoji, title, subtitle)` — 빈 상태 안내

## 사용자 상태 관리

```dart
// lib/models/user_store.dart
UserStore : ChangeNotifier {
  String name, location
  bool isSignedUp
  void signUp({name, location})
  void updateLocation(location)
}

// 접근 방법
final store = UserStoreProvider.of(context);
store.name      // 닉네임
store.location  // 동네
```

## ⚠️ 알려진 이슈 / 기술 부채

작업할 때 반드시 인지하고 있어야 할 부분:

1. **`main.dart`에서 `UserStore`가 두 번 생성됨**
   - `MultiProvider`로 하나, `UserStoreProvider`로 또 하나
   - 실제로 화면은 `UserStoreProvider.of(context)`만 사용 → Provider 쪽은 죽은 코드
   - 정리 필요

2. **상태 관리 일관성 부족**
   - `provider` 패키지를 import만 했지 실사용은 자체 `InheritedNotifier`
   - 둘 중 하나로 통일 권장

3. **`ChatRoomType` enum과 DB 값 불일치**
   - DB에 `'gathering'`으로 저장되는 경우와 `'gather'`로 저장되는 경우가 섞여 있음
   - `gather_screen.dart`의 채팅방 생성 시: `type: 'gather'`
   - `posts` 컬렉션: `type: 'gathering'`
   - `ChatRoom.fromMap`에서 fallback으로 `gather`로 빠짐 → 의도치 않은 동작 가능

4. **포인트 시스템이 UI만 존재**
   - 회원가입 시 `points: 0` 저장은 됨
   - 적립/차감 로직은 어디에도 없음
   - 리뷰 화면의 "120P"는 하드코딩

5. **리뷰/알림 화면이 MockData 기반**
   - Firestore 연동 필요

6. **`ExchangeStatus` 매핑 버그**
   - enum: `open` / `chatting` / `done`
   - `exchange_screen.dart`의 `fromMap`에서는 `'completed'`인 경우만 `done`으로 매핑 → 일관성 깨짐

7. **walkMinutes 하드코딩**
   - 모든 화면에서 `walkMinutes: 5` 또는 임시값 사용
   - 실제 거리 계산 로직 없음 (위치 권한, 좌표 저장도 없음)

8. **익명 인증만 사용**
   - 실제 로그인/계정 복구 불가
   - UID는 발급되지만 활용도가 낮음

## 진행 중인 작업 / TODO 메모 영역

> 새 기능 구현 계획이나 진행 상황을 여기에 기록하세요.

- [ ] (계획 중인 기능을 여기에 추가)
