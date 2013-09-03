function kurt=G2(x)
% x is a data matrix, raws for channels, columns for time samples.
xbl=x-repmat(mean(x,2),1,size(x,2));
x2=xbl.^2;
x4=xbl.^4;
sx2=sum(x2')';
sx4=sum(x4')';
VAR=sx2./(size(x,2)-1);
if ~isempty(find(VAR.*VAR==0)) 
    kurt=G2(1000.*x);
    warning('Multiplying x by 1000, VAR^2 is too small for single. consider rescaling X before using G2')
else
kurt=sx4./(VAR.*VAR.*size(x,2))-3;
end