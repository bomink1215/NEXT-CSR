/**
 * 동 이름만 있는 이전 형식 글 + 관련 채팅방 삭제 스크립트
 *
 * 실행 방법:
 * 1. Firebase Console → 프로젝트 설정 → 서비스 계정 → 새 비공개 키 생성
 * 2. 다운로드된 JSON 파일을 이 스크립트와 같은 폴더에 serviceAccount.json 으로 저장
 * 3. 터미널에서: node delete_old_posts.js
 */

const admin = require('./node_modules/firebase-admin');
const fs = require('fs');
const path = require('path');

// ── 서비스 계정 키 로드 ──────────────────────────────────────────
const serviceAccountPath = path.join(__dirname, 'serviceAccount.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ serviceAccount.json 파일이 없습니다.');
  console.error('   Firebase Console → 프로젝트 설정 → 서비스 계정 → 새 비공개 키 생성');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
  projectId: 'gatchi-sapsida',
});

const db = admin.firestore();

// ── 이전 형식 판별: 공백 없는 동 이름 하나만 있는 경우 ──────────
function isOldFormat(location) {
  if (!location || location.trim() === '') return false;
  const parts = location.trim().split(/\s+/);
  // 파트가 1개 = 동 이름만 ("안암동")
  // 파트가 2개이고 첫 파트가 시/도로 끝나지 않으면 = "성북구 안암동" 형식
  // → 둘 다 이전 형식으로 삭제
  if (parts.length === 1) return true;
  if (parts.length === 2) {
    const first = parts[0];
    // 새 형식이면 첫 파트가 "서울특별시", "경기도" 같은 시도 이름
    const isNewSido = first.endsWith('특별시') || first.endsWith('광역시') ||
                      first.endsWith('특별자치시') || first.endsWith('특별자치도') ||
                      first === '경기도' || first === '강원도' || first === '충청북도' ||
                      first === '충청남도' || first === '전라북도' || first === '전라남도' ||
                      first === '경상북도' || first === '경상남도' || first === '제주도';
    return !isNewSido; // 시도가 아니면 이전 형식
  }
  return false; // 3개 이상이면 새 형식 ("서울특별시 성북구 안암동")
}

async function deleteOldPosts() {
  console.log('🔍 이전 형식 글 조회 중...\n');

  const types = ['groupBuy', 'exchange', 'gathering'];
  let totalPosts = 0;
  let totalChats = 0;
  const postIdsToDelete = [];
  const exchangePostIds = [];

  // ── 1. 삭제 대상 조회 ──────────────────────────────────────────
  for (const type of types) {
    const snap = await db.collection('posts').where('type', '==', type).get();
    for (const doc of snap.docs) {
      const data = doc.data();
      const loc = data.location || '';
      if (isOldFormat(loc)) {
        console.log(`  [${type}] "${data.title || doc.id}" — location: "${loc}"`);
        postIdsToDelete.push(doc.id);
        if (type === 'exchange') exchangePostIds.push(doc.id);
        totalPosts++;
      }
    }
  }

  if (totalPosts === 0) {
    console.log('✅ 삭제할 이전 형식 글이 없습니다.');
    process.exit(0);
  }

  console.log(`\n총 ${totalPosts}개 글 발견`);
  console.log('5초 후 삭제를 시작합니다. 취소하려면 Ctrl+C를 누르세요...\n');
  await new Promise(r => setTimeout(r, 5000));

  // ── 2. posts + chatRooms 삭제 (groupBuy/gathering: 같은 ID) ────
  const BATCH_SIZE = 400;
  let batch = db.batch();
  let opCount = 0;

  const flush = async () => {
    if (opCount > 0) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  };

  for (const postId of postIdsToDelete) {
    batch.delete(db.collection('posts').doc(postId));
    batch.delete(db.collection('chatRooms').doc(postId)); // groupBuy/gather은 동일 ID
    opCount += 2;
    totalChats++;
    if (opCount >= BATCH_SIZE) await flush();
  }

  // ── 3. exchange 채팅방: postId 필드로 연결 ─────────────────────
  if (exchangePostIds.length > 0) {
    const chatSnap = await db.collection('chatRooms')
      .where('type', '==', 'exchange')
      .get();
    for (const chatDoc of chatSnap.docs) {
      const chatPostId = chatDoc.data().postId || '';
      if (exchangePostIds.includes(chatPostId) || exchangePostIds.includes(chatDoc.id)) {
        batch.delete(chatDoc.ref);
        opCount++;
        totalChats++;
        if (opCount >= BATCH_SIZE) await flush();
      }
    }
  }

  await flush();

  console.log(`✅ 완료!`);
  console.log(`   - 글 ${totalPosts}개 삭제`);
  console.log(`   - 채팅방 ${totalChats}개 삭제`);
  process.exit(0);
}

deleteOldPosts().catch(err => {
  console.error('❌ 오류:', err.message);
  process.exit(1);
});
