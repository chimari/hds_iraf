# Procedure for correcting echelle format
#
# copyright : A.Tajitsu (2002/5/30)
#
procedure hdsderotate(imlist,outlist,cmplist)
string imlist  {prompt= "input image list "}
string outlist {prompt= "output image list"}
string cmplist {prompt= "comparison list  "}

begin
#
# variables
#
string tmp1,tmp2,tmp3,tmp4,tmp5,tmp6,lcomp,ap_ref
real r_center
int center,xlen
string out,input[100],outfile[100],filelist,filename,temp1,temp2
string cmpfile[100],cmpname,aprefdef
bool sw,sw2
int i,j,k,kmax

#
task    $sed        =$foreign
#
# variables initialize
#

filelist = imlist
out = outlist
lcomp  = cmplist

for(i=1;i<=100;i=i+1)
	{
	input[i]=''
	outfile[i]=''
        cmpfile[i]=''
	}

temp1=mktemp("temp1.")
temp2=mktemp("temp2.in.")
sections( lcomp, option='fullname', >temp1)
sed( 's/.ff.fits//g',temp1 ,> temp2 )
delete(temp1)

k=1
list=temp2
while(fscan(list,cmpname)>0)
	{
	cmpfile[k]=cmpname
	k=k+1
	}
delete(temp2)

#
# variables initialize
#

temp1=mktemp("temp1.")
temp2=mktemp("temp2.in.")
sections( filelist, option='fullname', >temp1)
sed( 's/.fits//g',temp1 ,> temp2 )
delete(temp1)

i=1
list=temp2
while(fscan(list,filename)!=EOF)
	{
	input[i]=filename
	i=i+1
	}
del(temp2)

temp1=mktemp("temp1.")
temp2=mktemp("temp2.out.")
sections( out, option='fullname', >temp1)
sed( 's/.fits//g',temp1 ,> temp2 )
delete(temp1)

i=1
list=temp2
while(fscan(list,filename)!=EOF)
	{
	outfile[i]=filename
	i=i+1
	}
del(temp2)

