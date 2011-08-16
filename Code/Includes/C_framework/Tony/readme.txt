
libez80.lib should be linked with your app. It also includes the .h file
required by your app. Finally, it also includes "testing.xls" which
indicates which of the OS calls have currently been tested (a large
chunk, but not all currently).

cstartup.asm required by your app (also included in the
demo app) - this sets up the correct segments etc, and injects a PROSE header
as required for .ezp files. It's hard-coded to ADL
mode, no version requirements, but can be modified per-project as needed.

See "code/prose_based_apps/tony" for a simple test program "appone". A word of
caution: The test app mucks about with your RTC (although it does attempt to
restore it, you may lose some seconds, or it may fail totally requiring a
manual clock reset!). It also creates a directory in the root of your SD
card, as well as a file for test purposes. It will delete them after it's
finished.

Still early days, but hopefully this should make life easier for the C
coder. Feedback welcomed.

I have noticed a couple of things - sometimes the PROSE calls will fail, but
the trace from the test shows an error code of $00 which is weird as the
test condition also indicates a none-zero value (if (PROSE_Result) ...
causes code to be executed).

Essentially, many of the calls require pointers to variables to be passed to
them to receive their responses. In other cases, a BOOL or pointer will be
returned (see the .h or demo for details). In all cases, a non-zero return
value will cause the accumulator to be stored in global var PROSE_Result
which should give the error code.

Will carry on working on this, but thought it was at least semi-usable now.
