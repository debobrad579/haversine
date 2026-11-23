#include <stdint.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <x86intrin.h>

typedef double f64;
typedef unsigned long long u64;

static u64 GetOSTimerFreq() { return 1000000; }

static u64 ReadOSTimer() {
  struct timeval Value;
  gettimeofday(&Value, 0);

  u64 Result = GetOSTimerFreq() * (u64)Value.tv_sec + (u64)Value.tv_usec;
  return Result;
}

u64 GetRDTSC(void) { return __rdtsc(); }

u64 EstimateCPUFrequency(u64 MillisecondsToWait) {
  u64 OSFreq = GetOSTimerFreq();
  u64 CPUStart = __rdtsc();
  u64 OSStart = ReadOSTimer();

  u64 OSEnd = 0;
  u64 OSElapsed = 0;
  u64 OSWaitTime = OSFreq * MillisecondsToWait / 1000;
  while (OSElapsed < OSWaitTime) {
    OSEnd = ReadOSTimer();
    OSElapsed = OSEnd - OSStart;
  }

  u64 CPUEnd = __rdtsc();
  u64 CPUElapsed = CPUEnd - CPUStart;

  if (OSElapsed == 0) {
    return 0;
  } else {
    return OSFreq * CPUElapsed / OSElapsed;
  }
}

u64 ReadOSPageFaultCount(void) {
  struct rusage Usage = {};
  getrusage(RUSAGE_SELF, &Usage);

  u64 Result = Usage.ru_minflt + Usage.ru_majflt;

  return Result;
}
