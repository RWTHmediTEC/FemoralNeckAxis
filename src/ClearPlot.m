function ClearPlot(PlotHandle, Type)

for t=1:length(Type)
    delete(findobj(PlotHandle, 'Type', Type{t}))
end

end
