## 🛠️ Project Environment Setup

To ensure the project runs smoothly and remains consistent across all team members, please update your local environment to match the required versions below.

---

### 📌 Required Versions

| Component                   | Version |
| --------------------------- | ------- |
| Java (JDK)                  | 17      |
| [Gradle](#Step A:)          | 8.12    |
| Android Gradle Plugin (AGP) | 8.7.0   |
| Kotlin                      | 2.0.21  |

---
## 🟢 Flutter Setup (Using FVM)

### 1. Install FVM

```bash
dart pub global activate fvm
```

---

### 2. Use Project Flutter Version

```bash
fvm install
```

---

### 3. Install Dependencies

```bash
fvm flutter pub get
```

---

### ⚙️ Android Setup Instructions

#### Step A: Update Gradle Wrapper

Open the following file:

```
android/gradle/wrapper/gradle-wrapper.properties
```

Update the `distributionUrl` to:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
```

---

#### Step B: Update Plugins (AGP & Kotlin)

Open:

```
android/settings.gradle
```

Update the `plugins` block:

```gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.7.0" apply false
    id "org.jetbrains.kotlin.android" version "2.0.21" apply false
}
```

---

#### Step C: Apply Changes

Run the following commands in your terminal:

```bash
cd android
./gradlew clean
```
---

### ⚠️ Rules

* ❌ **Do NOT run `flutter` directly** → always use `fvm flutter`
* ❌ **Do NOT run `flutter pub upgrade`**
* ❌ **Do NOT change Flutter versions without team agreement**

---

### ✅ Notes

* Make sure you are using **JDK 17**
* Sync your project after changes (Android Studio / VS Code)
* If you face issues, try:

```bash
fvm flutter clean 
fvm flutter pub get
```
