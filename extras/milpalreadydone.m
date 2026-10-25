function done = milpalreadydone(i,state)
done = 0;
if length(state.ALREADY_MODELLED) >= i
    if ~isempty(state.ALREADY_MODELLED{i})
        if isequal(state.ALREADY_MODELLED{i}.method,'milp')
            done = 1;
        end
    end
end
