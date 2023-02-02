declare name "XYZMultipanner";
declare vendor "G.A.";
declare author "Gabriele Acquafredda";

import("12ts.lib"); 

pp = hslider("[00]Mic Mode (0 Omni | 0.5 Cardioid)",0,0,0.5,0.5);
dst = hslider("[01]Distance Between Microphones in cm",17,10,1000,1) : si.smoo; 
dvg = hslider("[02]Divergence in degrees",55,0,+90,1) : ts.deg2rad : si.smoo; //apertura
cd = hslider("[03]X in cm",0,-1000,1000,1) : si.smoo;
da = hslider("[03]Y in cm",100,0,1000,1) + 0.000001 : si.smoo;
ab = hslider("[03]Z in cm",100,0,1000,1) + 0.000001 : si.smoo;


//OUTPUT DISTANZA REALE TRA I MICROFONI SULLE TRE COORDINATE
xyz2dst(cd,da,ab) = cb(ab,ca)
with{
    ca = ts.pit(cd,da);
    cb(ab,ca) = sqrt(ab ^ 2 + ca ^ 2);
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
    //betaL = acos(( ((pdismic/2)^2) + (disL)^2 - pdissig^2 ) / (2*(pdismic/2)*disL)) : rad2deg;
    cb = xyz2dst(cd,da,ab);
    dstcap = dstmicmain(cd,da,ab,dst,rad);
    //angolo di incidenza sulla capsula
    
    inc(dst,dstcap,cb) = ts.acarnot(dst/2,dstcap,cb) : ts.rad2deg : (90-_) : ts.deg2rad;
};

panner(sig,pp,inc,dvg) = pan(sig,pp,inc,dvg)
with {
    pan(sig,pp,inc,dvg) = ppattern(sig,pp,inc,dvg); 
};

delaysig(sig,dst) = output(sig,delinsamples)
with {
    sspeed = 321;
    delinsamples = ((dst/100)/sspeed)*ma.SR;
    output(sig,delinsamples) = sig : de.delay(10000,delinsamples);
};

att(sig,dst) = output(sig,dst)
with{
    //Leq=Lrif−20*Log10(r/rrif)
    output(sig,dst) = sig * (100 - 20*log10(dst/0.1))/100;
};

multipanner(sig,cd,da,ab,dst,dvg,pp) = l(sig,pp,incL,dvg,dstL), r(sig,pp,incR,dvg,dstR)
with{
    //radianti dal centro
    radL = dst2arad(cd,da,ab);
    radR = radL : rad2deg : (_-180) : deg2rad;

    incL = radmicmain(cd,da,ab,dst,radL);
    incR = radmicmain(cd,da,ab,dst,radR);

    dstL = dstmicmain(cd,da,ab,dst,radL);
    dstR = dstmicmain(cd,da,ab,dst,radR);


    l(sig,pp,incL,dvg,dstL) = panner(sig,pp,incL,dvg) : delaysig(_,dstL) : att(_,dstL);
    r(sig,pp,incR,dvg,dstR) = panner(sig,pp,incR,-dvg) : delaysig(_,dstR) : att(_,dstR);
};

process = no.pink_noise, cd, da, ab, dst, dvg, pp : multipanner;
