function F = setupMeta(F,operator,varargin)

F = flatten(F);
F.clauses{1}.type = 56;
F.clauses{1}.data = {operator, varargin{:}};
% The session travels with the operands of the meta constraint
if isempty(sessOf(F))
    for i = 1:length(varargin)
        if isa(varargin{i},'sdpvar') || isa(varargin{i},'lmi') || isa(varargin{i},'constraint')
            Si = session(varargin{i});
            if ~isempty(Si)
                F.sess = Si;
                break
            end
        end
    end
end
if isempty(sessOf(F))
    error('YALMIP:sessionRequired','Cannot determine the session of this constraint expression.')
end
F.LMIid = sessOf(F).lmiid();
