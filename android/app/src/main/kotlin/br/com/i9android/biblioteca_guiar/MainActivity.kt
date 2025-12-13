package br.com.i9android.biblioteca_guiar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Bundle
import android.os.Debug
import kotlin.system.exitProcess
// Import BuildConfig if not automatically resolved, but usually it is in the same package scope or available.
// If package is br.com.i9android.biblioteca_guiar, BuildConfig is generated there.

class MainActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // ANTI-DEBUG PROTECTION
        // Só executa se NÃO estiver em modo DEBUG (Release Mode)
        if (!BuildConfig.DEBUG) {
            val isDebuggerConnected = Debug.isDebuggerConnected() || Debug.waitingForDebugger()
            
            if (isDebuggerConnected) {
                // Se detectar debugger, mata o processo silenciosamente ou com erro
                exitProcess(0)
            }
        }
    }
}