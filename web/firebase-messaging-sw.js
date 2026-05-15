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
  const notificationTitle = payload.notification?.title ?? '같이삽시다';
  const notificationOptions = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
