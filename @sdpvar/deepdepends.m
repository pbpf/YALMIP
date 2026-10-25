function  LinearVariables = deepdepends(x)
%DEPENDS Returns indicies to variables used in an SDPVAR object
%
% i = depends(x)
%
% Input
%    x : SDPVAR object
% Output
%    i : DOUBLE

S = x.sess;
[mt,variabletype] = S.getMonomtable();

% Simple linear cases
if ~any(variabletype(x.lmi_variables))
    LinearVariables = x.lmi_variables;
else
    LinearVariables = find(any(mt(x.lmi_variables,:),1));
end
extended = S.getExtvariables();
bad = ismember(LinearVariables,extended);
if any(bad)
    InnerArguments = [];
    p = S.extstruct();
    for j = find(bad)
        k = find(LinearVariables(j)==extended);
        InnerArguments = [InnerArguments deepdepends(p(k).arg{1})];
    end
    LinearVariables(find(bad))=[];
    LinearVariables = unique([InnerArguments LinearVariables]);
end
