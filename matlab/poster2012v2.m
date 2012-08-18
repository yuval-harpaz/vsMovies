%% Version 2
% this is version is intended to be an idependent script
% the previous script poster2012 is how I created my movie while using my
% other repositories in github.com/yuval-harpaz. this one requires no dependencies.
% it assumes you have afni and vsMovies in your home folder and that you 
% are running on linux. it will add bin folder in your home directory for
% better control of afni funcions by matlab
cd ~/vsMovies/Data
% avg is averaged MEG data of 54 trials. each row (248 rows) is one MEG channel
load avg
% ActWgts is for active weights. 
%    channel indexing: each column is one MEG channel by the same index as the rows of avg.
%    voxel indexing: each row (63,455 rows) is for one vs. they are arranged
%        in a box as follows:The first weight is at the most negative values 
%        of x, y, z -- progressing in the positive direction in steps 0.5cm.
%        The most rapidly changing index is Z, and the slowest changing
%        index is X. the coord system is PRI - posterior right inferior for
%        the smallest (negative) x,y and z, respectively.
%        here the first vs location is -12,-9,-2. the second is -12,-9,-1.5 and so on.
%        see cfg.boxSize below
load ActWgts


load rmsWts
timeStep=1; %in samples
torig=-0.1; %beginning of VS in sec
[VS,timeline,AllInd]=VS_slice(VG,'~/Data/tel_hashomer/yuval/SAM/VGerf,1-35Hz,VerbAa.wts',timeStep,[torig 0.5]);
% [vs,allInd]=inScalpVS(VS,AllInd);
TR=num2str(1000*timeStep/1017.25); % time of requisition, time gap between samples
cfg=[];
cfg.func='funcTemp+orig';
cfg.step=0.5;
cfg.boxSize=[-12 12 -9 9 -2 15];
cfg.prefix='rmsWts';
vs2brik(cfg,rmsWts')

cfg.prefix='raw';
cfg.TR=TR;
cfg.torig=torig*1000;
vs2brik4D(cfg,VS)
!~/abin/3dcalc -a raw+orig -expr '1e+9*a' -prefix sc_raw

!~/abin/3dcalc -a raw+orig -b rmsWts+orig -expr '1e+13*abs(a/b)' -prefix sc_abs_wts

sdNoise=std(VS(:,1:102)');
%sdmat=vec2mat(sdnoise,size(VS,2))';
meanNoise=mean(VS(:,1:102),2);
cfg=[];
cfg.func='funcTemp+orig';
cfg.step=0.5;
cfg.boxSize=[-12 12 -9 9 -2 15];
cfg.prefix='BLmean';
vs2brik(cfg,meanNoise)
cfg.prefix='BLsd';
vs2brik(cfg,sdNoise')

!~/abin/3dcalc -a raw+orig -b BLmean+orig -c BLsd+orig -expr 'abs((a-b)/c)' -prefix abs_pseudoZ


kur=g2(VS(:,103:end));
cfg=[];
cfg.func='funcTemp+orig';
cfg.step=0.5;
cfg.boxSize=[-12 12 -9 9 -2 15];
cfg.prefix='kur';
vs2brik(cfg,kur)


% apply g2 masks
!~/abin/3dcalc -a sc_abs_wts+orig -b kur+orig -expr 'a*ispositive(b-3)+0.0001*ispositive(a)' -float -prefix kurMsk3

% set threshold

!~/abin/3dcalc -a "kurMsk3+orig[0..$]<2..100>" -expr 'a' -prefix kurMsk3_thr2

!~/abin/3dcalc -a "kurMsk3+orig[0..$]<4..100>" -expr 'a' -prefix kurMsk3_thr4