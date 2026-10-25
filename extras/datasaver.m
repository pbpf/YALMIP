function  data = datasaver(op,x,i,memo)
%DATASAVER Evaluate compiled PENNLP function/constraint data at x
%
%   The compiled data and the cached monomial evaluation live on the
%   per-solve memo handle (memo.payload), replacing the former persistent
%   storage in this function. Initialized by solvers/callpennlp.m.

d = memo.payload;

if ~isequal(x,d.x)
    % Recompute the monomial terms for new x
    d.monomials=ones(1,size(d.savedfunctiondata.monomtable,2));
    d.monomials(d.savedfunctiondata.linearindicies) = x(:)';

    for k = 1:length(d.savedfunctiondata.nonlinearindicies)
        d.monomials(d.savedfunctiondata.nonlinearindicies(k)) = prod(d.monomials.^d.savedfunctiondata.monomtable(d.savedfunctiondata.nonlinearindicies(k),:));
    end
    d.x = x;
    memo.payload = d;
end

switch op
    case 1
        F = d.savedfunctiondata.F_struc;
    case 2
        F = d.savedfunctionGradientdata.F_struc;
    case 3
        F = d.savedfunctionHessiandata.F_struc;
    case 4
        if isempty(i)
            % ipopt-style call
            F = d.savedconstraintdata.F_struc;
        else
            % pennlp call
            F = d.savedconstraintdata.F_struc(1+i,:);
        end
    case 5
        F = d.savedconstraintGradientdata.F_struc;
        start = 1+(i-1)*d.n;
        F = F(i:d.m:end,:);
    case 6
        F = d.savedconstraintHessiandata.F_struc;
        F = full(F((i-1)+(1:d.m:d.m*d.n^2),:));
    otherwise
end

data = (F*[1;d.monomials(:)]);
