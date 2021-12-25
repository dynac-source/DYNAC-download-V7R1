        PROGRAM PTQ2DYN
c *******************************************************************************************************************************
c **********************Conversion from PARMTEQ style RFQ data to DYNAC style RFQ data ******************************************
c *******************************************************************************************************************************
c ********************************************** V2.1 03-May-2017 ***************************************************************
c *******************************************************************************************************************************
c ******************************************** E.Tanke and S.Valero *************************************************************
c *******************************************************************************************************************************
c --- Generate an RFQ desription as input file to Dynac
c --- Input to PTQ2DYN can be one of the two following:
c --- a)   .ASC parmteq input file
c --- b)   .DAT parmteq file
c --- For case b), the .DAT parmteq file should contain the following cell by cell data:
c     Cell    V     Wsyn    Beta    E0      A10     Phi     a       m       r0     Rho      B       L       Z     Imax,T  Imax
c *******************************************************************************************************************************
        implicit real*8 (a-h,o-z)
        common/mis/isfras        
        common/names/inname,fname,outname
        common/units/iinp,iout
        common/const/pi,uem
        common/cells/a(2000,30),inct(2000)
        common/cdata/rmsl,nrms
        dimension phi(2000),nc(2000)
        character*1 ctype,answer
        character*3 extens
        character*80 inarg,inname,outname,fname
        character*128 line,nline(2000)
c if isfras=1, tells routines a call was made from the asc2dyn routine         
        isfras=0        
c initialize number of cells in rfq (ncm)        
        ncm=0
        pi=4.*atan(1.)
        uem=931.49432
c define units for input and output file respectively        
        iinp=10
        iout=20        
        narg=1
        call GET_COMMAND_ARGUMENT(narg,inarg)
        if(LEN_TRIM(inarg).eq.0) then
          write(6,'(a$)') 'Input file name? '
          read(5,'(a80)') inarg
        endif
c use only one input argument at this time
        narg=1
        inname=TRIM(inarg)
c find extension of input file name        
        do i=1,80
          j=i
          if(inname(i:i).eq.'.') exit
        enddo
        if (j.eq.80) then
          write(6,*) 'Error in input file name'
          stop
        else
          fname(1:j-1)=inname(1:j-1)
          nl=j-1
          extens=inname(j+1:j+3)
c          write(6,*) fname(1:nl),'.',extens
        endif
        if (extens.eq.'ASC' .or. extens.eq.'asc') then
          fname(nl+1:nl+4)='.dat'
          write(6,'(a)') 'Will also read: ',fname
          call asc2dyn(ncm)
        elseif (extens.eq.'DAT' .or. extens.eq.'dat') then
          call dat2dyn(ncm)
        else
          write(6,*) 'Input file has to be of type .dat or .asc'
          stop
        endif
c        write(6,'(a$)')  
c     *   'Do you want the synchronous phase to be modified (y/n)? '
c        read(5,*) answer
c        if(answer.eq.'y' .or. answer.eq.'Y') then
c          call corpha(ncm)
c        endif
        write(6,'(a)') 'All done'
        END
        SUBROUTINE dat2dyn(ncm)
c *******************************************************************************************************************************
c --- Prepare input file to DYNAC based on the following parmteq cell by cell data:
c     Cell    V     Wsyn    Beta    E0      A10     Phi     a       m       r0     Rho      B       L       Z     Imax,T  Imax
c --- The letter R, T, M etc, used to describe special cells should be after the cell number (fifth character)
c --- This routine will select the following parameters :
c         a(1):  V (KVOLT)
c         a(2):  Wsyn  (Mev/u)
c         a(5):  A10 (no dimension)
c         a(6):  phase RF (deg) (input of cells)
c         a(7): smallest aperture  a  (cm)
c         a(8): modulation factor  m (no dimension)
c         a(9): mean aperture r0 (middle of cells)   (cm)
c         a(10):transverse radius of curvature  rh0 at the vane tip (cm)
c         a(12): cell length L (cm)
c
c --- The cell by cell RFQ description generated serves as input to DYNAC and is of the form:
c     CELL ITYPE V(KV)  cl(cm)   A10  a(cm)  m  r0(cm) rho(cm)  PHASE (deg)  fV
c *******************************************************************************************************************************
        implicit real*8 (a-h,o-z)
        common/mis/isfras        
        common/names/inname,fname,outname
        common/units/iinp,iout        
        common/const/pi,uem
        common/cells/a(2000,30),inct(2000)        
        common/cdata/rmsl,nrms
        dimension phi(2000),nc(2000)
        character*1 ctype,answer
        character*80 inarg,inname,outname,fname
        character*128 line,nline(2000)
        if(isfras.eq.1) then
          open(iinp,file=fname)                
        else
          open(iinp,file=inname)        
