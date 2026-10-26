function [feasible,feaslistLMI] = isfeasible(F,tol,varargin)

if nargin == 1
    tol = 0;
end
feaslistLMI = check(F,varargin{:});
feasible = all(feaslistLMI >= -tol);
