function p = smashFixed(p,action)
% Note: isempty is wrong here - a model with bounds but no rows has
% F_struc = 0-by-nvars, which isempty treats as empty, so the fixed
% columns would never be smashed and the node model would leave a
% width-mismatched F_struc behind (observed as "prob.blx has invalid
% dimension" in the MOSEK interface for bnb nodes on semivar models).
if p.feasible && size(p.F_struc,2) > 0
    r = find(p.lb == p.ub);
    if ~isempty(r)
        p.F_struc(:,1) = p.F_struc(:,1) + p.F_struc(:,1+r)*p.lb(r);
        if nargin == 1 || strcmp(action,'keep')
            p.F_struc(:,1+r) = 0;
        elseif strcmp(action,'reduce')
            % Not used, just testing
            p.F_struc(:,1+r) = [];
            p.f = p.f + p.c(r)'*p.lb(r);
            p.c(r) = [];
            p.lb(r)=[];
            p.ub(r)=[];                         
            p.Q(:,r)=[];
            p.Q(r,:)=[];
            p.variabletype(r) = [];
            p.monomtable(r,:) = [];
            p.monomtable(:,r) = [];
            kept = setdiff(1:length(p.c),r);
            [~,p.binary_variables] = find(ismember(kept,p.binary_variables));
            [~,p.integer_variables] = find(ismember(kept,p.binary_variables));
            p = presolve_strengthen_coefficients(p);
            p = presolve_empty_rows(p);                   
        else
            p.F_struc(:,1+r) = [];
        end
    end
end