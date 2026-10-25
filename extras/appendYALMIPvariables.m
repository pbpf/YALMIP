function appendYALMIPvariables(S,lmi_variables,mt,variabletype,hashed_monoms,current_hash);
%APPENDYALMIPVARIABLES Register new variables in the session registry
%
%   Extends the monomial table of session S with the new variable IDs.
%   (Formerly wrote through the global yalmip dispatcher.)

if nargin == 2
    [mt,variabletype,hashed_monoms,current_hash] = S.getMonomtable();
end

% Update monomtable and pre-calculated variable type
n_mt = size(mt,1);
m_mt = size(mt,2);
newmt = [];
if min(lmi_variables)>m_mt % New variables
    if size(mt,1)~=size(mt,2)
        mt(size(mt,1),size(mt,1))=0;
    end
    if isempty(mt)
        mt = speye(length(lmi_variables));
        newmt = mt;
    elseif length(lmi_variables)==1
        % Slightly faster than general case
       newmt = sparse(1);
       mt(end+1,end+1) = newmt;
    else
        newmt = speye(length(lmi_variables));
        mt=blkdiag(mt,newmt);
    end
else
    mt(lmi_variables,lmi_variables) = speye(length(lmi_variables));
end
variabletype(1,size(mt,1)) = 0;
if ~isempty(newmt)
    new_hash = 3*rand_hash(size(mt,2),size(newmt,2),1);
    hashed_monoms = [hashed_monoms;full(newmt*new_hash)];
    current_hash = [current_hash;new_hash];
    S.monomtable = mt;
    S.variabletype = variabletype;
    S.hashedmonomtable = hashed_monoms;
    S.hash = current_hash;
else
    S.monomtable = mt;
    S.variabletype = variabletype;
    S.hashedmonomtable = hashed_monoms;
    S.hash = current_hash;
end
