##################################################################
# gaoes_mk1d : Seimei GAOES-RV Make 1D spectrum
#  developed by Akito Tajitsu <akito.tajitsu@nao.ac.jp>
###################################################################
procedure gaoes_mk1d(inec,out1d,blaze)
#
file	inec	{prompt= "Input Multi-Order Spectrum"}
file	out1d   {prompt= "Output 1D Spectrum"}
file    blaze   {prompt= "Blaze Function\n"}
file    mask    {prompt= "Mask Image\n"}

int     st_x=70    {prompt= "Start X"}
int     ed_x=4100    {prompt= "End X\n"}

int     blmx_w1=5180    {prompt= "Start Wavelength for Blaze Max fit"}
int     blmx_w2=5910    {prompt= "End Wavelength for Blaze Max fit\n"}

#

begin
string 	inimg, outimg, blz, msk, suf_b, suf_s, suf_n, suf_c, suf_t,\
        adjtmp, vrtmp
bool  trm, aexp
int x1, x2, bw1, bw2
int expt, bexpt
real efact
string temp1


inimg=inec
outimg=out1d

blz=blaze
msk=mask

x1=st_x
x2=ed_x

bw1=blmx_w1
bw2=blmx_w2

suf_t="_t"
suf_b="_b"
suf_s="_sum"
suf_c="_c"
suf_n="_n"

if(access(inimg//suf_t//".fits")){ 
  imdelete(inimg//suf_t)
}
if(access(inimg//suf_t)){ 
  delete(inimg//suf_t)
}
if(access(blz//suf_t//".fits")){ 
  imdelete(blz//suf_t)
}
if(access(blz//suf_t)){ 
  delete(blz//suf_t)
}

printf("##### X Trimming #####\n")
scopy(inimg//"["//x1//":"//x2//",*]", inimg//suf_t)
scopy(blz//"["//x1//":"//x2//",*]", blz//suf_t)


printf("##### Removal Bad Pix #####\n")
if(access(inimg//suf_b//".fits")){ 
  imdelete(inimg//suf_b)
}
if(access(inimg//suf_b)){ 
  delete(inimg//suf_b)
}

sarith(inimg//suf_t, '*', msk, inimg//suf_b)

if(access(blz//suf_b//".fits")){ 
  imdelete(blz//suf_b)
}
if(access(blz//suf_b)){ 
  delete(blz//suf_b)
}
sarith(blz//suf_t, '*', msk, blz//suf_b)


printf("##### Scombine All Orders #####\n")
if(access(inimg//suf_b//suf_s//".fits")){ 
  imdelete(inimg//suf_b//suf_s)
}
if(access(inimg//suf_b//suf_s)){ 
  delete(inimg//suf_b//suf_s)
}
scombine(inimg//suf_b, inimg//suf_b//suf_s,combine="sum",
         group="images",reject="none")

if(access(blz//suf_b//suf_s//".fits")){ 
  imdelete(blz//suf_b//suf_s)
}
if(access(blz//suf_b//suf_s)){ 
  delete(blz//suf_b//suf_s)
}
scombine(blz//suf_b, blz//suf_b//suf_s,combine="sum",
         group="images",reject="none")

if(access(blz//suf_b//suf_s//suf_c//".fits")){ 
  imdelete(blz//suf_b//suf_s//suf_c)
}
if(access(blz//suf_b//suf_s//suf_c)){ 
  delete(blz//suf_b//suf_s//suf_c)
}
continuum(blz//suf_b//suf_s,blz//suf_b//suf_s//suf_c,type='fit',\
	function='spline3',order=1,interac-,sample=bw1//':'//bw2,\
	ask='YES')

if(access(blz//suf_b//suf_s//suf_n//".fits")){ 
  imdelete(blz//suf_b//suf_s//suf_n)
}
if(access(blz//suf_b//suf_s//suf_n)){ 
  delete(blz//suf_b//suf_s//suf_n)
}
sarith(blz//suf_b//suf_s,"/",blz//suf_b//suf_s//suf_c,\
	blz//suf_b//suf_s//suf_n)

printf("##### Make 1D Spectrum #####\n")

sarith(inimg//suf_b//suf_s,"/",blz//suf_b//suf_s//suf_n,outimg)
imgets(inimg,'EXPTIME')
expt=int(imgets.value)

hedit(outimg,"EXPTIME",expt,del-,add-,ver-,show+,update+)
hedit(outimg,'G_MASK', msk,add+,del-, ver-,show-,update+)
hedit(outimg,'G_BLAZE',blz,add+,del-, ver-,show-,update+)

printf("## Created : %s   ... done\n",outimg)

bye
end
