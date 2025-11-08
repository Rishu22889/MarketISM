// Firebase Cloud Messaging Service Worker - DISABLED FOR SIMPLE AUTH TESTING
/*
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Firebase configuration for development
const firebaseConfig = {
  apiKey: "demo-api-key",
  authDomain: "demo-marketism-dev.firebaseapp.com",
  projectId: "demo-marketism-dev",
  storageBucket: "demo-marketism-dev.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:demo-app-id"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase Cloud Messaging and get a reference to the service
const messaging = firebase.messaging();
*/

console.log('Firebase messaging service worker disabled for simple auth testing');

/*
// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'MarketISM';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new message',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'marketism-notification',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
*/

// Handle notification clicks
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Notification click received.');

  event.notification.close();

  // Handle the click action
  event.waitUntil(
    clients.openWindow('/')
  );
});