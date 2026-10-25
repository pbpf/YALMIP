function F = setupMeta(F,operator,varargin)

F = flatten(F);
F.clauses{1}.type = 56;
F.clauses{1}.data = {operator, varargin{:}};
% The session travels with the operands of the meta constraint
if isempty(F.sess)
    for i = 1:length(varargin)
        if isa(varargin{i},'sdpvar') || isa(varargin{i},'lmi') || isa(varargin{i},'constraint')
            if ~isempty(varargin{i}.sess)
                F.sess = varargin{i}.sess;
                break
            end
        end
    end
end
if isempty(F.sess)
    error('YALMIP:sessionRequired','Cannot determine the session of this constraint expression.')
end
F.LMIid = F.sess.lmiid();
