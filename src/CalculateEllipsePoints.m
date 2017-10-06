function points = CalculateEllipsePoints(z, a, b, alpha, npts)
% Form the parameter vector
t = linspace(0, 2*pi, npts);
% Rotation matrix
Q = [cos(alpha), -sin(alpha); sin(alpha) cos(alpha)];
% Ellipse points
points = (Q * [a * cos(t); b * sin(t)] + repmat(z, 1, npts))';
end