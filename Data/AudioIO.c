#include <EXTERN.h>
#include <perl.h>
#include "Audio.h"

#define SUN_MAGIC 	0x2e736e64		/* Really '.snd' */
#define SUN_HDRSIZE	24			/* Size of minimal header */
#define SUN_UNSPEC	((unsigned)(~0))	/* Unspecified data size */
#define SUN_ULAW	1			/* u-law encoding */
#define SUN_LIN_8	2			/* Linear 8 bits */
#define SUN_LIN_16	3			/* Linear 16 bits */

static void wblong _((PerlIO *f, long x));
static long rblong _((PerlIO *f, int n));

static void 
wblong(f, x)
PerlIO *f;
long x;
{
 int i;
 for (i = 24; i >= 0; i -= 8)
  {
   char byte = (char) ((x >> i) & 0xFF);
   PerlIO_write(f, &byte, 1);
  }
}

static long
rblong(f,n)
PerlIO *f;
int n;
{
 long x = 0;
 int i;
 for (i=0; i < n; i++)
  {
   long b = PerlIO_getc(f);
   x = (x <<= 8) + (b & 0xFF);
  }
 return x;
}

extern void Audio_header _((PerlIO *f,unsigned enc,unsigned rate,unsigned size,char *comment));

void 
Audio_header(f, enc, rate, size, comment)
PerlIO *f;
unsigned enc;
unsigned rate;
unsigned size;
char *comment;
{
 if (!comment)
  comment = "";
 wblong(f, SUN_MAGIC);
 wblong(f, SUN_HDRSIZE + strlen(comment));
 wblong(f, size);
 wblong(f, enc);
 wblong(f, rate);
 wblong(f, 1);                   /* channels */
 PerlIO_write(f, comment, strlen(comment));
}

static long Audio_write _((PerlIO *f, int au_format, int n,float *data));

static long 
Audio_write(f, au_encoding, n, data)
PerlIO *f;
int au_encoding;
int n;
float *data;
{
 long au_size = 0;
 if (n > 0)
  {
   if (au_encoding == SUN_LIN_16)
    {
     while (n--)
      {
       short s = float2linear(*data++,16);
       if (PerlIO_write(f, &s, sizeof(s)) != sizeof(s))
        au_size += sizeof(s);
      }
    }
   else if (au_encoding == SUN_ULAW)
    {
     while (n--)
      {
       char s = float2ulaw(*data++);
       if (PerlIO_write(f, &s, sizeof(s)) != sizeof(s))
        au_size += sizeof(s);
      }
    }
   else if (au_encoding == SUN_LIN_8)
    {
     while (n--)
      {
       char s = float2linear(*data++,8);
       if (PerlIO_write(f, &s, sizeof(s)) != sizeof(s))
        au_size += sizeof(s);
      }
    }
   else
    {
     croak("Unknown format");
    }
  }
 return au_size;
}

static void Audio_term _((PerlIO *f,long au_size));

static void
Audio_term(f,au_size)
PerlIO *f;
long au_size;
{
 off_t here = PerlIO_tell(f);
 PerlIO_flush(f);
 if (here >= 0)
  {
   /* can seek this file - truncate it */
   ftruncate(PerlIO_fileno(f), here);
   /* Now go back and overwite header with actual size */
   if (PerlIO_seek(f, 8L, SEEK_SET) == 8)
    {
     wblong(f, au_size);
    }
  }
}

static void
Audio_read(Audio *au, PerlIO *f,size_t dsize,long count,float (*proc)(long))
{
 SV *data = au->data;
 if (count > 0)
  {
   /* If we know how big it is to be get grow out of the way */
   SvGROW(data,SvCUR(data)+(count/dsize)*sizeof(float));
  }
 while (count && !PerlIO_eof(f))
  {
   STRLEN len = SvCUR(data);
   long  v  = rblong(f,dsize);
   float *p = (float *) (SvGROW(data,len+sizeof(float))+len);
   if (proc)
    *p = (*proc)(v);
   else
    *p = linear2float(v, dsize*8);
   len += sizeof(float);
   SvCUR(data) = len;
   count -= dsize;
  }
}

static void 
sun_load(Audio *au, PerlIO *f, long magic)
{
 long hdrsz = rblong(f,sizeof(long));
 long size  = rblong(f,sizeof(long));
 long enc   = rblong(f,sizeof(long));
 long rate  = rblong(f,sizeof(long));
 long chan  = rblong(f,sizeof(long));
 int dsize   = 1;
 au->rate   = rate;
 hdrsz -= SUN_HDRSIZE;
 if (!au->comment)
  au->comment = newSVpv("",0); 
 if (!au->data)
  au->data    = newSVpv("",0); 
 PerlIO_read(f,SvGROW(au->comment,hdrsz),hdrsz);
 SvCUR(au->comment) = hdrsz;
 switch(enc)
  {
   case SUN_ULAW:
    Audio_read(au,f,1,size,ulaw2float);
    break;
   case SUN_LIN_16:
    Audio_read(au,f,2,size,NULL);
    break;
   case SUN_LIN_8: 
    Audio_read(au,f,1,size,NULL);
    break;
   default:
    croak("Unsupported au format");
    break;
  }
}

void
Audio_Load(Audio *au, InputStream f)
{
 long magic = rblong(f,sizeof(long));
 switch(magic)
  {
   case SUN_MAGIC:
    sun_load(au, f, magic);
    break;
   default:
    croak("Unknown file format");
    break;
  }
}

void
Audio_Save(Audio *au, OutputStream f, char *comment)
{
 long encoding = (au->rate == 8000) ? SUN_ULAW : SUN_LIN_16;
 long bytes  = Audio_samples(au);
 if (encoding != SUN_ULAW)
  bytes *= 2; 
 if (!comment && au->comment)
  comment = SvPV(au->comment,na);
 Audio_header(f, encoding, au->rate, bytes, comment);
 bytes = Audio_write(f, encoding, Audio_samples(au), (float *) SvPVX(au->data));
 Audio_term(f, bytes);
}


