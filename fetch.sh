#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

git clone --depth 1 -b v4.10c https://github.com/AFLplusplus/AFLplusplus.git $FUZZER/repo
git clone --depth 1 https://github.com/shioya-lab-public/AceCov.git $FUZZER/repo/acecov
git -C $FUZZER/repo apply $FUZZER/repo/acecov/aflpp.diff
sed -i s@'#define MAP_SIZE_POW2 16'@'#define MAP_SIZE_POW2 17'@g $FUZZER/repo/include/config.h
cp "$FUZZER/acecov.env" "$FUZZER/repo/acecov/.env"

# Fix: CMake-based build systems fail with duplicate (of main) or undefined references (of LLVMFuzzerTestOneInput)
sed -i '{s/^int main/__attribute__((weak)) &/}' $FUZZER/repo/utils/aflpp_driver/aflpp_driver.c
sed -i '{s/^int LLVMFuzzerTestOneInput/__attribute__((weak)) &/}' $FUZZER/repo/utils/aflpp_driver/aflpp_driver.c
cat >> $FUZZER/repo/utils/aflpp_driver/aflpp_driver.c << EOF
__attribute__((weak))
int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size)
{
  // assert(0 && "LLVMFuzzerTestOneInput should not be implemented in afl_driver");
  return 0;
}
EOF

patch -p1 -d "$FUZZER/repo" << EOF
--- a/utils/aflpp_driver/aflpp_driver.c
+++ b/utils/aflpp_driver/aflpp_driver.c
@@ -65,7 +65,7 @@ extern "C" {
 #endif
 
 // AFL++ shared memory fuzz cases
-int                   __afl_sharedmem_fuzzing = 1;
+int                   __afl_sharedmem_fuzzing = 0;
 extern unsigned int  *__afl_fuzz_len;
 extern unsigned char *__afl_fuzz_ptr;
 
@@ -105,7 +105,8 @@ __attribute__((weak)) void __asan_unpoison_memory_region(
 __attribute__((weak)) void *__asan_region_is_poisoned(void *beg, size_t size);
 
 // Notify AFL about persistent mode.
-static volatile char AFL_PERSISTENT[] = "##SIG_AFL_PERSISTENT##";
+// DISABLED to avoid afl-showmap misbehavior
+static volatile char AFL_PERSISTENT[] = "##SIG_AFL_NOT_PERSISTENT##";
 int                  __afl_persistent_loop(unsigned int);
 
 // Notify AFL about deferred forkserver.
EOF
