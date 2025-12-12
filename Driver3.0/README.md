# Mighty Taxi Driver 3.0 – Setup Guide (FVM + Flutter 3.22.3)

Project này sử dụng **FVM (Flutter Version Manager)** để cố định version Flutter = `3.38.1`  
→ Ai pull về cũng dùng đúng SDK, tránh vỡ build do khác version.

Thư mục Flutter app:  
`MightyTaxiSourceCode/Driver3.0` (chính thư mục này có `pubspec.yaml`)

---

## 1. Yêu cầu môi trường

- **FVM** (Flutter Version Manager)
- **JDK 17** (Java 17 LTS)


---

## 2. Cài FVM

```bash
dart pub global activate fvm
# hoặc
flutter pub global activate fvm
Kiểm tra fvm đã cài đặt: fvm --version
Nếu chưa cài Flutter v3.38.1: fvm install 3.38.1
Gán Flutter v3.38.1 cho project này: fvm use 3.38.1

## 3. Cài JDK 17
Kiểm tra đã có JDK 17: 
    fvm flutter doctor -v
    Output Result: 
        [√] Android toolchain - develop for Android devices (Android SDK version 36.1.0)
        • Android SDK at C:\Users\Admin\AppData\Local\Android\sdk
        • Platform android-36, build-tools 36.1.0
        • Java binary at: C:\Program Files\Java\jdk-17\bin\java
        • Java version Java(TM) SE Runtime Environment (build 17.0.10+11-LTS-240)
        • All Android licenses accepted.
Nếu chưa thì cài thì cài: https://www.oracle.com/java/technologies/downloads/#java17-windows
Giải nén xong thì được cài vào: C:\Program Files\Java\jdk-17
Khai báo cho Project dùng JDK này: fvm flutter config --jdk-dir="C:\Program Files\Java\jdk-17"
Chạy lại: fvm flutter doctor -v

## 4. Cài dependencies
fvm flutter clean
fvm flutter pub get

## 5. Run
Vào File → Settings → Languages & Frameworks → Flutter
Flutter SDK path: chọn ../root_project/.fvm/flutter_sdk
Click Run