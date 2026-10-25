function run_stage(stagename, suites)
%RUN_STAGE Run test suites for a stage gate and compare against baseline
addpath(genpath('/media/connor/Data/YALMIP'));
addpath('/opt/mosek/11.2/toolbox/r2019b');
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
