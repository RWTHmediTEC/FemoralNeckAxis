function M = ANA_CalcAndPrintEllipseResults(C, NoPpC, Print)

a = [];
b = [];
% Get data from struct
for c=1:NoPpC
    a(end+1) = norm(C.P(c).Ell.AB(1,:));
    b(end+1) = norm(C.P(c).Ell.AB(2,:));
end; clear c

% Calculate Mean and Std
M(1,1) = mean(a);      M(1,2) = std(a);
M(2,1) = mean(b);      M(2,2) = std(b);
M(3,1) = mean(a./b);  M(3,2) = std(a./b);

ellTab = table(M(:,1),M(:,2),'VariableNames',{'Mean','Std'},'RowNames',{' a',' b',' a/b'});

if Print == 1
    disp(...
        [' Summary of the major and minor axis lengths, and the ratio between ' newline ...
        ' the major and minor axis lengths of the best-fit ellipses for the ' newline ...
        ' cross sections along the unified sagittal plane.' newline])
    
    disp(ellTab);
end

end