c name of output file = m_ in front of name of input file      
          outname(1:2)='m_'
          outname(3:80)=inname(1:78)
          open(iout,file=outname)
        endif
c --- read the input file, containing Parmteq data
        do
          read (iinp,'(A)') line
          if(line(1:4).eq.'Cell') exit
          if(line(2:5).eq.'Cell') exit
          if(line(3:6).eq.'Cell') exit
        enddo
c - found start of listing of cell data, cell by cell
        i=1        
        do
          read (iinp,'(A)') line
          if(line(1:4).eq.'Cell') exit
          if(line(2:5).eq.'Cell') exit
          if(line(3:6).eq.'Cell') exit
          nline(i)=line
          i=i+1
        enddo
        ncm=i-1
        write(6,'(a,i4,a)') 'Cell data read for ',ncm,' cells'
c        do i=1,ncm
c          write(13,*) nline(i)
c        enddo
        k=1
        ncm1=ncm
c nrms is number of cells in rms
        nrms=0
        do i=1,ncm
          line=nline(i)
          read (line(1:4),*) nci
c          write(6,*),nci,line
          if(i.eq.1 .and. nci.eq.0) then 
            ncm1=ncm1-1
            write(6,'(a,i4)') 'Skipping data for cell ',nci
            cycle
          endif  
          nc(k)=nci 
          read(line(5:5),'(a1)') ctype
          write(6,*) 'Debug L=',trim(line)
          write(6,*) 'Debug T=',ctype
c *******************************************************************************************************************************
c --- make up a list of cell by cell RFQ data based on the input file data
c --- read 10 parameters per line:
c     nc  ityp VV cl(cm)  A10  a(cm)  m  r0(cm) rho(cm) phase(deg) fvolt
c     nc: cell number
c     ityp = 0: standard accelerating cell (blank)
c     ityp = 1: transition cell of type T (delta-m cell)
c     ityp = 2: transition cell of type E (Entry transition cell)
c     ityp = 3: transition cell of type M (m=1 cell)
c     ityp = 4: fringe-field region type F (after type T, M or accelerating cell)
c     ityp = 5: RMS cell of type R
          if (ctype.eq.' ') inct(k)=0
          if (ctype.eq.'R') inct(k)=5
          if (ctype.eq.'E') inct(k)=2
          if (ctype.eq.'T') inct(k)=1
          if (ctype.eq.'M') inct(k)=3
          if (ctype.eq.'F') inct(k)=4
          line(1:5)='     '
          if(ctype.ne.'F') then
!2020            read(line,*) (a(k,j),j=1,15)
            read(line,*) (a(k,j),j=1,12)
            if(ctype.eq.'R') nrms=nrms+1              
          else
            read(line,*) (a(k,j),j=1,3),a(k,6),(a(k,j),j=8,10),
     *                   a(k,12)
!2020     *       (a(k,j),j=12,13)
            a(k,4)=0.
            a(k,5)=0.
            a(k,7)=0.
            a(k,11)=0.
            a(k,14)=0.
            a(k,15)=0.
          endif  
c          write(13,*) k,inct(k),(a(k,j),j=1,15)
          k=k+1
        enddo
        ncm=ncm1
        write(6,'(a,i4,a)') 'Cell data kept for ',ncm,' cells'
        zero=0.
c ---  write the output file in the form:
c   cell number, cell type, vane voltage (kV), length(cm),  A10,  a(cm),  m,  r0(cm), rho(cm), phase(deg), fvolt, NCN
c ---  fvolt: this value is applied to the inter-vane potential acting on 
c             particles (no action on synchronous particle)
c       (the starting value of fvolt is zero).
c
c initialize total rms length rmsl
        rmsl=0.
        if(isfras.eq.0) then
          NCN=0
          IFRST=0
          do i=1,ncm
            if(inct(i).eq.5) then
c multiple RMS 'cells' from the input file are converted into one DYNAC RMS cell            
              rmsl=rmsl+a(i,12)              
              if(i.eq.nrms) then
                write (iout,100)nc(i)+1-nrms,inct(i),a(i,1),rmsl,
     *    a(i,5),a(1,7),a(i,8),a(i+1,9),a(i+1,9),a(i,6),zero,NCN
              endif
            elseif(inct(i).eq.1) then
