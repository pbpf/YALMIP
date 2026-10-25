function done = alreadydone(variable,method,goal_vexity,state)
done = 0;
index = find(state.ALREADY_MODELLED_INDEX == variable);
if ~isempty(index)
    if ~isempty(state.ALREADY_MODELLED{index})
        if isequal(state.ALREADY_MODELLED{index}.method,method)
            if isequal(state.ALREADY_MODELLED{index}.goal_vexity,goal_vexity)
                done = 1;
            end
        elseif isequal(state.ALREADY_MODELLED{index}.method,'milp') || isequal(state.ALREADY_MODELLED{index}.method,'integer') || isequal(state.ALREADY_MODELLED{index}.method,'exact')
            done = 1;
        end
    end
end
