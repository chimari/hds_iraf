##################################################################
# grql : Seimei GAOES-RV Quick Look Script 
#  developed by Akito Tajitsu <akito.tajitsu@nao.ac.jp>
#              2023.05.09 ver.0.40
#              2022.10.25 ver.0.01
###################################################################
procedure grql(inid)
### Input parameters
 string inid {prompt = 'Input frame ID'}
 string indirec {prompt = 'directory of RAW data\n'}

 bool  batch=no {prompt = 'Batch Mode?'}
 file  inlist {prompt = 'Input file list for batch-mode\n'}
 
 bool interactive=yes {prompt ="Run task interactively? (yes/no)\n"}

 string ref_ap {prompt= "Aperture reference image"}
 string flatimg {prompt= "ApNormalized flat image"}
 string thar1d  {prompt= "1D wavelength-calibrated ThAr image"}
 string thar2d  {prompt= "2D ThAr image\n"}

 int st_x=-54  {prompt ="Start pixel to extract"}
 int ed_x=53  {prompt ="End pixel to extract\n"}

 bool   cosmicra=no {prompt = 'Cosmic Ray Rejection?'}
 bool   scatter=no {prompt = 'Scattered Light Subtraction?'}
 bool   ecfw=no {prompt = 'Extract / Flat-fielding / Wavelength calib.?'}
 bool   getcnt=no  {prompt = 'Measure spectrum count?'}
 bool   mk1d=no  {prompt = 'Make order combined 1d spectrum?'}
 bool   splot=no    {prompt = 'Splot Spectrum?\n\n### Cosmic-Ray Rejection. ###'}

# Parameters for overscan

# Parameters for cosmicray-event rejection
 string cr_proc="wacosm" {prompt = 'CR rejection procedure (wacosm|lacos)?\n### Parameters for wacosm11 ###', enum="wacosm|lacos"}
 real   cr_wbase=2000  {prompt = 'Baseline for wacosm11\n### Parameters for lacos_spec ###'}
 bool   cr_ldisp=no {prompt = 'Confirm w/Display? (need DS9)'}
 real   cr_lgain=1.67  {prompt = 'gain (electron/ADU)'}
 real   cr_lreadn=4.4  {prompt = 'read noise (electrons)'}
 int    cr_lxorder=9  {prompt = 'order of object fit (0=no fit)'}
 int    cr_lyorder=3  {prompt = 'order of sky line fit (0=no fit)'}
 real   cr_lclip=10.  {prompt = 'detection limit for cosmic rays(sigma)'}
 real   cr_lfrac=3.  {prompt = 'fractional detection limit fro neighbouring pix'}
 real   cr_lobjlim=5.  {prompt = 'contrast limit between CR and underlying object'}
 int   cr_lniter=4  {prompt = 'maximum number of iterations\n\n### Scattered-light Subtraction ###'}

# scattered light subtraction
 bool   sc_inter=yes {prompt = 'Run apscatter interactively?\n\n### Get Spectrum Count. ###'}

# Parameters for Get Spectrum Count
 int ge_line=2 {prompt = 'Order line to get count'}
 int ge_stx=2150  {prompt ="Start pixel to get count"}
 int ge_edx=2400  {prompt ="End pixel to get count"}
 real ge_low=1.0  {prompt ="Low rejection in sigma of fit"}
 real ge_high=0.0   {prompt ="High rejection in sigma of fit\n\n### Make 1D spectrum ###"}

 string m1_blaze {prompt = 'Blaze Function'}
 string m1_mask {prompt = 'Mask Image'}
 int m1_stx=2 {prompt = 'Start X for trimming'}
 int m1_edx=4096 {prompt = 'Endt X for trimming\n\n### Splot ###'}
 
#splot
 int sp_line=1 {prompt = 'Splot image line/aperture to plot\n'}
 bool   clean=no {prompt = 'Clean up intermediate images? (yes/no)'}

# Extract / Flat fielding / Wavecalib

begin
string version="0.40 (05-09-2023)"
string input_id, tmp_inid
string apref, flt, thar1, thar2

int batch_n, batch_i, end_la
string temp_id
bool d_ans,ap_done, do_flag

string input, input0, output

string flag
string crfile, osfile, scfile, ecfile,nextin, crinfile, batch_id[2000]

string temp1, temp2, temp3
int mean_cnt, max_cnt, cont_cnt
string cnt_out, m1file

apref=ref_ap
flt=flatimg
thar1=thar1d
thar2=thar2d

