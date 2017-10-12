function Ells = FitEllipseParfor(ContourParts)

Ells = nan(5, size(ContourParts,1));
parfor p=1:length(ContourParts)
    Ells(:,p) = TryFitEllipse(ContourParts{p});
end

end

function Ell = TryFitEllipse(ContourPart)
[z(1,1), z(2,1), a, b, g] = ...
    ellipse_im2ex(ellipsefit_direct(ContourPart(1,:)',ContourPart(2,:)'));
Ell = [z; a; b; g];
end