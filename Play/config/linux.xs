#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

/*****************************************************************/
/***                                                           ***/
/***    Play out a file on Linux                               ***/
/***                                                           ***/
/***                H.F. Silverman 1/4/91                      ***/
/***    Modified:   H.F. Silverman 1/16/91 for amax parameter  ***/
/***    Modified:   A. Smith 2/14/91 for 8kHz for klatt synth  ***/
/***    Modified:   Rob W. W. Hooft (hooft@EMBL-Heidelberg.DE) ***/
/***                adapted for linux soundpackage Version 2.0 ***/
/***    Merged FreeBSD version - 11/11/94 NIS                  ***/
/***    Perl Port - 27/01/97 NIS                               ***/
/***                                                           ***/
/*****************************************************************/


#include <fcntl.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <sys/ioctl.h>

#ifdef HAVE_SYS_SOUNDCARD_H
/* linux style */
#include <sys/soundcard.h>
#endif

#ifdef HAVE_MACHINE_SOUNDCARD_H
/* FreeBSD style */
#include <machine/soundcard.h>
#endif

/* Nested dynamic loaded extension magic ... */
#include "../../Data/Audio.m"  
AudioVtab     *AudioVptr;

/* file descriptor for audio device */


#if defined(HAVE_DEV_DSP) || !defined(HAVE_DEV_SBDSP)
static char *dev_file = "/dev/dsp";
#else
#if defined(HAVE_DEV_SBDSP)
static char *dev_file = "/dev/sbdsp";
#endif
#endif

#define SAMP_RATE 8000

typedef struct
{
 long samp_rate;
 int fd;
 float gain;
} play_audio_t;

static int
audio_init(play_audio_t *dev,int wait)
{
 dev->samp_rate = SAMP_RATE;
 dev->fd = open(dev_file, O_WRONLY | O_NDELAY);
 if (dev->fd < 0)
  {
   return 0;
  }
 return 1;
}

IV
audio_rate(play_audio_t *def, IV rate)
{IV old = dev->samp_rate;
 if (rate)
  {
   dev->samp_rate = rate;
   ioctl(dev->fd, SNDCTL_DSP_SPEED, &dev->samp_rate);
  }
 return old;
}

void
audio_flush(play_audio_t *dev)
{
 if (dev->fd >= 0)
  {
   int dummy;                              
   ioctl(dev->fd, SNDCTL_DSP_SYNC, &dummy);
  }
} 

void
audio_DESTROY(play_audio_t *dev)
{
 audio_flush(dev);
 /* Close audio system  */
 if (dev->fd >= 0)
  {
   close(dev->fd);
   dev->fd = -1;
  }
}

void
audio_play16(play_audio_t *dev,int n, short *data)
{
 if (n > 0)
  {
   unsigned char *converted = (unsigned char *) malloc(n);
   int i;

   if (converted == NULL)
    {
     croak("Could not allocate memory for conversion\n");
    }

   for (i = 0; i < n; i++)
    converted[i] = (data[i] - 32768) / 256;

   if (dev->fd >= 0)
    {
     if (write(dev->fd, converted, n) != n)
      perror("write");
    }
   free(converted);
  }
}

float
audio_gain(play_audio_t *dev,float gain)
{
 float prev_gain = dev->gain;
 if (gain >= 0.0)
  {
   if (gain != 1.0)
    warn("Cannot change audio gain");
   /* If you can tell me how,
      otherwise we could multiply out during conversion to short.
      ... NI-S 
   */
  }
 return prev_gain;
}

/*
   API level Play function 
    - volume may go from the interface - it is un-natural
    - convert to 'short' should be done at Audio::Play level 
    - likewise rate-matching needs to be higher level
*/
void
audio_play(play_audio_t *dev, Audio *au, float volume)
{
 STRLEN samp = Audio_samples(au);
 SV *tmp = Audio_shorts(au);
 if (volume >= 0)
  audio_gain(dev, volume);

 if (au->rate != audio_rate(dev,0))
  audio_rate(dev, au->rate);           /* Or re-sample to dev's rate ??? */

 audio_play16(dev, samp, (short *) SvPVX(tmp));
 SvREFCNT_dec(tmp);
}

MODULE = Audio::Play::#OSNAME#	PACKAGE=Audio::Play::#OSNAME#	PREFIX = audio_

PROTOTYPES: DISABLE

play_audio_t *
audio_new(class,wait = 1)
char *	class
IV	wait
CODE:
 {static play_audio_t buf;
  if (!audio_init(RETVAL = &buf,wait))
   {
    XSRETURN_NO;
   }
 }
OUTPUT:
 RETVAL

void
audio_DESTROY(dev)
play_audio_t *	dev

void
audio_flush(dev)
play_audio_t *	dev

double
audio_gain(dev,val = -1.0)
play_audio_t *	dev
double	val

IV
audio_rate(dev,rate = 0)
play_audio_t *	dev
IV	rate

void
audio_play(dev, au, vol = -1.0)
play_audio_t *	dev
Audio *		au;
float		vol

BOOT:
 {
  /* Nested dynamic loaded extension magic ... */
  AudioVptr = (AudioVtab *) SvIV(perl_get_sv("Audio::Data::AudioVtab",5)); 
 }
