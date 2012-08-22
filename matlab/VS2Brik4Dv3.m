function VS2Brik4Dv3(cfg,vs)
% cfg should include func field with a name of functional data in BRIK
% format.
% cfg.TR (time of requisition) is the difference between two samples in S or ms.
% cfg.boxSize is [xmin xmax ymin ymax zmin zmax] in PRI order
% cfg.step is the spatial resolution in cm (0.5 ?)
% cfg.prefix for prefix
% vs has rows for voxels and columns for samples.

xyzMin=cfg.boxSize([1 3 5]);
xyzMax=cfg.boxSize([2 4 6]);
xsize=length(xyzMin(1):cfg.step:xyzMax(1));
ysize=length(xyzMin(2):cfg.step:xyzMax(2));
zsize=length(xyzMin(3):cfg.step:xyzMax(3));
% here I create a functional template from scratch
if ~exist ('temp+orig.BRIK','file')
    xyzstr=[num2str(xsize),' ',num2str(ysize),' ',num2str(zsize)];
    eval(['!~/abin/3dUndump -dimen ',xyzstr,' -prefix temp']);
    !~/abin/3drefit -xyzscale 5 temp+orig
    origins=abs(xyzMin);
    eval(['!~/abin/3drefit -orient PRI -xorigin ',num2str(origins(1)),' -yorigin ',num2str(origins(2)),' -zorigin ',num2str(origins(3)),' temp+orig'])
end
[~, ~, Infofunc, ~] = BrikLoad ('temp+orig');
% if ~exist('~/bin','dir')
%     mkdir ~/bin
% end
% if ~exist('~/bin/cat_matvec','file') % ~/bin but not ~/abin is recognized by matlab '!'
%     if ~exist('~/abin','dir')
%         error('requires abin folder (afni) or a link to it in home directory');
%     end
%     !cp ~/abin/ccalc ~/bin/
%     !cp ~/abin/Vecwarp ~/bin/
%     !cp ~/abin/cat_matvec ~/bin/
%     !cp ~/vsMovies/docs/coordstoijk.csh ~/bin/
% end
% xyzMin=10*cfg.boxSize([1 3 5]));
% xyzMax=10*cfg.boxSize([2 4 6]));
% eval(['!coordstoijk.csh ',cfg.func,' ',xyzMin])
% P   A      R  L     I   S
%-120 120   -90 90   -20 150
%   7 43     40 6      49 1
%    49       35        37
%ijkMin=importdata('coords.txt');
%eval(['!coordstoijk.csh ',cfg.func,' ',xyzMax])
%ijkMax=importdata('coords.txt');

%ysize=length(xyzMin(2):10*cfg.step:xyzMax(2));

tsize=size(vs,2);
vsRs=reshape(vs,[zsize,ysize,xsize,tsize]);%figure;plot(squeeze(vsRs(20,20,:))==0,'k');hold on;plot(squeeze(vsRs(20,:,20))==0,'b');plot(squeeze(vsRs(:,20,20))==0,'c');

pmt=permute(vsRs,[3 2 1 4]);
% pmt=flipdim(pmt,1);
% pmt=flipdim(pmt,2);
% pmt=flipdim(pmt,3);
% ijkMax=ijkMax+1;ijkMin=ijkMin+1; % because first ijk index is zero
% ijk order in Vfunc is (small values for ) Ant Sup Left (ASL)
%vfsize=size(Vfunc);
% newVfunc=zeros([vfsize(1:3),size(pmt,4)]);
newVfunc=pmt;

InfoNewTSOut = Infofunc;
InfoNewTSOut.RootName = '';
InfoNewTSOut.BRICK_STATS = [];
InfoNewTSOut.BRICK_FLOAT_FACS = [];
InfoNewTSOut.IDCODE_STRING = '';
InfoNewTSOut.BRICK_TYPES=3*ones(1,tsize); % 1 short, 3 float.
% InfoNewTSOut.DATASET_DIMENSIONS(1,4)=tsize;
InfoNewTSOut.DATASET_RANK(2)=tsize;

for brki=1:tsize
    if brki==1
        labels='samp1';
    else
        labels=[labels,'~samp',num2str(brki)];
    end
end
InfoNewTSOut.BRICK_LABS =labels;
% read README.attributes of afni
def=-999;
InfoNewTSOut.TAXIS_NUMS=[tsize,0,77001,def,def,def,def,def]; % 77001 for ms
if ischar(cfg.TR)
    TR=str2double(cfg.TR);
else
    TR=cfg.TR;
end
InfoNewTSOut.TAXIS_FLOATS=[cfg.torig,TR,0,0,0,-999999,-999999,-999999];

OptTSOut.Scale = 1;
OptTSOut.Prefix = cfg.prefix;
OptTSOut.verbose = 1;
%OptTSOut.Slices=tsize;
if exist([cfg.prefix,'+orig.BRIK'],'file')
    eval(['!rm ',cfg.prefix,'+orig*'])
end
%write it
WriteBrik (newVfunc, InfoNewTSOut, OptTSOut);