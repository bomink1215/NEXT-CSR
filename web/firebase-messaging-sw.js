importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCGuoLZUR8mbRXouCpMt5ceELdyMEvYa8E",
  authDomain: "gatchi-sapsida.firebaseapp.com",
  projectId: "gatchi-sapsida",
  storageBucket: "gatchi-sapsida.firebasestorage.app",
  messagingSenderId: "787164281308",
  appId: "1:787164281308:web:f0b2d98e3471e715ec7719",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  // notification 필드가 있으면 FCM SDK가 자동으로 알림을 표시함
  // 여기서 showNotification()까지 호출하면 동일 알림이 2번 뜨므로 early return
  if (payload.notification) return;

  // data-only 메시지일 때만 직접 표시
  const notificationTitle = payload.data?.title ?? '같이삽시다';
  const notificationOptions = {
    body: payload.data?.body ?? '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
