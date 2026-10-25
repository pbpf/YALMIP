function res = isrelaxfeasible(F,sol)

% The stateless refactoring removed the global "last solution": the
% solution struct returned by OPTIMIZE must be passed explicitly.
if nargin < 2
    error('YALMIP:sessionRequired','Since the stateless refactoring, pass the solution: res = isrelaxfeasible(F, sol), where sol = optimize(Fc,obj).')
end

% Unwrap the evaluation payload if the full optimize output is passed
if isstruct(sol) && isfield(sol,'eval')
    sol = sol.eval;
end

F = flatten(F);

nlmi = length(F.LMIid);
spaces = ['                                    '];
if (nlmi == 0) & (neq == 0)
    disp('empty LMI')
    return
end

lmiinfo{1} = 'LMI';
lmiinfo{2} = 'Element-wise';
lmiinfo{3} = 'Equality constraint';
lmiinfo{4} = 'Second order cone constraint';
lmiinfo{5} = 'Rotated Lorentz constraint';

header = {'ID','Constraint','Type','Residual (should be > 0)','Tag'};

if nlmi>0
    for j = 1:nlmi
        F0 = relaxdouble(F.clauses{j}.data,sol);
        if any(isnan(F0(:)))
            res = NaN;
        else
            switch F.clauses{j}.type
                case 1
                    res = min(eig(F0));
                case 2
                    res = min(min(F0));
                case 3
                    res = -max(max(abs(F0)));
                case 4
                    res = F0(1)-norm(F0(2:end));
                case 5
                    res = 2*F0(1)*F0(2)-norm(F0(3:end))^2
            end
        end
        data{j,1} = ['#' num2str(j)];
        data{j,2} = F.clauses{j}.symbolic;
        data{j,3} = lmiinfo{F.clauses{j}.type};
        data{j,4} = res;
        data{j,5} = F.clauses{j}.handle;
    end
end

res = [data{:,4}];
