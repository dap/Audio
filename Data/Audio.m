#ifndef _AUDIO_VM
#define _AUDIO_VM
#include "Audio_f.h"
#define _l2u (*AudioVptr->V__l2u)
#define _u2l (*AudioVptr->V__u2l)
#define Audio_shorts (*AudioVptr->V_Audio_shorts)
#define float2linear (*AudioVptr->V_float2linear)
#define float2ulaw (*AudioVptr->V_float2ulaw)
#define linear2float (*AudioVptr->V_linear2float)
#define ulaw2float (*AudioVptr->V_ulaw2float)
#endif /* _AUDIO_VM */
