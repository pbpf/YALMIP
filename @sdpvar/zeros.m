function sys = zeros(varargin)
% ZEROS Creates overloaded SDPVAR zeros
%
 % zeros(N,M,'like',spvar) generates an N-by-M zero matrix
 % which actually is an SDPVAR, which means its elements can be changed to
 % SDPVARs
 %
 % Example
 % S = yalmip.Session();
 % X = zeros(2,3,'like',S.sdpvar(1))
 % y = S.sdpvar(1);
 % X(1,3) = y;
 % ShouldBeZero = X - [0 0 y;0 0 0]

if nargin < 4 || ~isequal(varargin{nargin-1},'like') || ~isa(varargin{end},'sdpvar')
    error('YALMIP:sessionRequired','zeros(...,''like'',X) requires an sdpvar template to inherit the session from.');
end
S = varargin{end}.sess;
Z = zeros(varargin{1:nargin-2});
sys = struct(sdpvarCore(S,1));
sys.dim = size(Z);
sys.lmi_variables = [];
sys.basis = Z(:);
sys = sdpvar(sys);