c get the correct phase etc for the special cells at the RFQ high energy end            
              if(NCN.eq.0) then
                NCN=1
              else
                NCN=0
              endif
              write (iout,100)nc(i)+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i-1,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zero,
     *    NCN
            elseif(inct(i).eq.3) then
c get the correct phase etc for the special cells at the RFQ high energy end            
              if(NCN.eq.0) then
                NCN=1
              else
                NCN=0
              endif
              write (iout,100)nc(i)+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i-1,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zero,
     *    NCN
            elseif(inct(i).eq.4) then
cdebug 2015 a(i-1,6) seems to be the wrong phase! Is the input phase of the previous cell,
cdebug 2015 but should be the output phase!
c get the correct phase etc for the special cells (F) at the RFQ high energy end            
              write (iout,100)nc(i)+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i-1,8),3.*a(i,9),a(i,10),a(i-1,6),zero,
     *    NCN
            elseif(inct(i).eq.2) then
              NCN=1
              write (iout,100)nc(i)+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i,10),a(i,6),zero,NCN
            else
c              if(IFRST.eq.0) then
c                NCN=0
c                IFRST=1
c              else
                if(NCN.eq.0) then
                  NCN=1
                else
                  NCN=0
                endif
c              endif
              write (iout,100)nc(i)+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i,10),a(i,6),zero,NCN
            endif
          enddo
          izer=0
c --- the last line  in the output file is zero
          write(iout,100)izer,izer,zero,zero,zero,zero,zero,zero,zero,
     *    zero,zero,izer
c100       format(2x,i5,2x,i1,2x,9(2x,e12.5))
100       format(1x,i5,1x,i1,1x,f12.6,1x,6(1x,f12.9),2(1x,f11.6),
     *           1x,i5)
          close(iout)
          write(6,'(a)') 'Output file written: ',outname
        endif
        close(iinp)
        return
        end
        SUBROUTINE asc2dyn(ncm)
c ****************************************************************
c ******** 18-Nov-2011 
******************************************************************
c *******1*********2*********3*********4*********5*********6*********7*
c --- Convert rfq.ASC to DYNAC input list 
c --- This file has the same cell by cell data as the .DAT file, but
c --- the data have higher accuracy. However, the transverse radius of
c --- curvature at the vane tip Rho seems to be missing. Therefor, Rho 
c --- will be read from the .DAT file.
c
c Cell V Wsyn Beta E0  A10  Phi  a  m  r0 Rho   B   L   Z   Imax,T Imax
c --- select the following parameters :
c         a(2):  Wsyn  (Mev)
c         a(5):  A10 (no dimension)
c         a(6):  Phi phase RF (deg) (entrance of cells)
c         a(7): smallest aperture  a  (cm)
c         a(8): modulation factor  m (no dimension)
c         a(9): mean aperture r0 (middle of cells)   (cm)
c         a(10):transverse radius of curvature  rh0 at the vane tip(cm)
c         a(12): cell length L (cm)
c
c *******1*********2*********3*********4*********5*********6*********7*
        implicit real*8 (a-h,o-z)
        common/names/inname,fname,outname        
        common/units/iinp,iout
        common/const/pi,uem
        common/cells/a(2000,30),inct(2000)
        common/cdata/rmsl,nrms
        common/mis/isfras        
        common/indata/atm,qst,fh
        dimension out(30),nc(2000),b(2000,30)
        integer wout,tout
        character*1 ctype,answer
        character*80 inarg,inname,outname,fname
        character*160 line,nline(2000)
        isfras=1
c get the Rho data first from the .DAT file via the dat2asc routine
        call dat2dyn(ncm)
        izer=0
        zero=0.
c define units for test files        
        wout=14
        nout=15
        ichk=13
        tout=16        
c name of output file = m_ in front of name of input file      
        outname(1:2)='m_'
        outname(3:80)=inname(1:78)
        open(iinp,file=inname,recl=160)
        open(iout,file=outname,recl=260)
        outname(1:2)='n_'        
        open(nout,file=outname)
        outname(1:2)='w_'        
        open(wout,file=outname)
c --- read the input file, containing Parmteq data
        write(6,'(a22,a)') 'Starting to read file ',inname
c first line is comment line
        read (iinp,'(A)') line
