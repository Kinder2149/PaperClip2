package com.kinder2149.paperclip2

import androidx.multidex.MultiDexApplication
import com.google.firebase.FirebaseApp

class Application : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
}