for(j=1;j<=i-1;j=j+1)
{
printf("Now processing %s -> %s (%d / %d)\n",input[j],outfile[j],j,(i-1))

if(access(outfile[j]//".fits"))
	{
	print(outfile[j]," already exits.\n")
	print("Do you delete it ?<y/n>")
	While(scan(sw)==0) {}
	if(sw)
		imdelete (outfile[j]//".fits",verify-)
	else goto donothing
	}

if(access("database/ap"//input[j]//"0000"))
   delete("database/ap"//input[j]//"0000")

if(access("input[j]"//"0000.imh"))
 imdelete("input[j]"//"0000.imh")
	
    rfits(input[j]//'.fits','*',input[j],datatyp="real")
	
    printf("Is this frame derotated by itself?<y/n> : ")
    while(scan(sw2)==0) {}
    if(sw2){

    imgets(input[j],'i_naxis1')
    xlen=int(imgets.value)
    if(xlen>500) xlen=500
    printf(" i_naxis= %d\n",xlen)
# for normal star
     apall(input[j]//"0000",2,output=input[j]//'.apall',\
      format='multispec',reference='',profile='',\
      interac+,recente+,resize-,\
      edit+,trace+,fittrac+,extract+,extras-,review-,\
      b_funct='chebyshev',b_order=1,b_naver=-3,b_niter=0,\
      b_low_r=3,b_high_=3,b_sample='-10:-6,6:10',\
      width=15,radius=30,thresho=0,\
      peak+,avglimi+,\
      t_niter=2,t_low_r=3,t_high_=3,t_order=3,t_funct='legendre',\
      t_nsum=10,t_step=3,t_nlost=10,t_sampl="*",t_naver=1,t_grow=0,\
      find=yes,llimit=-17,ulimit=17,\
      lower=-250,upper=250,nsubaps=500)
      aprefdef=input[j]//"0000"
     }
     else{
     imgets(input[j],'i_naxis1')
     xlen=int(imgets.value)
     if(xlen>500) xlen=500
     printf(" i_naxis= %d\n",xlen)
# for emission lines
     printf("Please Input Reference Frame (%s) : ",aprefdef)
     if (scan(ap_ref)==0)
     {
         ap_ref=aprefdef
     }
     apall(input[j]//'0000',2,output=input[j]//'.apall',\
      format='multispec',reference=ap_ref,profile=ap_ref,\
      interac-,recente-,resize-,\
      edit-,trace-,fittrac+,extract+,extras-,review-,\
      b_funct='chebyshev',b_order=1,b_niter=3,\
      b_low_r=3,b_high_=3,b_sample='*',\
      t_niter=3,t_low_r=3,t_high_=3,t_order=2,t_funct='legendre',\
      t_nsum=10,t_step=10,\
#      find=no,llimit=-50,ulimit=50,lower=-250,upper=250,nsubaps=500)
      find=no,llimit=-xlen,ulimit=xlen,\
      lower=-xlen/2,upper=xlen/2,nsubaps=xlen)
     }


list='database/ap'//input[j]//'0000'
while(fscan(list,tmp1,tmp2,tmp3,tmp4,tmp5,tmp6)>0)
{
  if(tmp1=='center')
    {
      print(tmp2) | scan(r_center);
    }
}


imgets(input[j],'i_naxis1')
xlen=int(imgets.value)
center=int(r_center+0.5)
print('Now Flipping...')
imcopy(input[j]//'.apall',outfile[j],  >&'dev$null')
#inverse(input[j]//'.apall',outfile[j])
imdel(input[j]//'.apall')
print('Now Trimming...')
#print(center)
#print(xlen)
#print(outfile[j]//'[*,'//250-center//':'//250-center+xlen-1//']')
#imcopy(outfile[j]//'[*,'//250-center//':'//250-center+xlen-1//']',\
#           outfile[j],  >&'dev$null')

print('Now editting the header parameters...')
#hedit(outfile[j],"LTM2_1",0,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"LTM1_2",0,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"CRVAL1",1,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"CRPIX1",1,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"CRVAL2",1,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"CRPIX2",1,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"LTV1",0,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"CDELT1",1,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"CDELT2",0,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"CD1_1",1,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"CD2_2",0,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"LTM1_1",1,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"LTM2_2",0,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"WAT0_001",0,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"WAT1_001",0,del+,add-,ver-,show-,update+)
#hedit(outfile[j],"WAT2_001",0,del+,add-,ver-,show-,update+)

#hedit(outfile[j],"APNUM*",0,del+,add-,ver-,show-,update+)
#display(input[j],1,xcenter=0.3)
#display(outfile[j],1,xcenter=0.7,erase-)

donothing:
}



print("Now derotate Comparison frames...")
#
for(j=1;j<=k-1;j=j+1)
{



if(access("database/ap"//cmpfile[j]//".ff0000"))
   delete("database/ap"//cmpfile[j]//".ff0000")

if(access("cmpfile[j]"//".ff0000.imh"))
 imdelete("cmpfile[j]"//".ff0000.imh")
	
     rfits(cmpfile[j]//'.ff.fits','*',cmpfile[j]//'.ff',datatyp="real")
	
     imgets(cmpfile[j]//".ff",'i_naxis1')
     xlen=int(imgets.value)
     if(xlen>500) xlen=500
     printf(" i_naxis= %d\n",xlen)
# for emission lines
     printf("Please Input Reference Frame (%s) : ",aprefdef)
     if (scan(ap_ref)==0)
     {
         ap_ref=aprefdef
     }
     apall(cmpfile[j]//'.ff0000',2,output=cmpfile[j]//'.apall',\
      format='multispec',reference=ap_ref,profile=ap_ref,\
      interac-,recente-,resize-,\
      edit-,trace-,fittrac+,extract+,extras-,review-,\
      b_funct='chebyshev',b_order=1,b_niter=3,\
      b_low_r=3,b_high_=3,b_sample='*',\
      t_niter=3,t_low_r=3,t_high_=3,t_order=2,t_funct='legendre',\
      t_nsum=10,t_step=10,\
      find=no,llimit=-xlen,ulimit=xlen,\
      lower=-xlen/2,upper=xlen/2,nsubaps=xlen)
#      find=no,llimit=-50,ulimit=50,lower=-250,upper=250,nsubaps=500)



list='database/ap'//cmpfile[j]//'.ff0000'
while(fscan(list,tmp1,tmp2,tmp3,tmp4,tmp5,tmp6)>0)
{
  if(tmp1=='center')
    {
      print(tmp2) | scan(r_center);
    }
}


imgets(cmpfile[j]//".ff",'i_naxis1')
xlen=int(imgets.value)
center=int(r_center+0.5)
print('Now Flipping...')
imcopy(cmpfile[j]//'.apall',cmpfile[j]//'.dc',  >&'dev$null')
imdel(cmpfile[j]//'.apall')
imtrans(cmpfile[j]//'.dc',cmpfile[j]//'.dc',len_blk=4096)
hedit(cmpfile[j]//'.dc',"CRPIX1",1,del+,add-,ver-,show-,update+)
hedit(cmpfile[j]//'.dc',"APNUM*",0,del+,add-,ver-,show-,update+)
hedit(cmpfile[j]//'.dc',"WAT*",0,del+,add-,ver-,show-,update+)
hedit(cmpfile[j]//'.dc',"BAND*",0,del+,add-,ver-,show-,update+)
hedit(cmpfile[j]//'.dc',"DISPAXIS",1,del-,add+,ver-,show-,update+)
print('Now Trimming...')

#print('Now editting the header parameters...')
}

print("This is the end of this procedure...")
#
bye
end
