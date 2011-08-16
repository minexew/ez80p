appone is a sample (test) application for the C framework. A word of
caution: The test app mucks about with your RTC (although it does attempt to
restore it, you may lose some seconds, or it may fail totally requiring a
manual clock reset!). It also creates a directory in the root of your SD
card, as well as a file for test purposes. It will delete them after it's
finished.