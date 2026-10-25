function r = rand_hash(k,n,m);
%RAND_HASH Seeded random draw used for hash keys
%
%   Stateless version: the former persistent batch of preallocated random
%   numbers is replaced by a direct seeded draw. Values for a given seed k
%   are prefix-consistent across different draw sizes.

try
    s = rng;
    rng(k,'twister');
    r = rand(n,m);
    rng(s);
catch
    % Old versions of MATLAB
    s = rand('state');
    rand('state',k)
    r = rand(n,m);
    rand('state',s);
end
