#pragma once
// Local string adapter for the upstream entry points. No JVM is embedded.
#include <deque>
#include <string>
using jstring = const char*;
using jclass = void*;
using jint = int;
#define JNIEXPORT
#define JNICALL
struct JNIEnv {
    std::deque<std::string> strings;
    const char* GetStringUTFChars(jstring s, void*) { return s ? s : ""; }
    void ReleaseStringUTFChars(jstring, const char*) {}
    jstring NewStringUTF(const char* s) {
        strings.emplace_back(s ? s : "");
        return strings.back().c_str();
    }
};
