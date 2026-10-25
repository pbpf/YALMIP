function sys = double2sdpvar(varargin)
%DOUBLE2SDPVAR Wrap a numeric matrix as a (constant) sdpvar object
%
%   Creates the object directly from the struct template: no variable is
%   registered, so no session is required.

sys.basis = varargin{1}(:);
sys.lmi_variables = [];
sys.dim = size(varargin{1});
sys.typeflag = 0;
sys.savedata = [];
sys.extra = [];
sys.extra.expanded = [];
sys.extra.opname = '';
sys.extra.createTime = '';
sys.conicinfo = [0 0];
sys.originalbasis = 'unknown';
sys.sess = [];
sys.name = '';
sys = sdpvar(sys);
