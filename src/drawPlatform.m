function  varargout = drawPlatform(plane, siz, varargin)

%% Parse inputs
if numel(plane) == 1 && ishandle(plane)
    hAx = plane;
    plane = siz;
    siz = varargin{1};
    varargin(1) = [];
else
    hAx = gca;
end

p=inputParser;
addRequired(p,'plane',@(x) size(x,1)==1 && isPlane(x))
parse(p,plane)

if ~isempty(varargin)
    if length(varargin) == 1
        if isstruct(varargin{1})
            % if options are specified as struct, need to convert to 
            % parameter name-value pairs
            varargin = [fieldnames(varargin{1}) struct2cell(varargin{1})]';
            varargin = varargin(:)';
        else
            % if option is a single argument, assume it corresponds to 
            % plane color
            varargin = {'FaceColor', varargin{1}};
        end
    end
else
    % default face color
    varargin = {'FaceColor', 'm'};
end


%% Algorithm
% Calculate vertex points of the platform 
pts(1,:) = planePoint(plane,[1,1]*0.5.*siz);
pts(2,:) = planePoint(plane,[1,-1]*0.5.*siz);
pts(3,:) = planePoint(plane,[-1,-1]*0.5.*siz);
pts(4,:) = planePoint(plane,[-1,1]*0.5.*siz);

pf.vertices=pts;
pf.faces=[1 2 3 4];

% Draw the patch
h = patch(hAx, pf, varargin{:});


%% Parse outputs
% Return handle to plane if needed
if nargout>0
    varargout{1}=h;
end

end
