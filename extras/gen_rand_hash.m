function r = gen_rand_hash(k,n,m);
%GEN_RAND_HASH Seeded random draw used for monomial hash keys
%
%   Stateless version: the former persistent buffer of preallocated random
%   numbers is replaced by a direct seeded draw. Values for a given seed k
%   are prefix-consistent across different draw sizes.

try
    s = rng;
    rng(k);
    r = rand(n,m);
    rng(s);
catch
    % but rng is not available in all versions...
    s = rand('state');
    rand('state',k)
    r = rand(n,m);
    rand('state',s);
end
