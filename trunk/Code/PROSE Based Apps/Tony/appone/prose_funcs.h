#ifndef _PROSE_FUNCS_H_
#define _PROSE_FUNCS_H_

#include <defines.h>

extern void PrintAt(UINT8 x, UINT8 y, char *msg);
extern void WaitMillis(int millis);
extern void WaitForKey(void);
extern void PrintHex2(UINT8 bin);
extern void PrintHex4(UINT16 bin);
extern void PrintHex6(UINT24 bin);
extern void PrintHex8(UINT32 bin);

#endif // _PROSE_FUNCS_H_