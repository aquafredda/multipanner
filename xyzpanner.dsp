declare name "Multipanner";
declare vendor "G.A.";
declare author "Gabriele Acquafredda";

import("stdfaust.lib"); 
ts = library("12ts.lib");

deg2rad = * (ma.PI/180);
rad2deg = * (180/ma.PI);

pinc = nentry("[2]Microphones Inclination in degrees",55,0,+90,1) : deg2rad : si.smoo;
pdismic = nentry("[1]Distance Between Microphones in cm",17,10,1000,1) : si.smoo;

cd = nentry("[3]X in cm",0,-1000,1000,1) : si.smoo;
da = nentry("[3]Y in cm",100,0,1000,1) + 0.000001 : si.smoo;
ab = nentry("[3]Z in cm",100,0,1000,1) + 0.000001 : si.smoo;

ca = sqrt(cd ^ 2 + da ^ 2);
xsign = cd : ma.signum;

cb = sqrt(ab ^ 2 + ca ^ 2);
db = sqrt(ab ^ 2 + da ^ 2);

prad = acos((cb ^ 2 + db ^ 2 - cd ^ 2)/(2 * cb * db)) : rad2deg : _ * xsign : (_+90) : deg2rad;
pradR = prad : rad2deg : (_-180) : deg2rad;

zrad = acos((cb^2 + ab^2 - ca^2)/(2 * cb * ab)) : rad2deg : 90-_ : deg2rad;

pdissig = cb;

//calculated radiants
disL = sqrt((pdissig^2) + ((pdismic/2)^2) - 2*(pdissig) * (pdismic/2) * cos(prad)) <: attach(_,abs : vbargraph("h:Distances From Source in cm/[1]Left [style:numerical]",0,3000));
disR = sqrt((pdissig^2) + ((pdismic/2)^2) - 2*(pdissig) * (pdismic/2) * cos(pradR)) <: attach(_,abs : vbargraph("h:Distances From Source in cm/[2]Right [style:numerical]",0,3000));

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

    
panner(radL,radR,inc,x) = l(radL,inc, x), r(radR, inc, x)
with{
    
    pp = vslider("[0]Mic Mode[style:menu{'Cardioid':0;'Omni':1}]",0,0,1,1);

    //la divisione in bande serve a simulare meglio le capsule microfoniche e la sensibilità alle varie frequenze in base all'angolo di incidenza
    crossover(x) = x : fi.crossover2LR4(10000) : si.bus(2);

    band1(rad,inclination,pp,x) = x <: ((0.5 * _) + (0.5 * _ * cos(rad))*cos(inclination))*cos(zrad)*(1-pp) + (_*pp);
    band2(rad,inclination,pp,x) = x <: ((0.4 * _) + (0.6 * _ * cos(rad))*cos(inclination))*cos(zrad)*(1-pp) + (_*pp);


    l(radL,inc, x) = crossover(x) : band1(radL,inc,pp,_), band1(radL,inc,pp,_) :> _;
    r(radR,inc, x) = crossover(x) : band1(radR,-inc,pp,_), band1(radR,-inc,pp,_) :> _;
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

process = vstin <: panner(compbetaL,compbetaR,pinc,_) : delayLR(delayL,delayR,_) : attenuation(disL,disR,_);
