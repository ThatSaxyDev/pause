#include <jni.h>

namespace {
JavaVM* g_vm = nullptr;

JNIEnv* envForCurrentThread(bool* didAttach) {
  *didAttach = false;
  JNIEnv* env = nullptr;
  if (g_vm == nullptr) return nullptr;
  const jint state = g_vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
  if (state == JNI_EDETACHED) {
    if (g_vm->AttachCurrentThread(&env, nullptr) != JNI_OK) return nullptr;
    *didAttach = true;
  } else if (state != JNI_OK) {
    return nullptr;
  }
  return env;
}

jboolean callBooleanStatic(const char* method) {
  bool didAttach = false;
  JNIEnv* env = envForCurrentThread(&didAttach);
  if (env == nullptr) return JNI_FALSE;
  jclass activity = env->FindClass("com/pauseapp/pause_mobile/MainActivity");
  if (activity == nullptr) {
    env->ExceptionClear();
    if (didAttach) g_vm->DetachCurrentThread();
    return JNI_FALSE;
  }
  jmethodID target = env->GetStaticMethodID(activity, method, "()Z");
  if (target == nullptr) {
    env->ExceptionClear();
    env->DeleteLocalRef(activity);
    if (didAttach) g_vm->DetachCurrentThread();
    return JNI_FALSE;
  }
  const jboolean result = env->CallStaticBooleanMethod(activity, target);
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    env->DeleteLocalRef(activity);
    if (didAttach) g_vm->DetachCurrentThread();
    return JNI_FALSE;
  }
  env->DeleteLocalRef(activity);
  if (didAttach) g_vm->DetachCurrentThread();
  return result;
}
}  // namespace

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  g_vm = vm;
  return JNI_VERSION_1_6;
}

extern "C" JNIEXPORT jboolean JNICALL pause_guard_open_notification_access() {
  return callBooleanStatic("openPauseGuardNotificationAccess");
}

extern "C" JNIEXPORT jboolean JNICALL pause_guard_is_notification_access_granted() {
  return callBooleanStatic("isPauseGuardNotificationAccessGranted");
}
