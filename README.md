# memstorage-timecounter

Memory evaluation and interruptless timers built by Felix Hildebrandt as final thesis for Assambly Development in 2018. The repository is split into two main programs running on an emulator.

> **_NOTE:_** Commentary appears in German.

## Picture

![i8086 Emulator](./img/screenshot_assably.jpg)

## Memory Content Evaluation

The program can search for a specific 8-bit value and counts the occurrence in the memory area of C000H-CFFFH, which is the monitor program of the SBC-86 BIOS. The value can be set with the switches on the emulator. The hits on the search result are to be output on the 7-segment display.

### Search Flow

![Search Program Flow](/img/memory_content_evaluation.png)

## Timer Controlled Counter

The program implements a timer-controlled counter where
a time is to be preset and displayed binary via the emulator switches. Switching on the S7 bit starts the counter in 10ms steps. Switching off the S7 bit stops the time if the final value has not yet been reached already. Due to the interrupt setup, the timer can always be accurate.

### Timer Flow

![Timer Program Flow](/img/timer_controlled_counter.png)

## Tools

- [i8086 Emulator](http://sourceforge.net/projects/i8086emu/): A multi-platform Emulator on SBC-86
