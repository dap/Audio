#ifdef _AUDIO
VVAR(unsigned char	*,_l2u,V__l2u)
VVAR(short		*,_u2l,V__u2l)
VFUNC(SV *,Audio_shorts,V_Audio_shorts,_((Audio *au)))
VFUNC(long,float2linear,V_float2linear,_((float f,int bits)))
VFUNC(long,float2ulaw,V_float2ulaw,_((float f)))
VFUNC(float,linear2float,V_linear2float,_((long l,int bits)))
VFUNC(float,ulaw2float,V_ulaw2float,_((long u)))
#endif /* _AUDIO */
