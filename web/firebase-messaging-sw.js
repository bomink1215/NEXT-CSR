importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCGuoLZUR8mbRXouCpMt5ceELdyMEvYa8E',
  appId: '1:787164281308:web:f0b2d98e3471e715ec7719',
  messagingSenderId: '787164281308',
  projectId: 'gatchi-sapsida',
  authDomain: 'gatchi-sapsida.firebaseapp.com',
  storageBucket: 'gatchi-sapsida.firebasestorage.app',
});

const messaging = firebase.messaging();