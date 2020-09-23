function ClearPlot(PlotHandle, Type)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

for t=1:length(Type)
    delete(findobj(PlotHandle, 'Type', Type{t}))
end

end
