function Ells = FitEllipseParfor(ContourParts, verbose)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

Ells = nan(5, size(ContourParts,1));
parfor p=1:length(ContourParts)
    Ells(:,p) = TryFitEllipse(ContourParts{p}, verbose);
end

end

function Ell = TryFitEllipse(ContourPart, verbose)
    try
        % Try to fit a ellipse
        [z(1,1), z(2,1), a, b, g] = ellipse_im2ex(ellipsefit_direct(ContourPart(1,:)',ContourPart(2,:)'));
    catch
        if verbose
            % If fitting is not successful create a fake ellipse
            warning('Ellipse fit was not successful: Creating fake ellipse!')
        end
        z = [1.1;-1.1]; a = 3; b = 2; g = 1;
    end
    Ell = [z; a; b; g];
end

