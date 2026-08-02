plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystore = System.getenv("BIBLEPULSE_ANDROID_KEYSTORE")
val releaseStorePassword = System.getenv("BIBLEPULSE_ANDROID_STORE_PASSWORD")
val releaseKeyAlias = System.getenv("BIBLEPULSE_ANDROID_KEY_ALIAS")
val releaseKeyPassword = System.getenv("BIBLEPULSE_ANDROID_KEY_PASSWORD")
val releaseSigningReady = listOf(
    releaseKeystore,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

android {
    namespace = "app.biblepulse.reader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "app.biblepulse.reader"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                storeFile = file(releaseKeystore!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Store/publish builds must set BIBLEPULSE_ANDROID_* env vars.
            // Without them, sign with the debug keystore so CI/sideload APKs
            // install on devices ("package appears to be invalid" = unsigned).
            signingConfig = if (releaseSigningReady) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

tasks.register("verifyReleaseSigning") {
    doLast {
        check(releaseSigningReady) {
            "Release signing variables are required for publishable Android artifacts."
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
