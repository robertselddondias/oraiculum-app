plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    compileSdkVersion flutter.compileSdkVersion
            ndkVersion flutter.ndkVersion

            compileOptions {
                sourceCompatibility JavaVersion.VERSION_1_8
                        targetCompatibility JavaVersion.VERSION_1_8
            }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.oraculum.app"
        minSdkVersion 21  // Necessário para Stripe SDK
        targetSdkVersion flutter.targetSdkVersion
                versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName

                // Configurações do Stripe
                manifestPlaceholders = [
            'stripePublishableKey': 'pk_test_51RTpqm4TyzboYffk5IRBTmwEqPvKtBftyepU82rkCK5j0Bh6TYJ7Ld6e9lqvxoJoNe1xefeE58iFS2Igwvsfnc5q00R2Aztn0o'
        ]

        // Multidex support
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
                    minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            applicationIdSuffix ".debug"
            debuggable true
        }
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"

    // Google Play Services
    implementation 'com.google.android.gms:play-services-wallet:19.4.0'
    implementation 'com.google.android.gms:play-services-maps:18.2.0'

    // Firebase
    implementation platform('com.google.firebase:firebase-bom:33.1.2')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-messaging'

    // Stripe Android SDK
    implementation 'com.stripe:stripe-android:20.43.0'

    // Multidex
    implementation 'androidx.multidex:multidex:2.0.1'

    // Biometric authentication
    implementation 'androidx.biometric:biometric:1.1.0'
}


flutter {
    source = "../.."
}
