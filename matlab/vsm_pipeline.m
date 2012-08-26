%% vsMovies, pipeline of processing
% if you have no idea what this is all about check the poster at
% vsMovies/docs.
%
% this will work if you have afni (abin) in your home folder, vsMovies/matlab
% and afni matlab pack in your matlab path, and that you are running on linux. 

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
% I got ActWgts in mat format from *.wts (Dr. Robinson's output of SAMwts)
% using this function:
% https://github.com/yuval-harpaz/SAM_BIU/blob/master/matlab/readWeights.m
load ActWgts
% multiply weights by data to form the virtual sensor traces
VS=ActWgts*avg;

% to create a 4-D image with VS2Brikv3 we create a template 'temp+orig.BRIK' based on VS box size.
% you have to define the time axsis with torig and TR and the size of the box. 
torig=-100; % beginning of VS in ms
TR=num2str(1000/1017.25); % time of requisition, time gap between samples (sampling rate here is 1017.25)
cfg=[];
%cfg.func='~/vsMovies/Data/funcTemp+orig';
cfg.step=5;
cfg.boxSize=[-120 120 -90 90 -20 150];
cfg.prefix='raw';
cfg.TR=TR;
cfg.torig=torig;
VS2Brik(cfg,VS);


% to view the image open afni with ortho+orig as underlay and raw+orig as
% overlay. click "new" for a new afni gui, there choose raw+orig as
% underlay and open a graph. you have to definre timelock as well in define
% datamode > lock. here is a rescaling command if the graph shows no VS
!~/abin/3dcalc -a raw+orig -expr '1e+9*a' -prefix sc_raw

% I saved .afni.startup_script to open the windows. after running afni it
% all opens up. you only have to open a graph on the second instance of
% afni and choose define data mode > lock > timelock
% you can open afni from matlab like this:
!~/abin/afni &

%% 'rms of weights' correction for depth
% calculating rms for the weights and make an image
rmsWts=sqrt(mean(ActWgts.*ActWgts,2)');
cfg=[];
cfg.step=5;
cfg.boxSize=[-120 120 -90 90 -20 150];
cfg.prefix='rmsWts';
VS2Brik(cfg,rmsWts')

% correct VS for depth by dividing by rms of weights (and display abs values)
% here some rescaling is required for display purposes (afni graphs may
% fail without rescaling)
!~/abin/3dcalc -a raw+orig -b rmsWts+orig -expr '1e+13*abs(a/b)' -prefix sc_abs_wts

%% absolute pseudo Z
sdNoise=std(VS(:,1:102)');
meanNoise=mean(VS(:,1:102),2);
cfg=[];
cfg.func='funcTemp+orig';
cfg.step=0.5;
cfg.boxSize=[-12 12 -9 9 -2 15];
cfg.prefix='BLmean';
VS2Brik(cfg,meanNoise)
cfg.prefix='BLsd';
VS2Brik(cfg,sdNoise')

!~/abin/3dcalc -a raw+orig -b BLmean+orig -c BLsd+orig -expr 'abs((a-b)/c)' -prefix abs_pseudoZ

%% Kurtosis (g2) based mask
kur=G2(VS(:,103:end)); % I start from sample 103 (100ms) because I don't
% want "spikes" in the baseline period to be considered as activity
cfg=[];
cfg.func='funcTemp+orig';
cfg.step=0.5;
cfg.boxSize=[-12 12 -9 9 -2 15];
cfg.prefix='kur';
VS2Brik(cfg,kur)


% apply g2 mask. for higher g2 threshold x use ispositive(b-x)
% I added 0.0001 to paint zeros blue rather than making them disappear.
!~/abin/3dcalc -a sc_abs_wts+orig -b kur+orig -expr 'a*ispositive(b)+0.0001*ispositive(a)' -float -prefix kurMsk

% since afni gui 4-D thresholding is unclear to me (you can try) I set the
% threshold myself. get only values between 4 and 100 to pass. I meant it 
% to be a 2 high pass but couldn't find the right sytax so it is 4 to 
% something very big (100).
% note this time we are talking about VS values, not g2.

!~/abin/3dcalc -a "kurMsk+orig[0..$]<4..100>" -expr 'a' -prefix kurMsk_thr4

% viewing this should give the "movie" images in the bottom of the poster.
% let me know if got stuck along the way or got something else.