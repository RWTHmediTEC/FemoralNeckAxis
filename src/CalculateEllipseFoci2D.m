function [Foci, AB] = CalculateEllipseFoci2D(z, a, b, alpha)

% Form the parameter vector
t = [0, pi/2];

% Rotation matrix
Q = [cos(alpha), -sin(alpha); sin(alpha) cos(alpha)];
% Major & Minor Axis
AB = (Q * [a * cos(t); b * sin(t)])';

% Focus
f = [sqrt((a.^2-b.^2)); 0] ;
alpha1 = alpha-pi;
alpha2 = alpha+pi;

% Rotation matrix
Q1 = [cos(alpha1), -sin(alpha1); sin(alpha1) cos(alpha1)];
Q2 = [cos(alpha2), -sin(alpha2); sin(alpha2) cos(alpha2)];
Foci(1,1:2) = (z-(Q2*f))';
Foci(2,1:2) = (z+(Q1*f))';

end