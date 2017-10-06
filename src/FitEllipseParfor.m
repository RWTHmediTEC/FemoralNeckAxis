function Ells = FitEllipseParfor(ContourParts)

parfor p=1:length(ContourParts)
    Ells{p} = TryFitEllipse(ContourParts{p})
end

Ells = cell2mat(Ells);

end

function Ell = TryFitEllipse(ContourPart)
    try
        % TEST: Try the function fitellipse. If it is not
        % successful catch the error and create a fake ellipse.
        % Could be improved by replacing the fake ellipse against
        % a robust fitting algorithm ;-)
        [z, a, b, g] = fitellipse(ContourPart);
        % Check if a and b are positive scalars
        if a <= 0 || b <= 0
            warning('Ellipse fit was not successful: a <= 0 || b <= 0! Creating fake ellipse ;).')
             z = [1.1;-1.1]; a = 3; b = 2; g = 1;
        end
    catch
        warning('Ellipse fit was not successful:  Error in fitellipse! Creating fake ellipse ;).')
        z = [1.1;-1.1]; a = 3; b = 2; g = 1;
    end
    
    Ell = [z; a; b; g];
end

