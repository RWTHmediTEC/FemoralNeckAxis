function Ells = FitEllipseParfor(ContourParts)

Ells = nan(5, size(ContourParts,1));
parfor p=1:length(ContourParts)
    Ells(:,p) = TryFitEllipse(ContourParts{p});
end

end

function Ell = TryFitEllipse(ContourPart)
    try
        % Try to fit a ellipse
        [z(1,1), z(2,1), a, b, g] = ellipse_im2ex(ellipsefit_direct(ContourPart(1,:)',ContourPart(2,:)'));
    catch
        % If fitting is not successful create a fake ellipse
        warning('Ellipse fit was not successful: Creating fake ellipse!')
        z = [1.1;-1.1]; a = 3; b = 2; g = 1;
    end
    Ell = [z; a; b; g];
end

