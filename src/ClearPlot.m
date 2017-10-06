function ClearPlot(FigHandle, PlotHandle, Type)

figure(FigHandle)
for t=1:length(Type)
    delete(findobj(PlotHandle, 'Type', Type{t}))
end

end
