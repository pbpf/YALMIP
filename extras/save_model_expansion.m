function [done,state] = save_model_expansion(method,goal_vexity,F_graph,properties,state)

done = 0;

for variables = properties.models
    save_place = find(variables == state.ALREADY_MODELLED_INDEX);
    if ~isempty(save_place)%length(state.ALREADY_MODELLED)>=variables & ~isempty(state.ALREADY_MODELLED{variables})
        % Ouch, we have already modelled this-one
        if strcmpi(state.ALREADY_MODELLED{save_place}.method,method)
            % Ok, already modelled using same approach
            done = 1;
            return
        elseif strcmpi(state.ALREADY_MODELLED{save_place}.method,'graph') & (strcmpi(method,'callback') | strcmpi(method,'integer') | strcmpi(method,'exact'))
            % Replace old graph model with exact model
            state.REMOVE_THESE_IN_THE_END = [state.REMOVE_THESE_IN_THE_END  state.ALREADY_MODELLED{save_place}.index];
            state.ALREADY_MODELLED{save_place}.goal_vexity = goal_vexity;
            state.ALREADY_MODELLED{save_place}.method = method;
            state.ALREADY_MODELLED{save_place}.index  = getlmiid(F_graph);
            state.ALREADY_MODELLED{save_place}.properties  = properties;
        elseif ((strcmpi(state.ALREADY_MODELLED{save_place}.method,'integer') | strcmpi(state.ALREADY_MODELLED{save_place}.method,'exact') | strcmpi(state.ALREADY_MODELLED{save_place}.method,'callback')) & strcmpi(method,'graph'))
            % Keep old stuff, we are done
            done = 1;
            return
        end
    else
        state.ALREADY_MODELLED{end+1}.goal_vexity = goal_vexity;
        state.ALREADY_MODELLED{end}.method = method;
        state.ALREADY_MODELLED{end}.index  = getlmiid(F_graph);
        state.ALREADY_MODELLED{end}.properties = properties;
        state.ALREADY_MODELLED_INDEX = [state.ALREADY_MODELLED_INDEX;variables];
    end
end