c read number of cells        
        read (iinp,*) ncm
        write(6,'(i4,a)') ncm,' cells plus 1 end cell'
        ncm=ncm+1
c read dummy        
        read (iinp,*) dummy
c read rest mass
        read (iinp,*) rmass
c read f(MHz)
        read (iinp,*) freq
        fh=freq
c read rf wavelength(m)
        read (iinp,*) rflam
c read input energy (MeV/u)
        read (iinp,*) win
c read input rel. beta 1
        read (iinp,*) beta1
c read input rel. beta 2
        read (iinp,*) beta2
c read 3 dummies        
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
c read phase cell 0        
        read (iinp,*) C0phi
c read V cell 0        
        read (iinp,*) C0V
c read 11 dummies        
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
c read a cell 0        
        read (iinp,*) C0a
c read 14 dummies        
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
        read (iinp,*) dummy
c read cell data
c cell_type cell V W etc
c        write(nout,*)'Cell  CT    V       W      beta   E0     A10'
c     *  ,'        Phi     a         m         r0       '
c     *  ,'Rho   B      L          Z     ImaxT'   
c     *  ,'   ImaxL     A0        A1'   
c        write(wout,*)'Cell  CT           W                    beta'
c     *  ,'                 Phi                L'   
c nrms is number of cells in rms
        nrms=0
        do i=1,ncm
          do j=1,30
            read (iinp,*) b(i,j)
          enddo
c sign
          out(20)=b(i,5)        
c relativistic gamma
          out(19)=b(i,8)        
c cell type
          out(18)=b(i,1)          
c VV(kV), W, beta, E0, A10          
          out(1)=b(i,30)*1000
          a(i,1)=out(1)
          out(2)=b(i,3)
          a(i,2)=out(2)
          out(3)=b(i,7)
          out(4)=0.
          out(5)=b(i,23)
          a(i,5)=out(5)
c Phi, a, m, r0, Rho      
          out(6)=b(i,13)*180./pi
          a(i,6)=out(6)
          out(7)=b(i,11)
          a(i,7)=out(7)          
          out(8)=b(i,6)
          a(i,8)=out(8)
          out(9)=b(i,2)
          a(i,9)=out(9)
          out(10)=0.
c B, L, Z, ImaxT, ImaxL
          out(11)=0.
          out(12)=b(i,4)
          a(i,12)=out(12)
          out(13)=b(i,12)
          out(14)=0.
          out(15)=0.
c A0, A1          
          out(16)=b(i,21)
          out(17)=b(i,22)               
c          write(nout,700) i,out(18),(out(k),k=1,17)
          ict=-1
          if(b(i,1).eq.0.) ict=5
          if(b(i,1).eq.5.) ict=2
          if(b(i,1).eq.1.) ict=0
          if(b(i,1).eq.2.) ict=1
          if(b(i,1).eq.3.) ict=3
          if(b(i,1).eq.4.) ict=4          
          if (ict.eq.-1) write(6,*) 'Invalid cell type for cell ',i
c overwrite small a for fringe field          
          if(ict.eq.4) a(i,7)=0.
          if(ict.eq.5) nrms=nrms+1
          inct(i)=ict
        enddo
c data read, now go and write them        
        rmsl=0.
        NCN=0
        IFRST=0
        do i=1,ncm
c     CELL ITYPE V(KV)  cl(cm)   A10  a(cm)  m  r0(cm) rho(cm)  PHASE (deg)  fV NCN
            if(inct(i).eq.5) then
c multiple RMS 'cells' from the input file are converted into one DYNAC RMS cell            
              rmsl=rmsl+a(i,12)              
              if(i.eq.nrms) then
                write (iout,100)i+1-nrms,inct(i),a(i,1),rmsl,
     *    a(i,5),a(1,7),a(i,8),a(i+1,9),a(i+1,9),a(i,6),zero,
     *          NCN
              endif
            elseif(inct(i).eq.1) then
c get the correct phase etc for the special cells at the RFQ high energy end            
              if(NCN.eq.0) then
                NCN=1
              else
                NCN=0
              endif
              write (iout,100)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i-1,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zero,
     *    NCN
            elseif(inct(i).eq.3) then
c get the correct phase etc for the special cells at the RFQ high energy end            
              if(NCN.eq.0) then
                NCN=1
              else
                NCN=0
              endif
              write (iout,100)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i-1,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zero,
     *    i-nrms
            elseif(inct(i).eq.4) then
