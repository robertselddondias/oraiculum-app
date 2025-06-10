import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.Project

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Função para carregar propriedades locais
fun getLocalProperty(key: String, project: Project): String {
    val properties = Properties()
    val localPropertiesFile = project.rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        properties.load(FileInputStream(localPropertiesFile))
        return properties.getProperty(key) ?: ""
    }
    return ""
}

// Carregar propriedades da chave de assinatura de um arquivo seguro
val keyPropertiesFile = rootProject.file("android/key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.selddon.oraculum"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    // Configuração para assinar o app lendo de um arquivo seguro
    signingConfigs {
        create("release") {
            storeFile = file("release-key.jks")
            storePassword = "@@22anakin31"
            keyAlias = "chave_release"
            keyPassword = "@@22anakin31"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.selddon.oraculum"
        minSdk = 23
        targetSdk = 35
        versionCode = getLocalProperty("flutter.versionCode", project).toIntOrNull() ?: 1
        versionName = getLocalProperty("flutter.versionName", project).takeIf { it.isNotEmpty() } ?: "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:2.0.0"))
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("androidx.multidex:multidex:2.0.1")

    // CORRIGIDO: Versão da biblioteca desugar alterada para uma versão estável e disponível.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Dependências do Firebase (BoM - Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
}