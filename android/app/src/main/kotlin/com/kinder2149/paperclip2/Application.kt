package com.kinder2149.paperclip2

import androidx.multidex.MultiDexApplication

class Application : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        // Firebase a été remplacé par un backend FastAPI
    }
}