c get the correct phase etc for the special cells (F) at the RFQ high energy end            
              write (iout,100)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i-1,8),3.*a(i,9),a(i,10),a(i-1,6),
     *    zero,NCN
            elseif(inct(i).eq.2) then
              NCN=1
              write (iout,100)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i,10),a(i,6),zero,NCN
            else
c              if(IFRST.eq.0) then
c                NCN=0
c                IFRST=1
c              else
                if(NCN.eq.0) then
                  NCN=1
                else
                  NCN=0
                endif
c              endif
              write (iout,100)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i,10),a(i,6),zero,NCN
            endif
c          write(tout,200) i,ict,out(1),out(12),out(5),(out(k),k=7,10),
c     *     out(6),zero         
c          write(wout,400) i,ict,out(2),out(3),out(6),out(12)
c          write(ichk,300) i,b(i,5),b(i,9),b(i,10),b(i,14),b(i,15)
c          write(ichk,300) i,b(i,9),b(i,14),b(i,15)
c          write(ichk,300) i,b(i,16),b(i,17),b(i,18),b(i,19),b(i,20)
c          write(ichk,300) i,b(i,15),b(i,20)
c          write(ichk,300) i,b(i,5),b(i,9),b(i,14),b(i,15),b(1,16),
c     *     b(i,24),b(i,25),b(i,27),
c     *     b(i,28),b(i,29),b(i,26)
        enddo
c --- the last line  in the output file is zero
        write(iout,100)izer,izer,zero,zero,zero,zero,zero,zero,zero,
     *    zero,zero,izer
        
        write(6,'(a,i4,a)') 'Cell data written for ',ncm,' cells'
c        do i=1,ncm
c          write(ichk,*) nline(i)
c        enddo
c100     format(1x,i5,1x,i1,1x,f12.6,1x,6(1x,f12.9),2(1x,f11.6))
100     format(1x,i5,1x,i1,1x,f12.6,1x,6(1x,f12.9),2(1x,f11.6),
     *           1x,i5)
700     format(1x,i3,1x,f4.2,2(1x,f7.4),1x,f5.3,1x,f9.6,1x,
     *     f8.4,1x,f10.6,1x,f9.6,1x,f9.6,1x,f5.3,1x,f5.3,1x,f9.6,1x,
     *     f8.3,1x,f7.3,3(1x,f9.6))
200     format(1x,i3,1x,i1,8(1x,f20.15),1x,f3.1)
300     format(1x,i3,10(1x,f12.6),1x,E12.5)
400     format(1x,i3,4x,i1,4(1x,f20.15))
        close(iinp)
        close(iout)
c        close(nout)
c        close(ichk)
        outname(1:2)='m_'        
        write(6,'(a)') 'Output file written: ',outname
c        outname(1:2)='n_'        
c        write(6,'(a)') 'Output file written: ',outname
c        outname(1:2)='w_'        
c        write(6,'(a)') 'Output file written: ',outname
        return
        end
        SUBROUTINE corpha(ncm)
c ***********************************************************************************************************************************
c --- correct synchronous phase to obtain identical energy gain as with parmteq 
c     ncm is the number of cells in the RFQ
c     Phase corrections only for cell types 0 and 2. List of cell types:
c     ityp = 0: standard accelerating cell (blank)
c     ityp = 1: transition cell of type T (delta-m cell)
c     ityp = 2: transition cell of type E (Entry transition cell)
c     ityp = 3: transition cell of type M (m=1 cell)
c     ityp = 4: fringe-field region type F (after type T, M or accelerating cell)
c     ityp = 5: RMS cell of type R
c     array inct(2000) contains cell type, cell by cell
c ***********************************************************************************************************************************
        implicit real*8 (a-h,o-z)
        common/indata/atm,qst,fh
        common/mis/isfras        
        common/cells/a(2000,30),inct(2000)
        common/cdata/rmsl,nrms
        common/names/inname,fname,outname
        common/units/iinp,iout        
        common/spl/x(4000),y(4000),s(5000),p(5000),q(5000)
        common/const/pi,uem
        common/engain/vlm,tref,bref,z,hl,cay,av,xl,ns
        dimension phi(2000),nc(2000)
        character*80 inarg,inname,outname,fname
        data vl,dphi,ddphi,epsp/2.99792458E+10,10.,0.25,1.e-05/
