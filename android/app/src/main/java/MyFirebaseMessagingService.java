package com.gatiella.symmeapp;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class MyFirebaseMessagingService extends FirebaseMessagingService {
    
    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        // Handle FCM messages here.
        super.onMessageReceived(remoteMessage);
        
        // Log message data (optional)
        if (remoteMessage.getData().size() > 0) {
            // Handle data payload
        }
        
        // Check if message contains a notification payload
        if (remoteMessage.getNotification() != null) {
            // Handle notification payload
        }
    }

    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        // Send token to your server or handle token refresh
    }
}