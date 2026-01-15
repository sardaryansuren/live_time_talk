# 🎙️ live_time_talk

## Real-Time Barge-In TTS (Flutter + Android)

This project demonstrates **real-time Text-to-Speech playback with voice barge-in**, using:

* **Flutter (Dart)** for UI and networking
* **ElevenLabs TTS API** (MP3 streaming – free tier compatible)
* **Android native audio (Kotlin)** for low-latency playback and microphone VAD

When TTS is playing, the user can interrupt (**barge-in**) by speaking — **not** by tapping or playing another audio source.

---

## 📁 Project Structure

```
/lib
 ├── elevenlabs_helper.dart     # Streams TTS audio from ElevenLabs
 ├── barge_in_bloc.dart         # UI state management (button enable/disable)
 └── platform_audio.dart        # Flutter → Android MethodChannel

/android
 └── app/src/main/kotlin/.../
     ├── MainActivity.kt        # MethodChannel wiring
     └── BargeInAudioEngine.kt  # Native audio + mic + VAD engine
```

---

## 🧠 Architecture Overview

### Why native Android audio is required

Flutter does **not** provide:

* Low-latency microphone access
* Echo cancellation
* Reliable real-time voice activity detection (VAD)

Therefore:

| Responsibility            | Layer                              |
| ------------------------- | ---------------------------------- |
| UI / Button state         | Flutter                            |
| ElevenLabs HTTP streaming | Flutter                            |
| Audio playback            | Android (MediaPlayer / AudioTrack) |
| Microphone capture        | Android (AudioRecord)              |
| Voice detection           | Android (VAD loop)                 |
| Barge-in trigger          | Android → Flutter                  |

---

## 🔊 Audio Flow

### TTS Playback (Free Tier)

1. Flutter requests ElevenLabs TTS (`audio/mpeg`)
2. MP3 bytes are streamed to Android
3. Android buffers MP3 to a temporary file
4. `MediaPlayer` plays the file

### Barge-In Detection

1. `AudioRecord` captures microphone input
2. RMS / amplitude-based VAD runs in a background thread
3. Sustained human speech triggers barge-in
4. Playback stops immediately
5. Flutter UI is notified

---

## 🛑 What triggers barge-in

**✔ Triggers**

* Real human speech
* Sustained voice energy
* Microphone input only

**❌ Does NOT trigger**

* Button taps
* ElevenLabs voice output
* System sounds

---

## 🚀 How to Build & Run

### 1️⃣ Flutter setup

```bash
flutter pub get
```

### 2️⃣ Android permissions

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 3️⃣ Run on device (recommended)

⚠️ Emulator microphone latency may cause false negatives

---

## 🎛️ Configuration Options

### Barge-in sensitivity (Android)

```kotlin
private val amplitudeThreshold = 1200
private val minSpeechFrames = 8
```

| Scenario          | Suggested Change       |
| ----------------- | ---------------------- |
| Too sensitive     | Increase threshold     |
| Too slow          | Reduce minSpeechFrames |
| Noisy environment | Increase both          |

---

## 🔐 ElevenLabs API Notes

* Free tier streams **MP3 only**
* Paid tier can stream **raw PCM** (lower latency)
* No model configuration required in dashboard
* Voice choice does **not** affect barge-in behavior

---

## ⚠️ Important Technical Decisions

### Why MP3 buffering instead of streaming decode

* Android cannot decode MP3 incrementally without `MediaCodec`
* `MediaPlayer` is stable and widely supported
* Free tier limitation makes PCM unavailable

### Why VAD is native (not Flutter)

Flutter cannot:

* Access low-level microphone buffers
* Use echo cancellation
* Run reliable real-time audio DSP loops

---

## 🏁 Summary

This project provides:

* Production-safe audio lifecycle
* True real-time barge-in
* Flutter-friendly API
* Free-tier compatible ElevenLabs TTS