c ---------------------------------------------------------------------------------------------
c  output file: input file name preceeded by p_
c -----------------------------------------------------------------------------------------------
        outname(1:1)='p'
        open (iout,file=outname,status='unknown')
        iz=0
        zr=0.
        atm=238.
        write(6,'(a$)') 'Mass (e.g. 238 for U) ? '
        read(5,*) atm
        qst=1.
        write(6,'(a$)') 'Charge                ? '
        read(5,*) qst
        if(isfras.eq.0) then
          fh=80.5
          write(6,'(a$)') 'RF freqency (MHz)     ? '
          read(5,*) fh
        else
          write(6,'(a,f8.4)') 'RF freqency (MHz)=',fh
        endif
c --- REA3
c       qst=1.
c       atm=5.
c       fh=80.5
c ------------------------------
c --- FRIB_500
c       qst=33.
c       atm=238.
c       fh=80.5
c -------------------------------
       fh=2.*pi*fh*1.e06
       er=uem*atm
c  vl in m
       vlm=vl/100.
c --- ns: number of iterations (computation of energy gain of cells)
       ns=18
       radian=pi/180.
c write first cell (no phase correction)
       i=nrms
       write(iout,7779)iz+1,inct(i),a(i,1),rmsl,a(i,5),a(i,7),
     *                 a(i,8),a(i,9),a(i+1,9),a(i,6),zr,iz
c write remainder of cells       
       do i=nrms+1,ncm
c **************************************************************************************************
c      PROVISOIRE:: if A10 = 0 the input phase is not changed
c EUGENE: les data des cellules de type R et E sont conservées telles quelles
c         la cellule E demanderait un traitement specifique (non fait dans le code)
c         j'ai forcé A10 = 0 dans le fichier out de Parmteq pour cell E
c ****************************************************************************************************
         if(a(i,5).eq.0.) then
           if(inct(i).eq.5) then
c multiple RMS 'cells' from the input file are converted into one DYNAC RMS cell            
             rmsl=rmsl+a(i,12)              
             if(i.eq.nrms) then
               write (iout,7779)i+1-nrms,inct(i),a(i,1),rmsl,
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i+1,9),a(i,6),zr,i-nrms
             endif
           elseif(inct(i).eq.1) then
c get the correct phase etc for the special cells at the RFQ high energy end            
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i-1,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zr,
     *    i-nrms
           elseif(inct(i).eq.3) then
c get the correct phase etc for the special cells at the RFQ high energy end            
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i-1,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zr,
     *    i-nrms
           elseif(inct(i).eq.4) then
c get the correct phase etc for the special cells at the RFQ high energy end            
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zr,
     *    i-nrms
           else
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i,10),a(i,6),zr,i-nrms
           endif
c           
         elseif(inct(i).eq.2) then
c do not correct the phase for the entrance transition cell            
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i,10),a(i,6),zr,i-nrms
         else
c A10 is not equal to zero; correct the phase         
           tvolt=a(i,1)*1.e-03
           wref=a(i-1,2)*atm
           gref=wref/er+1.
           bref=sqrt(1.-1./(gref*gref))
c ws is reference energy gain in the cell
           ws=a(i,2)-a(i-1,2)
           ws=ws*atm
           phi(i)=a(i,6)
           phspl=phi(i)
           cl=a(i,12)*1.e-02
           xl=cl/float(ns)
           hl=.5*xl
           cay=pi/cl
           av=a(i,5)*tvolt
c check if the enrgy gain and nominal phase is within error margin
           call calcdw(phi(i),dwref,dwref1)
           write(66,*) i,i+1-nrms,phi(i),wref,a(i,2)*atm,ws,dwref1,
     *     ws-dwref1
           if(abs(ws) .le. 2.5e-03)  goto 2222        
c  phimi: lower limit of the input phase
c  phima: upperlimt of the input phase
           phimi=phi(i)-dphi
           phima=phi(i)+dphi
           phind=phimi
           isp=1
c calculate the number of phase steps
           npstps=1+int(2.*dphi/ddphi)
           wouter=10000.
           phspl=phi(i)           
           do klm=1,npstps
             phini=phind*radian
             z=0.
             tref=0.
c wref is the input energy to the cell
             wref=a(i-1,2)*atm
             wrefi=wref
             gref=wref/er+1.
             bref=sqrt(1.-1./(gref*gref))
c ---- compute for the Spline functions the table (phind,dW) with phimi < phind < phima
c      iterations over steps xl
c calculate the energy gain in the cell given the current phase setting
             call calcdw(phini,dwref,dwref1)
