// Import the Firebase SDKs compatible with service workers
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Initialize Firebase with the web configuration
const firebaseConfig = {
  apiKey: "AIzaSyBoCrPxDfL6fnXmJCuefqUYCAfPOzV8S5E",
  authDomain: "dreamseat-75ed1.firebaseapp.com",
  projectId: "dreamseat-75ed1",
  storageBucket: "dreamseat-75ed1.firebasestorage.app",
  messagingSenderId: "194348582720",
  appId: "1:194348582720:web:834e32bd7a4b0af87adca5",
  measurementId: "G-E6K835V3RP"
};

firebase.initializeApp(firebaseConfig);

// Initialize Firebase Cloud Messaging
const messaging = firebase.messaging();
