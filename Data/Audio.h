#ifndef _AUDIO
#define _AUDIO
typedef struct
 {
  unsigned long rate;
  SV *data;
  SV *comment;
 } Audio;

#define InputStream PerlIO *
#define OutputStream PerlIO *

#define Audio_samples(au) (SvCUR((au)->data)/sizeof(float))
#define Audio_duration(au) ((float) Audio_samples(au)/(au)->rate)
#define Audio_silence(au,t) Audio_more(au,(int) (t*(au)->rate))

extern short		*_u2l;		/* 8-bit u-law to 16-bit PCM */
extern unsigned char	*_l2u;		/* 13-bit PCM to 8-bit u-law */
#define	ulaw2short(X)	(_u2l[(unsigned char) (X)])
#define	short2ulaw(X)	(_l2u[((short)(X)) >> 3])
extern long float2ulaw _((float f));
extern float ulaw2float _((long u));
extern long float2linear _((float f,int bits));
extern float linear2float _((long l,int bits));
extern SV * Audio_shorts _((Audio *au));
#endif /* _AUDIO */