c  spline functions areas (deg,Mev)
             x(isp)=phind
             y(isp)=abs(dwref1-ws)
c i=ptq cell number, i+1-nrms=dynac cell number, ws=reference energy gain, dwref1=energy gain obtained
c isp is phase step number, x=phase for step isp, y=energy gain for that phase
c a(i,2)*atm is reference output energy of cell, wref is output energy of cell given the phase in 
c phase step isp            
             write(77,*) i,i+1-nrms,ws,dwref1,isp,x(isp),y(isp),
     *                   a(i,2)*atm,wref
             isp=isp+1
             phind=phind+ddphi
c find phase with smallest error in output energy             
             if(abs(a(i,2)*atm-wref).lt.abs(wouter))then
               wouter=a(i,2)*atm-wref
               phspl=x(isp-1)
             endif  
           enddo  
           isp=isp-1
c           call deriv2(isp)
cc  seek for the phase phspl(deg)
c           phspl=phimi
c           dspl=ddphi
c6000       continue
c           if(phspl.gt.phima) then
c             phspl=phi(i)
c             go to 8000
c           endif
c           wdf=slope(isp,phspl)
c           if(wdf.lt.0.) then
c             phspl=phspl+dspl
c             go to 6000
c           else
c             if(dspl.le.epsp) go to 8000
c             if(wdf.eq.6.*0.) go to 8000
c             phspl=phspl-dspl
c             dspl=dspl/5.
c             phspl=phspl+dspl
c             go to 6000
c           endif
c8000       continue
c           if(phspl.lt.phimi) phspl=phi(i)
2222         if(inct(i).eq.5) then
c multiple RMS 'cells' from the input file are converted into one DYNAC RMS cell            
             rmsl=rmsl+a(i,12)              
             if(i.eq.nrms) then
               write (iout,7779)i+1-nrms,inct(i),a(i,1),rmsl,
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i+1,9),phspl,zr,i-nrms
             endif
           elseif(inct(i).eq.1) then
c get the correct phase etc for the special cells at the RFQ high energy end            
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i-1,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zr,
     *    i-nrms
           elseif(inct(i).eq.3) then
c get the correct phase etc for the special cells at the RFQ high energy end            
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i-1,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zr,
     *    i-nrms
           elseif(inct(i).eq.4) then
c get the correct phase etc for the special cells at the RFQ high energy end            
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i-1,8),a(i,9),a(i,10),a(i-1,6),zr,
     *    i-nrms
           else
             write (iout,7779)i+1-nrms,inct(i),a(i,1),a(i,12),
     *    a(i,5),a(i,7),a(i,8),a(i,9),a(i,10),phspl,zr,i-nrms
           endif
c7779       format(2(2x,i4),9(2x,e12.5))
7779       format(1x,i5,1x,i1,1x,f12.6,1x,6(1x,f12.9),2(1x,f11.6),
     *            1x,i5)

         endif
       enddo
       write(iout,7779) iz,iz,zr,zr,zr,zr,zr,zr,zr,zr,zr
       close(iout)
       write(6,'(a)')'Output file (corrected phases) written: ',outname
       return
       end
       FUNCTION slope(N,XV)
c   ..........................................
c    first derivative of the spline function
c   ..........................................
       implicit real*8 (a-h,o-z)
       common/spl/x(4000),y(4000),s(5000),p(5000),q(5000)
       do i=2,n
         xtvi=xv-x(i)
         if(xtvi.gt.0.) go to 4
         if(xtvi.lt.0.) go to 2
         if(xtvi.eq.0.00) go to 3
4        continue
       enddo
3       I=I-1
        AVX=X(I+1)-X(I)
        SLOPE=S(I+1)*AVX/3.+S(I)*AVX/6.+(Y(I+1)-Y(I))/AVX
        return
2       I=I-1
        DGX=XV-X(I)
        DDX=X(I+1)-XV
        AVX=X(I+1)-X(I)
        SLOPE=-(S(I)*DDX*DDX)/(2.*AVX)+(S(I+1)*DGX*DGX)/(2.*AVX)
     *          +((Y(I+1)-Y(I))/AVX)-(AVX*(S(I+1)-S(I))/6.)
        return
        end
       FUNCTION spline (N,XV)