if(batch){
  list=inlist
  batch_n=0

  printf("\n############################################\n")
  printf("###   Starting grql in Batch Mode\n")
  printf("############################################\n")
  printf("  Input files are...\n")
  while(fscan(list,temp_id)==1){
    printf("   %s/GRA%s\n",indirec,temp_id)
    batch_n=batch_n+1
    batch_id[batch_n]=temp_id
  }

  printf(" Total frame number=%d.\n",batch_n)
  if(interactive){
    printf(">>> Do you want to start Batch mode? (y/n) : ")
    while(scan(d_ans)!=1) {}
    if(!d_ans){
      printf("!!! ABORT !!!\n")
      bye
    }
  }

  list=inlist
}

do_flag=yes
batch_i=1
while(do_flag){

if(batch){
  if(batch_i<batch_n+1){
    input_id=batch_id[batch_i]
    printf("\n##########################\n")
    printf("###   Batch Mode\n")
    printf("###     Input ID = %s\n", input_id)
    printf("##########################\n\n")
  }
  else{
    do_flag=no
    bye
  }
}
else{
  input_id=inid
}

output  = "G"//input_id
printf("output ID : %s\n", output)

input=indirec//"/GRA"//input_id//".fits"
printf("input data= %s\n", input)

nextin=input


# overscan
  printf("\n")
  printf("##################################\n")
  printf("# [1/4] Overscan\n")
  printf("##################################\n")

  flag="o"
  osfile=(output+flag)

  if((access(osfile))||access(osfile//".fits")){
     printf("*** OverScanned file \"%s\" already exsits!!\n",osfile)
     printf("*** Automatcally Rmoving \"%s\" ...\n",osfile)
     imdelete(osfile)
     if(access(osfile//".fits")) delete(osfile//".fits")
  }

  printf(" output overscaned data= %s\n", osfile)
  print("# Overscan is now processing...")
  gaoes_overscan(inimage=nextin,outimage=osfile)
  hedit(osfile,'GRQL_OS',"done",add+,del-, ver-,show-,update+)
  nextin=osfile


# wacosm11
if (cosmicra){
   printf("\n")
   printf("##################################\n")
   printf("# [2/4] Cosmic Ray Rejection\n")
   printf("##################################\n")

   if (cr_proc == "lacos"){
     flag=flag+"C"
     printf("### Using lacos_spec for CR Rejection ###\n")
   }else{
     flag=flag+"c"
     printf("### Using wacosm for CR Rejection ###\n")
   }
   crfile=(output+flag)

   if((access(crfile))||access(crfile//".fits")){
     printf("*** Cosmic Ray Rjected file \"%s\" already exsits!!\n",crfile)
     printf("*** Automatcally Rmoving \"%s\" ...\n",crfile)
     imdelete(crfile)
     if(access(crfile//".fits")) delete(crfile//".fits")
   }

   crinfile=nextin
#

   if (cr_proc == "lacos"){
### LACOSM:
     end_la=0
     while(end_la == 0){
       print("# lacos_spec is now processing...")
       printf("### If failed, load STSDAS then retry ###\n")
       if((access(crinfile//"_badpix"))||access(crinfile//"_badpix"//".fits")){
          imdelete(crinfile//"_badpix")
          if(access(crinfile//"_badpix"//".fits")) delete(crinfile//"_badpix"//".fits")
       }
       lacos_spec(crinfile,crfile,crinfile//"_badpix",
         gain=ls_gain,readn=ls_readn,xorder=ls_xorder,yorder=ls_yorder,
         sigclip=ls_sigclip,sigfrac=ls_sigfrac,objlim=ls_objlim,
         niter=ls_niter,ver+)
       if(cr_ldisp){
         display(crinfile,1)
         display(crfile,2)
         display(crinfile//"_badpix",3)
         printf("# Displaying [1]IN  [2]OUT  [3]BadPix ...\n")     
         printf("# If you want to compare please tile them in your DS9\n")     
         printf(">>> OK to go to the next step? (y/n) : ")     
         while(scan(la_ans)!=1) {}
         if(!la_ans){
           printf(">>> Input New Xorder (%d) : ",ls_xorder) 
           while( scan(ans_int) == 0 )
           print(ans_int)
           ls_xorder=ans_int
           printf(">>> Input New Yorder (%d) : ",ls_yorder) 
           while( scan(ans_int) == 0 )
           print(ans_int)
           ls_yorder=ans_int
           printf(">>> Input New SigClip (%.2f) : ",ls_sigclip) 
           while( scan(ans_real) == 0 )
           print(ans_real)
           ls_sigclip=ans_real
           printf(">>> Input New SigFrac (%.2f) : ",ls_sigfrac) 
           while( scan(ans_real) == 0 )
           print(ans_real)
           ls_sigfrac=ans_real
           printf(">>> Input New ObjLim (%.2f) : ",ls_objlim) 
           while( scan(ans_real) == 0 )
           print(ans_real)
           ls_objlim=ans_real

           imdelete(crfile)
###         goto LACOSM
         }
	 else{
	   end_la=1
	 }
       }
       else{
         end_la=1
       }
     }
   }
   else{
# wacosm
     print("# wacosm11 is now processing...")
     wacosm11 (in_f=crinfile,out_f=crfile,base=cr_wbase)
  }
  hedit(crfile,'GRQL_CR',"done",add+,del-, ver-,show-,update+)
  nextin=crfile
}
else {
   print("CR rejection not processing")     
}


# scattered light subtraction
if (scatter){
  printf("\n")
  printf("##################################\n")
  printf("# [3/4] Scattered Light Subtraction\n")
  printf("##################################\n")

  flag=flag+"s"	
  scfile=(output+flag)

  if((access(scfile))||access(scfile//".fits")){
     printf("*** Scattered Light Subtracted file \"%s\" already exsits!!\n",scfile)
     printf("*** Automatcally Rmoving \"%s\" ...\n",scfile)
     imdelete(scfile)
     if(access(scfile//".fits")) delete(scfile//".fits")
  }
#

  printf("# Resizing aperture size of \"%s\"......\n", apref)
  apresize(apref,refer=" ",llimit=st_x, ulimit=ed_x, ylevel=INDEF,\
    find-, resize+, interac-)

  print("# Scattered light subtracting is now processing...")
  apscatter(nextin,scfile,interac=sc_inter,referen=apref,recente-,resize-,\
    edit-,trace-,fittrac=sc_inter)
  hedit(scfile,'GRQL_SC',"done",add+,del-, ver-,show-,update+)
  nextin=scfile
}

# extract / flat fielding / wavelength calibration
if(ecfw){
  printf("\n")
  printf("######################################################\n")
  printf("# [4/4] Flat Fielding / Extraction / Wavelength Calib.\n")
  printf("######################################################\n")

  flag=flag+"_ecfw"	
  ecfile=(output+flag)
  printf(" output extracted, flatted, wavelength calibrated data= %s\n", ecfile)

  if((access(ecfile))||access(ecfile//".fits")){
     printf("*** Extracted / Flat Fielded / Wavelength calibrated file \"%s\" already exsits!!\n",ecfile)
     printf("*** Automatcally Rmoving \"%s\" ...\n",ecfile)
     imdelete(ecfile)
     if(access(ecfile//".fits")) delete(ecfile//".fits")
  }

  printf("# Extraction / Flat fielding / Wavelength calibration is now processing...")
  gaoes_ecfw(nextin,ecfile,ref_ap=apref, flatimg=flt,thar1d=thar1, \
   thar2d=thar2, st_x=st_x,ed_x=ed_x, clean=clean)
  hedit(ecfile,'GRQL_EC',"done",add+,del-, ver-,show-,update+)
  hedit(ecfile,'G_APREF',apref,add+,del-, ver-,show-,update+)
  hedit(ecfile,'G_FLAT',flt,add+,del-, ver-,show-,update+)
  hedit(ecfile,'G_THAR1D',thar1,add+,del-, ver-,show-,update+)
  hedit(ecfile,'G_THAR2D',thar2,add+,del-, ver-,show-,update+)
  nextin=ecfile
  ap_done=yes
}
else{
  ap_done=no
}

printf("\n")
printf("##############################################################\n")
printf("# grql : FINISH\n")
printf("#   ver %s developped by A.Tajitsu\n",version)
printf("#\n")
printf("#  Resultant File :   %s%s.fits\n",output,flag)
printf("##############################################################\n")

#endofp:

if (getcnt && ap_done){
  getcount(nextin,"G"//input_id//"_cnt",ge_line=ge_line,ge_stx=ge_stx,ge_edx=ge_edx,ge_high=ge_high,ge_low=ge_low,ask="no")
}

if(mk1d){
  flag=flag+"_1d"	
  m1file=(output+flag)
  gaoes_mk1d(nextin,m1file,blaze=m1_blaze,mask=m1_mask,st_x=m1_stx,ed_x=m1_edx)
  if(batch){
   batch_i=batch_i+1
  }
  else{
    if (splot && ap_done){
        splot (images=output//flag,line=1,band=1)
    }
    do_flag=no
    bye
  }
}
else{
  if(batch){
   batch_i=batch_i+1
  }
  else{
    if (splot && ap_done){
       splot (images=output//flag,line=sp_line,band=1)
    }
    do_flag=no
    bye
  }
}
}

bye
end
