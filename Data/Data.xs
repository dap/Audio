/*
  Copyright (c) 1996 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "Audio_f.h"

float *
Audio_more(Audio *au, int n)
{
 STRLEN sz = n * sizeof(float);
 float  *p = (float *) (SvGROW(au->data,SvCUR(au->data)+sz) + SvCUR(au->data));
 SvCUR(au->data) += sz;
 Zero(p,n,float);
 return p;
}

SV *
Audio_shorts(Audio *au)
{
 SV *tmp = newSVpv("",0);
 STRLEN samp = Audio_samples(au);
 short *p   = (short *) SvGROW(tmp,samp*sizeof(short));
 float *data = (float *) SvPVX(au->data); 
 STRLEN i;
 while (samp--)
  {
   *p++ = float2linear(*data++,16);
  }
 return tmp;
}


void
Audio_tone(Audio *au, float freq, float dur, float amp)
{
 unsigned samp = (int) (dur * au->rate);
 float *buf = Audio_more(au, samp);
 double th  = 0.0;
 double inc = 2*M_PI*freq/au->rate;
 while (samp > 0)
  {
   *buf++ = amp * sin(th);
   th += inc;
   samp--;
  }
}

MODULE = Audio::Data	PACKAGE = Audio::Data	PREFIX = Audio_ 

PROTOTYPES: DISABLE

SV *
Audio_shorts(au)
Audio *	au;

void
Audio_silence(au, time = 0.1)
Audio *	au;
float	time;

void
Audio_tone(au,freq,dur = 0.1, amp = 0.5)
Audio *	au;
float	freq;
float	dur
float	amp

  
void
DESTROY(au)
Audio *	au
PPCODE:
 {
  if (au->comment)
   SvREFCNT_dec(au->comment);
  if (au->data)
   SvREFCNT_dec(au->data);
 }

Audio *
create(class)
char *	class
CODE:
 {
  Audio x;
  Zero(&x,1,Audio);
  x.comment = newSVpv("",0);
  x.data    = newSVpv("",0);
  RETVAL    = &x;
 }
OUTPUT:
  RETVAL

SV *
Audio_comment(au,...)
Audio *		au
CODE:
 {
  if (items > 1)
   sv_setsv(au->comment,ST(1));
  RETVAL = SvREFCNT_inc(au->comment);
 }
OUTPUT:
 RETVAL

IV 
Audio_samples(au)
Audio *		au

float
Audio_duration(au)
Audio *		au

IV
Audio_rate(au,rate = 0)
Audio *	au
IV	rate 

void
Audio_data(au)
Audio *		au
PPCODE:
 {
  if (GIMME & G_ARRAY)
   {
    STRLEN sz;
    int count = 0;
    float *p = (float *) SvPV(au->data,sz);
    while (sz > sizeof(float))
     {
      double d = *p++;
      XPUSHs(sv_2mortal(newSVnv(d)));
      sz -= sizeof(float);
      count++;
     }
    XSRETURN(count);
   }
  else
   {
    XPUSHs(SvREFCNT_inc(au->data));
    XSRETURN(1);
   }
 }

void
Audio_Load(au,fh)
Audio *		au
InputStream	fh

void
Audio_Save(au,fh,comment = NULL)
Audio *		au
OutputStream	fh
char *		comment

BOOT:
 {
  sv_setiv(perl_get_sv("Audio::Data::AudioVtab",1),(IV) AudioVGet());   
 }
