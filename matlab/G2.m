function kurt=G2(x)
% x is a data matrix, raws for channels, columns for time samples.
xbl=x-Vec2Mat(mean(x,2),size(x,2));
x2=xbl.^2;
x4=xbl.^4;
sx2=sum(x2')';
sx4=sum(x4')';
VAR=sx2./(size(x,2)-1); 
kurt=sx4./(VAR.*VAR.*size(x,2))-3;
end