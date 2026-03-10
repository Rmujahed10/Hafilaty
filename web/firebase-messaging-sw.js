importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCWMPnEWiSdWzAHMqO43hb_GS9Hmb1pPwk",
  authDomain: "hafilaty-80caf.firebaseapp.com",
  projectId: "hafilaty-80caf",
  storageBucket: "hafilaty-80caf.firebasestorage.app",
  messagingSenderId: "290002889120",
  appId: "1:290002889120:web:f7854cc718d264020f5cc5"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log("Background message received:", payload);

  const notificationTitle = payload.notification?.title || "Hafilaty";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png"
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});