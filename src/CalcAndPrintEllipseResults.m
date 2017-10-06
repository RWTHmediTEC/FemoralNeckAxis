function M = CalcAndPrintEllipseResults(C, NoPpC, Print)

ma = [];
mb = [];
% Get data from struct
for c=1:NoPpC
    ma(end+1) = norm(C.P(c).Ell.AB(1,:));
    mb(end+1) = norm(C.P(c).Ell.AB(2,:));
end; clear c

colh = {'Mean','Std'};
rowh = {' a',' b',' a/b'};

% Calculate Mean and Std
M(1,1) = mean(ma);      M(1,2) = std(ma);
M(2,1) = mean(mb);      M(2,2) = std(mb);
M(3,1) = mean(ma./mb);  M(3,2) = std(ma./mb);


if Print == 1
    display(...
        [' Summary of the major and minor axis lengths, and the ratio between ' char(10) ...
        ' the major and minor axis lengths of the best-fit ellipses for the ' char(10) ...
        ' cross sections along the unified sagittal plane.' char(10)])
    
    displaytable(M,colh,8,'.4f',rowh,1)
    
    display(' ');
end

end

