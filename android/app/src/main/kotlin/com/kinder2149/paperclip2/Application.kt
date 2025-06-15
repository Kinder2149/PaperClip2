package com.kinder2149.paperclip2

import androidx.multidex.MultiDexApplication

class Application : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        // Application initialisée sans dépendances externes
    }
}