C    ..................................................................
C      SPLINE FUNCTION
C    ..................................................................
       implicit real*8 (a-h,o-z)
       COMMON /SPL/X(4000),Y(4000),S(5000),P(5000),Q(5000)
       spline=y(1)
       xtv1=xv-x(1)
       if(xtv1.lt.0.) then
         SPLINE=Y(1)+((Y(2)-Y(1))/(X(2)-X(1))-S(2)*(X(2)-X(1))/6.)
     *          *(XV-X(1))
         return
       endif
       if(xtv1.eq.0.00) then
         SPLINE=Y(1)
         return
       endif
       if(xtv1.gt.0.) then
        xtvn=xv-x(n)
        if(xtvn.eq.0.00) then
          SPLINE=Y(N)
          return
        endif
        if(xtvn.gt.0.) then
         SPLINE=Y(N)+((Y(N)-Y(N-1))/(X(N)-X(N-1))+S(N-1)*(X(N)-X(N-1))
     *           /6.)*(XV-X(N))
         return
        endif
        if(xtvn.lt.0.) then
         do i=2,n
          xtvi=xv-x(i)
          if(xtvi.gt.0.) go to 11
          if(xtvi.lt.0.) go to 2
          if(xtvi.eq.0.) go to 3
11        continue
         enddo
3        spline=y(i)
         return
2        I=I-1
         DGX=XV-X(I)
         DDX=X(I+1)-XV
         AVX=X(I+1)-X(I)
         SPLINE=S(I)*DDX**3/(6.*AVX)+S(I+1)*DGX**3/(6.*AVX)
     *   +(Y(I+1)/AVX-S(I+1)*AVX/6.)*DGX+(Y(I)/AVX-S(I)*AVX/6.)*DDX
         return
        endif
       endif
       end
       SUBROUTINE deriv2(N)
C   ...................................................................
C     second derivative of spline functions at position (x,y)
C   ...................................................................
       implicit real*8 (a-h,o-z)
       common/spl/x(4000),y(4000),s(5000),p(5000),q(5000)
       AVXN=X(N)-X(N-1)
       AVVXN=X(N-1)-X(N-2)
       AVYN=Y(N)-Y(N-1)
       AVVYN=Y(N-1)-Y(N-2)
       F=AVXN-(AVVXN**2)/AVXN
       P(N-1)=1.
       Q(N-1)=0.
       if(f.ne.0.) then
         P(N-1)=(-2.*AVXN-3.*AVVXN-AVVXN**2/AVXN)/F
         Q(N-1)=6.*(AVYN/AVXN-AVVYN/AVVXN)/F
       endif
       NM1=N-1
       DO J=2,NM1
         I=N-J
         AVX=X(I+1)-X(I)
         AVVX=X(I+2)-X(I+1)
         AVY=Y(I+1)-Y(I)
         AVVY=Y(I+2)-Y(I+1)
         D=2.*(AVX+AVVX)+AVVX*P(I+1)
         P(I)=-AVX/D
         Q(I)=(6.*(AVVY/AVVX-AVY/AVX)-AVVX*Q(I+1))/D
       ENDDO
       AVX1=X(2)-X(1)
       AVVX1=X(3)-X(2)
       G1=(AVVX1/AVX1)+1.-P(2)-(Q(2)/Q(1))
       G2=(AVVX1/(AVX1*P(1)))-(AVVX1/AVX1)-1.+P(2)
       S(1)=(Q(1)*G1)/(P(1)*G2)
       DO I=1,NM1
         S(I+1)=P(I)*S(I)+Q(I)
       ENDDO
       RETURN
       END
       subroutine calcdw(phini,dwref,dwref1)  
c calculate the energy gain in the cell given the current phase setting
       implicit real*8 (a-h,o-z)
       common/indata/atm,qst,fh
       common/const/pi,uem
       common/engain/vlm,tref,bref,z,hl,cay,av,xl,ns
       data vl,dphi,ddphi,epsp/2.99792458E+10,10.,0.25,1.e-05/
       dwref1=0.
       dwref=0.
       phref=phini
       do n=1,ns
         z=z+hl
         tref=tref+hl/(bref*vlm)
         phref=tref*fh+phini
         if(n.eq.9) phrefm=phref
         skz=sin(cay*z)
         ckz=cos(cay*z)
c  change of energy over the step xl
         sp=sin(phref)
         dwref=.5*qst*cay*av*skz*sp*xl
         dwref1=dwref1+dwref
         wref=wref+dwref
         gref=wref/er+1.
         bref=sqrt(1.-1./(gref*gref))
         tref=tref+hl/(bref*vlm)
         z=z+hl
       enddo
       return
       end
