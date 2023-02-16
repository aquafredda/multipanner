declare name "XYZMultipanner";
declare vendor "G.A.";
declare author "Gabriele Acquafredda";

import("12ts.lib"); 

pp = hslider("[00]Mic Mode (0 Omni | 0.5 Cardioid | 1 8.figure)",0,0,1,0.1);
dst = hslider("[01]Distance Between Microphones in cm",17,17,1000,1) : si.smoo; 
dvg = hslider("[02]Divergence in degrees",55,0,+90,1) : si.smoo; //apertura
cd = hslider("[03]X in cm",0,-1000,1000,1) : si.smoo ;
da = hslider("[03]Y in cm",100,0,1000,1) : si.smoo : max(ma.EPSILON);
ab = hslider("[03]Z in cm",100,5,1000,1) : si.smoo : max(ma.EPSILON);


//OUTPUT DISTANZA REALE TRA I MICROFONI SULLE TRE COORDINATE
xyz2dst(cd,da,ab) = cb(ab,ca)
with{
    ca = ts.pit(cd,da);
    cb(ab,ca) = ts.pit(ab,ca);
};

//OUTPUT RADIANTI AZIMUT REALI
dst2arad(cd,da,ab) = arad(cb,db,cd,xsign)
with{
    cb = xyz2dst(cd,da,ab);

    xsign = cd : ma.signum;
    db = ts.pit(ab,da);
    arad(cb,db,cd,xsign) = ts.acarnot(cb,db,cd) : ts.rad2deg : _ * xsign : (_+90) : ts.deg2rad;
};

//DISTANZA REALE TRA CIASCUN MIC DELLA COPPIA MAIN E LA SORGENTE
dstmicmain(cd,da,ab,dst,rad) = dstsource(cb,dst,rad)
with{
    cb = xyz2dst(cd,da,ab);
    dstsource(cb,dst,rad) = ts.lcarnot(cb,dst/2,rad);
};

//ANGOLO DI INCIDENZA DELLA SORGENTE SU UNA CAPSULA
radmicmain(cd,da,ab,dst,rad) = inc(dst,dstcap,cb)
with{
    cb = xyz2dst(cd,da,ab);
    dstcap = dstmicmain(cd,da,ab,dst,rad);
    
    inc(dst,dstcap,cb) = ts.acarnot(dst/2,dstcap,cb) : ts.rad2deg : (90-_) : ts.deg2rad;
};

panner(sig,pp,inc) = pan(sig,pp,inc)
with {
    pan(sig,pp,inc) = ppattern(sig,pp,inc); 
};

delaysig(sig,dst) = output(sig,delinsamples)
with {
    sspeed = 321;
    delinsamples = ((dst/100)/sspeed)*ma.SR : int;
    output(sig,delinsamples) = sig : de.sdelay(10000,256,delinsamples);
};

att(sig,dst) = output(sig,dst)
with{
    //Leq=Lrif−20*Log10(r/rrif)
    output(sig,dst) = sig * (100 - 20*log10(dst/0.1))/100;
};

multipanner(sig,cd,da,ab,dst,dvg,pp) = l(sig,pp,totangleL,dstL), r(sig,pp,totangleR,dstR)
with{
    //radianti dal centro
    radL = dst2arad(cd,da,ab);
    radR = radL : rad2deg : (_-180) : deg2rad;

    incL = radmicmain(cd,da,ab,dst,radL) : rad2deg;
    incR = radmicmain(cd,da,ab,dst,radR) : rad2deg;

    dstL = dstmicmain(cd,da,ab,dst,radL);
    dstR = dstmicmain(cd,da,ab,dst,radR);

    totangleL = incL, dvg : + : deg2rad;
    totangleR = incR, dvg : + : deg2rad;

    l(sig,pp,totangleL,dstL) = panner(sig,pp,totangleL) : delaysig(_,dstL) : att(_,dstL);
    r(sig,pp,totangleR,dstR) = panner(sig,pp,totangleR) : delaysig(_,dstR) : att(_,dstR);
};

//process = _, cd, da, ab, dst, dvg, pp : multipanner;
process = multipanner; //OGGETTO MAX
