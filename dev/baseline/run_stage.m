function run_stage(stagename, suites, withMPT)
%RUN_STAGE Run test suites for a stage gate and compare against baseline
%
% Solver policy: SeDuMi and SDPT3 are always on the path - they only add
% backends and they fixed nine baseline failures. MPT3 is opt-in (third
% argument) because its MPT2-compatibility layer defines legacy bare names
% (polytope, chebyball, vertices, ...) that YALMIP's robust and pwa code also
% calls with plain matrices; with MPT permanently on the path those calls
% silently switch to MPT and the 'robust' suite loses five tests. Run the
% 'mpt' suite in its own process with withMPT = true.
% Everything is added with '-end' so no solver can shadow YALMIP.
if nargin < 3, withMPT = false; end
addpath(genpath('/media/connor/Data/YALMIP'));
addpath('/opt/mosek/11.2/toolbox/r2019b');

addSolverTree({'/opt/sedumi', '/home/connor/yalmip-solvers/sedumi'});
addSolverTree({'/opt/sdpt3', '/home/connor/yalmip-solvers/sdpt3'});
if withMPT
    mptRoot = firstExisting({'/opt/mpt3', '/home/connor/yalmip-solvers/mpt3/source/mpt'});
    if ~isempty(mptRoot)
        addpath(genpath(mptRoot), '-end');
        if exist('mpt_init', 'file')
            try
                evalc('mpt_init');
            catch
            end
            % mpt_init re-adds the MPT tree at the front of the path
            addpath(genpath(fileparts(which('mpt_init'))), '-end');
        end
    end
end

cd('/media/connor/Data/YALMIP');
fid = fopen(fullfile('dev','baseline',[stagename '_results.txt']),'w');
totalp = 0; totalf = 0; totale = 0;
for i = 1:numel(suites)
    s = suites{i};
    try
        r = runxunittests(fullfile('dev','tests',s), fullfile('dev','baseline',[stagename '_' s '.xml']));
        p = [r.Passed]; inc = [r.Incomplete];
        np = nnz(p); nf = nnz(~p & ~inc); ni = nnz(inc);
        fprintf('STAGE_RESULT %s %s passed=%d failed=%d incomplete=%d\n', stagename, s, np, nf, ni);
        fprintf(fid,'STAGE_RESULT %s %s passed=%d failed=%d incomplete=%d\n', stagename, s, np, nf, ni);
        totalp = totalp + np; totalf = totalf + nf; totale = totale + ni;
    catch e
        fprintf('STAGE_ERROR %s %s: %s | %s\n', stagename, s, e.identifier, e.message);
        fprintf(fid,'STAGE_ERROR %s %s: %s | %s\n', stagename, s, e.identifier, e.message);
    end
end
fprintf('STAGE_TOTAL %s passed=%d failed=%d incomplete=%d\n', stagename, totalp, totalf, totale);
fprintf(fid,'STAGE_TOTAL %s passed=%d failed=%d incomplete=%d\n', stagename, totalp, totalf, totale);
fclose(fid);
exit(0);
end

function d = firstExisting(candidates)
d = '';
for i = 1:numel(candidates)
    if isfolder(candidates{i})
        d = candidates{i};
        return
    end
end
end

function addSolverTree(candidates)
d = firstExisting(candidates);
if ~isempty(d)
    addpath(genpath(d), '-end');
end
end
