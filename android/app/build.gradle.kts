plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.growday"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.growday"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf("-Xlint:-options")
    }

    buildTypes {
        release {
            // ⚙️ Replace with your actual release key when signing for production
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        // ✅ Avoid duplicate files from multiple dependencies
        resources {
            excludes += setOf(
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Desugaring for modern Java APIs (required for some libraries)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.1")

    // ✅ Firebase BoM (keeps all Firebase versions in sync)
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))

    // ✅ Firebase services
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // ✅ Google Play services (required for flutter_local_notifications, etc.)
    implementation("com.google.android.gms:play-services-base:18.5.0")

    // ✅ Kotlin standard library
    implementation("org.jetbrains.kotlin:kotlin-stdlib")

    // ✅ MultiDex support for large Flutter + Firebase apps
    implementation("androidx.multidex:multidex:2.0.1")
}