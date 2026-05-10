package com.example.zak_streaming_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i("BootBroadcastReceiver", "Device boot completed - triggering Workmanager reschedule")

            // Call the Dart method to reinitialize background tasks
            val mainActivity = Intent(context, MainActivity::class.java)
            mainActivity.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            // Note: This will start the app, which will trigger initializeBackgroundTasks()
            context.startActivity(mainActivity)
        }
    }
}

