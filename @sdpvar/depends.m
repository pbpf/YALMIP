function  LinearVariables = depends(varargin)
%DEPENDS Returns indicies to variables used in an SDPVAR object
%
% i = depends(x)
%
% Input
%    x : SDPVAR object
% Output
%    i : DOUBLE

if nargin > 1
    LinearVariables = [];
    for i = 1:nargin
        LinearVariables_i = depends(varargin{i});
        LinearVariables = [LinearVariables;LinearVariables_i(:)];
    end
    LinearVariables = unique(LinearVariables);
    return
else
    x = varargin{1};
end

if ~isa(x,'sdpvar')
    LinearVariables = [];
    return
end
S = x.sess;
[mt,variabletype] = S.getMonomtable();

% Simple linear cases
if ~any(variabletype(x.lmi_variables))
   LinearVariables = x.lmi_variables;
else
    LinearVariables = find(any(mt(x.lmi_variables,:),1));    
end