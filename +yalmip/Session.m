classdef Session < handle
%SESSION Stateless YALMIP session (variable registry, solutions, duals).
%   See dev/REFACTORING_STATE.md and MIGRATION.md.

    properties
        monomtable = []
        hashedmonomtable = []
        hash = []
        boundlist = []
        variabletype = []
        intVariables = []
        binVariables = []
        tempintVariables = []
        tempbinVariables = []
        semicontVariables = []
        uncVariables = []
        parVariables = []
        extVariables = []
        auxVariables = []
        auxVariablesW = []
        logicVariables = []
        complexpair = []
        internalconstraints = {}
        ExtendedMap = []
        ExtendedMapHashes = []
        DependencyMap = []
        DependencyMap_i = []
        DependencyMap_j = []
        DependencyMapUser = []
        sosid = 0
        sos_index = []
        sos_data = []
        sos_ParV = []
        sos_Q = []
        sos_v = []
        optSolution = {}
        activeSolution = 1
        nonCommutingTable = []
        nonHermitiannonCommutingTable = []
        containsSemivar = false
        LMIid = 0
        duals_index = []
        duals_data = []
        duals_associated_index = []
        duals_associated_data = []
        preferedSolver = ''
        solverCache = []
        variableNames = {}
        variableNameIndex = []
    end

    properties (Access = private)
        gemFound = []
    end

    methods
        function S = Session()
            S.monomtable = spalloc(0,0,0);
            S.hashedmonomtable = [];
            S.hash = [];
            S.boundlist = [];
            S.variabletype = spalloc(0,0,0);
            S.intVariables = [];
            S.binVariables = [];
            S.tempintVariables = [];
            S.tempbinVariables = [];
            S.semicontVariables = [];
            S.uncVariables = [];
            S.parVariables = [];
            S.extVariables = [];
            S.auxVariables = [];
            S.auxVariablesW = [];
            S.logicVariables = [];
            S.complexpair = [];
            S.internalconstraints = {};
            S.ExtendedMap = [];
            S.ExtendedMapHashes = [];
            S.DependencyMap = sparse(0);
            S.DependencyMap_i = [];
            S.DependencyMap_j = [];
            S.DependencyMapUser = sparse(0);
            S.sosid = 0;
            S.sos_index = [];
            S.sos_data = [];
            S.sos_ParV = [];
            S.sos_Q = [];
            S.sos_v = [];
            S.optSolution = {struct('info','Initialized by YALMIP','variables',[],'optvar',[],'values',[])};
            S.activeSolution = 1;
            S.nonCommutingTable = [];
            S.nonHermitiannonCommutingTable = [];
            S.containsSemivar = false;
            S.LMIid = 0;
            S.duals_index = [];
            S.duals_data = [];
            S.duals_associated_index = [];
            S.duals_associated_data = [];
            S.preferedSolver = '';
            S.solverCache = struct('CACHED_SOLVERS',[],'allsolvers',[],'EXISTTIME',[],'NCHECKS',[]);
            S.variableNames = {};
            S.variableNameIndex = [];
        end

        % ----- variable creation -----------------------------------------
        function X = sdpvar(obj, varargin)
            X = sdpvar(varargin{:}, 'session', {obj});
        end

        function X = intvar(obj, varargin)
            X = intvarCore(obj, varargin{:});
        end

        function X = binvar(obj, varargin)
            X = binvarCore(obj, varargin{:});
        end

        function X = uncvar(obj, varargin)
            X = uncvarCore(obj, varargin{:});
        end

        function X = semivar(obj, varargin)
            X = semivarCore(obj, varargin{:});
        end

        function X = parvar(obj, varargin)
            X = parvarCore(obj, varargin{:});
        end

        function varargout = define(obj, varargin)
            varargout = yalmip.dispatch(obj, varargin{:});
        end

        % ----- name registry ----------------------------------------------
        function registerVariablenames(obj, displayname, ids)
            for k = 1:numel(ids)
                obj.variableNames{ids(k)} = displayname;
                obj.variableNameIndex(ids(k)) = k;
            end
        end

        function n = getvariablenames(obj, ids)
            n = cell(length(ids),1);
            for k = 1:length(ids)
                nm = '';
                idx = 0;
                if ids(k) >= 1 && ids(k) <= length(obj.variableNames)
                    nm = obj.variableNames{ids(k)};
                    if ids(k) <= length(obj.variableNameIndex)
                        idx = obj.variableNameIndex(ids(k));
                    end
                end
                if isempty(nm)
                    n{k} = ['internal(' num2str(ids(k)) ')'];
                elseif idx > 1
                    n{k} = sprintf('%s(%d)', nm, idx);
                else
                    n{k} = nm;
                end
            end
        end

        % ----- state snapshots -------------------------------------------
        function s = snapshotState(obj)
            s = struct();
            f = properties(obj);
            for i = 1:numel(f)
                if strcmp(f{i},'gemFound'); continue; end
                s.(f{i}) = obj.(f{i});
            end
        end

        function restoreState(obj, s)
            f = properties(obj);
            for i = 1:numel(f)
                if strcmp(f{i},'gemFound'); continue; end
                if isfield(s,f{i})
                    obj.(f{i}) = s.(f{i});
                end
            end
        end

        function r = gemInPath(obj, varargin)
            if nargin >= 2
                switch varargin{1}
                    case 'clear'
                        obj.gemFound = [];
                    otherwise
                        disp('Invalid command for gemInPath');
                end
                return;
            end
            if isempty(obj.gemFound)
                obj.gemFound = (exist('gem', 'class') == 8);
            end
            r = logical(obj.gemFound);
        end

        function c = evalSnapshot(obj)
            c = struct();
            c.monomtable = obj.monomtable;
            c.variabletype = obj.variabletype;
            sol = obj.optSolution{obj.activeSolution};
            c.variables = sol.variables;
            c.optvar = sol.optvar;
            c.values = sol.values;
            c.duals_index = obj.duals_index;
            c.duals_data = obj.duals_data;
        end

        function varargout = clearsolution(obj, varargin)
            varargout = yalmip.dispatch(obj, 'clearsolution', varargin{:});
        end

        function varargout = setmonomtable(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setmonomtable', varargin{:});
        end

        function varargout = defineVectorizedUnitary(obj, varargin)
            varargout = yalmip.dispatch(obj, 'defineVectorizedUnitary', varargin{:});
        end

        function varargout = setdependence(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setdependence', varargin{:});
        end

        function varargout = setdependenceUser(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setdependenceUser', varargin{:});
        end

        function varargout = getdependence(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getdependence', varargin{:});
        end

        function varargout = getdependenceUser(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getdependenceUser', varargin{:});
        end

        function varargout = getarguments(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getarguments', varargin{:});
        end

        function varargout = extstruct(obj, varargin)
            varargout = yalmip.dispatch(obj, 'extstruct', varargin{:});
        end

        function varargout = expvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'expvariables', varargin{:});
        end

        function varargout = rankvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'rankvariables', varargin{:});
        end

        function varargout = setnonlinearvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setnonlinearvariables', varargin{:});
        end

        function varargout = cleardual(obj, varargin)
            varargout = yalmip.dispatch(obj, 'cleardual', varargin{:});
        end

        function varargout = associatedual(obj, varargin)
            varargout = yalmip.dispatch(obj, 'associatedual', varargin{:});
        end

        function varargout = addcomplexpair(obj, varargin)
            varargout = yalmip.dispatch(obj, 'addcomplexpair', varargin{:});
        end

        function varargout = getcomplexpair(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getcomplexpair', varargin{:});
        end

        function varargout = setallsolution(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setallsolution', varargin{:});
        end

        function varargout = setvalues(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setvalues', varargin{:});
        end

        function varargout = numbersolutions(obj, varargin)
            varargout = yalmip.dispatch(obj, 'numbersolutions', varargin{:});
        end

        function varargout = selectsolution(obj, varargin)
            varargout = yalmip.dispatch(obj, 'selectsolution', varargin{:});
        end

        function varargout = setsolution(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setsolution', varargin{:});
        end

        function varargout = addauxvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'addauxvariables', varargin{:});
        end

        function varargout = addauxvariablesW(obj, varargin)
            varargout = yalmip.dispatch(obj, 'addauxvariablesW', varargin{:});
        end

        function varargout = getsolution(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getsolution', varargin{:});
        end

        function varargout = setdual(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setdual', varargin{:});
        end

        function varargout = dual(obj, varargin)
            varargout = yalmip.dispatch(obj, 'dual', varargin{:});
        end

        function varargout = clearsos(obj, varargin)
            varargout = yalmip.dispatch(obj, 'clearsos', varargin{:});
        end

        function varargout = setsos(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setsos', varargin{:});
        end

        function varargout = getsos(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getsos', varargin{:});
        end

        function varargout = getinternalsetstate(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getinternalsetstate', varargin{:});
        end

        function varargout = setinternalsetstate(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setinternalsetstate', varargin{:});
        end

        function varargout = getinternalsdpvarstate(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getinternalsdpvarstate', varargin{:});
        end

        function varargout = setinternalsdpvarstate(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setinternalsdpvarstate', varargin{:});
        end

        function varargout = setintvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setintvariables', varargin{:});
        end

        function varargout = setbinvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setbinvariables', varargin{:});
        end

        function varargout = settempintvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'settempintvariables', varargin{:});
        end

        function varargout = settempbinvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'settempbinvariables', varargin{:});
        end

        function varargout = quantvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'quantvariables', varargin{:});
        end

        function varargout = setsemicontvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setsemicontvariables', varargin{:});
        end

        function varargout = setuncvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setuncvariables', varargin{:});
        end

        function varargout = setparvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setparvariables', varargin{:});
        end

        function varargout = nonCommutingVariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'nonCommutingVariables', varargin{:});
        end

        function varargout = nonlinearvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'nonlinearvariables', varargin{:});
        end

        function varargout = addinternal(obj, varargin)
            varargout = yalmip.dispatch(obj, 'addinternal', varargin{:});
        end

        function varargout = nvars(obj, varargin)
            varargout = yalmip.dispatch(obj, 'nvars', varargin{:});
        end

        function varargout = info(obj, varargin)
            varargout = yalmip.dispatch(obj, 'info', varargin{:});
        end

        function varargout = getbounds(obj, varargin)
            varargout = yalmip.dispatch(obj, 'getbounds', varargin{:});
        end

        function varargout = setbounds(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setbounds', varargin{:});
        end

        function varargout = logicextvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'logicextvariables', varargin{:});
        end

        function varargout = addlogicvariable(obj, varargin)
            varargout = yalmip.dispatch(obj, 'addlogicvariable', varargin{:});
        end

        function varargout = setNonHermitianNonCommuting(obj, varargin)
            varargout = yalmip.dispatch(obj, 'setNonHermitianNonCommuting', varargin{:});
        end

        function varargout = solver(obj, varargin)
            varargout = yalmip.dispatch(obj, 'solver', varargin{:});
        end

        function varargout = clear(obj, varargin)
            varargout = yalmip.dispatch(obj, 'clear', varargin{:});
        end

        function varargout = nextConstraintId(obj, varargin)
            varargout = yalmip.dispatch(obj, 'lmiid', varargin{:});
        end

        function varargout = version(obj, varargin)
            varargout = yalmip.dispatch(obj, 'version', varargin{:});
        end

        function varargout = addextendedvariable(obj, varargin)
            varargout = yalmip.dispatch(obj, 'addextendedvariable', varargin{:});
        end

        function varargout = getMonomtable(obj, varargin)
            varargout = yalmip.dispatch(obj, 'monomtable', varargin{:});
        end

        function varargout = getVariabletype(obj, varargin)
            varargout = yalmip.dispatch(obj, 'variabletype', varargin{:});
        end

        function varargout = getLogicvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'logicVariables', varargin{:});
        end

        function varargout = getSetNonCommutingTable(obj, varargin)
            varargout = yalmip.dispatch(obj, 'nonCommutingTable', varargin{:});
        end

        function varargout = nextSosId(obj, varargin)
            varargout = yalmip.dispatch(obj, 'sosid', varargin{:});
        end

        function varargout = getContainsSemivar(obj, varargin)
            varargout = yalmip.dispatch(obj, 'containsSemivar', varargin{:});
        end

        function varargout = getIntvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'intvariables', varargin{:});
        end

        function varargout = getBinvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'binvariables', varargin{:});
        end

        function varargout = getAuxvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'auxvariables', varargin{:});
        end

        function varargout = getAuxvariablesW(obj, varargin)
            varargout = yalmip.dispatch(obj, 'auxvariablesW', varargin{:});
        end

        function varargout = getExtvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'extvariables', varargin{:});
        end

        function varargout = getSemicontvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'semicontvariables', varargin{:});
        end

        function varargout = getUncvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'uncvariables', varargin{:});
        end

        function varargout = getParvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'parvariables', varargin{:});
        end

        function varargout = getTempintvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'tempintvariables', varargin{:});
        end

        function varargout = getTempbinvariables(obj, varargin)
            varargout = yalmip.dispatch(obj, 'tempbinvariables', varargin{:});
        end

        function varargout = getExtendedmap(obj, varargin)
            varargout = yalmip.dispatch(obj, 'extendedmap', varargin{:});
        end

        function varargout = ver(obj, varargin)
            varargout = obj.version('ver', varargin{:});
        end

        function varargout = ConstraintID(obj, varargin)
            varargout = obj.nextConstraintId('ConstraintID', varargin{:});
        end

        function varargout = addEvalVariable(obj, varargin)
            varargout = obj.addextendedvariable('addEvalVariable', varargin{:});
        end

        function varargout = definemulti(obj, varargin)
            varargout = yalmip.dispatch(obj, 'definemulti', varargin{:});
        end
    end
end
