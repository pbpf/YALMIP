function y = InstantiateElementWiseUnitary(funName,varargin);
S = sdpvarargumentsession(varargin{:});

args = varargin{1};
dims = size(args);
y = S.defineVectorizedUnitary(funName,varargin{:});
y = reshape(y,dims);   
