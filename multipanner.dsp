declare name "Multipanner";
declare vendor "G.A.";
declare author "Gabriele Acquafredda";

import("stdfaust.lib"); 
ts = library("12ts.lib");

deg2rad = * (ma.PI/180);
rad2deg = * (180/ma.PI);


prad = hslider("Radiants",0,-89.9,+89.9,0.1)+90 : deg2rad : si.smoo;
pradR = prad : rad2deg : (_-180) : deg2rad;
pinc = hslider("Inclination",55,0,+90,1) : deg2rad : si.smoo;
pdismic = hslider("Distance Between Microphones in cm",100,10,300,1) : si.smoo;
pdissig = hslider("Distance From Source in cm",50,10,300,1) : si.smoo;

//calculated radiants
disL = sqrt((pdissig^2) + ((pdismic/2)^2) - 2*(pdissig) * (pdismic/2) * cos(prad)) <: attach(_,abs : vbargraph("Left Distance[style:numerical]",0,3000));
disR = sqrt((pdissig^2) + ((pdismic/2)^2) - 2*(pdissig) * (pdismic/2) * cos(pradR)) <: attach(_,abs : vbargraph("Right Distance [style:numerical]",0,3000));

//calcolo angolo L
betaL = acos(( ((pdismic/2)^2) + (disL)^2 - pdissig^2 ) / (2*(pdismic/2)*disL)) : rad2deg;
compbetaL = betaL : (90-_) : deg2rad;
//calcolo angolo R
betaR = acos(( ((pdismic/2)^2) + (disR)^2 - pdissig^2 ) / (2*(pdismic/2)*disR)) : rad2deg;
compbetaR = betaR : (90-_) : deg2rad;

//v = s / t
sspeed = 343; //velocità del suono
delayL = ((disL/100)/sspeed)*ma.SR;
delayR = ((disR/100)/sspeed)*ma.SR;


panner(radL,radR,inc,x) = l(radL,inc,x), r(radR,inc,x)
with{
    
    pp = checkbox("Omni Mode");
    l(radL,inc,x) = ((0.5 * x) + (0.5 * x * cos(radL))*cos(inc))*(1-pp) + (x*pp);
    r(radR,inc,x) = ((0.5 * x) + (0.5 * x * cos(radR))*cos(-inc))*(1-pp) + (x*pp);
};

delayLR(delayL,delayR,x) = l(delayL,x), r(delayR,x) 
with{
    l(delayL,x) = x : de.delay(3000,delayL);
    r(delayR,x) = x : de.delay(3000,delayR);
};

attenuation(disL,disR,x) = l(disL,x), r(disR,x)
with{
    //Leq=Lrif−20*Log10(r/rrif)
    l(disL,x) = x * (100 - 20*log10(disL/0.1))/100;
    r(disR,x) = x * (100 - 20*log10(disR/0.1))/100;
    
};

vstin = _ , !;
process = no.pink_noise <: panner(compbetaL,compbetaR,pinc,_) : delayLR(delayL,delayR,_) : attenuation(disL,disR,_) ; //il _ nella funzione è 
