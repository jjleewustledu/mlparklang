classdef (Abstract) ParkLang 
	%% PARKLANG  

	%  $Revision$
 	%  was created 21-Apr-2020 13:42:51 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlparklang/src/+mlparklang.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties (Abstract)
        indicesRS
    end
    
	properties
        home = '/Users/jjlee/Box/DeepNetFCProject/PLOS1'
        label
        subjectsDir = '/Users/jjlee/Box/DeepNetFCProject/Donnas_Tumors'
    end
    
    properties (Dependent)
        allRS
        atlas
        brainmask
        Broca
        fmriLabel
        LHemis
        MLP
        rightHandedRS
        task
        Wernicke
        
        labelSampleMasked
    end
    
    methods (Static)
        function this = createAll(varargin)
            this = mlparklang.ParkLangAll(varargin{:});
        end
        function this = createRightHanded(varargin)
            this = mlparklang.ParkLangRightHanded(varargin{:});
        end
        function createAllROCFigures(lbl)
            pl = mlparklang.ParkLang.createAll('MLP', 'broca', 'label', lbl)
            pl.createPerfcurveAverages()
            pl = mlparklang.ParkLang.createAll('MLP', 'wernicke', 'label', lbl)
            pl.createPerfcurveAverages()
            pl = mlparklang.ParkLang.createAll('task', 'broca',  'label', lbl)
            pl.createPerfcurveAverages()
            pl = mlparklang.ParkLang.createAll('task', 'wernicke', 'label', lbl)
            pl.createPerfcurveAverages()
        end
        function ifc = makeAverage(ifc0)
            ifc = copy(ifc0);
            ifc.img = sum(ifc0.img, 4);
            ifc.img = ifc.img/size(ifc0.img, 4);
            ifc.fileprefix = [ifc.fileprefix '_avgt'];
        end
        function ifc = mat2ifc(dat, fp)
            %% MAT2IFC converts from Carl & Kiyun's storage conventions for BOLD to mlfourd.ImagingFormatContext.
            
            import mlfourd.ImagingFormatContext
            assert(isnumeric(dat))
            assert(ischar(fp))
            
            atlas7112b = ImagingFormatContext(fullfile(getenv('REFDIR'), '711-2B_333.4dfp.hdr'));
            atlas7112b.filesuffix = '.nii.gz';
            if ~isfile(atlas7112b.fqfilename)
                atlas7112b.save
            end
            ifc = copy(atlas7112b);
            ifc.filename = [fp '.nii.gz'];
            
            Nt = numel(dat)/prod([48 64 48]);
            img = reshape(dat, [48 64 48 Nt]);
            img = flip(flip(img, 1), 2);
            ifc.img = img;
            ifc.fsleyes(atlas7112b.fqfilename)
            ifc.save
        end
    end
    
	methods        
        
        %% GET
        
        function g = get.allRS(this)
            g = globFoldersT(fullfile(this.subjectsDir, 'RS0*'));
            g = cellfun(@(x) basename(x), g, 'UniformOutput', false);
        end
        function g = get.atlas(~)
            g = fullfile(getenv('REFDIR'), '711-2B_333.nii.gz');
            g = mlfourd.ImagingFormatContext(g);            
        end
        function g = get.brainmask(this)
            g = fullfile(this.home, 'brainmask.nii.gz');
            g = mlfourd.ImagingFormatContext(g);            
        end
        function g = get.Broca(this)
            switch this.label
                case 'neurosynth'
                    fn = 'ns_broca_b30z_333.nii.gz';
                case 'sanai'
                    fn = 'LNsanai_broca_bin.nii.gz';
                otherwise
                    error('mlparklang:ValueError', 'ParkLang.get.Broca')
            end
            g = fullfile(this.home, fn);
            g = mlfourd.ImagingFormatContext(g);
            g.img = g.img > eps;
        end
        function g = get.fmriLabel(this)
            if lstrfind(lower(this.fmri_.fileprefix), 'mlp')
                g = 'MLP';
                return
            end
            if lstrfind(lower(this.fmri_.fileprefix), 'task')
                g = 'Task';
                return
            end
            error('mlparklang:ValueError', 'ParkLang.get.fmriLabel')
        end
        function g = get.LHemis(this)
            g = fullfile(this.home, 'LHemis.nii.gz');
            g = mlfourd.ImagingFormatContext(g);
        end
        function g = get.MLP(this)
            g = fullfile(this.home, 'LNMLP_MAP_v2.nii.gz');
            g = mlfourd.ImagingFormatContext(g);
        end
        function g = get.rightHandedRS(~)
            idx = {3 4 7 9 11 12 14 17 18 19 20 21 23 24 29 30 32 33 35 40 42 43 44};
            g = cellfun(@(x) sprintf('RS%03i', x), idx, 'UniformOutput', false);
        end
        function g = get.task(this)
            g = fullfile(this.home, 'LNtask_MAP.nii.gz');
            g = mlfourd.ImagingFormatContext(g);
        end
        function g = get.Wernicke(this)
            switch this.label
                case 'neurosynth'
                    fn = 'ns_wernicke_b30z_333.nii.gz';
                case 'sanai'
                    fn = 'LNsanai_wernicke_bin.nii.gz';
                otherwise
                    error('mlparklang:ValueError', 'ParkLang.get.Wernicke')
            end
            g = fullfile(this.home, fn);
            g = mlfourd.ImagingFormatContext(g); 
            g.img = g.img > eps;
        end        
        
        function g = get.labelSampleMasked(this)
            g = this.roi().img(this.LHemis.img ~= 0);
            g = this.reshape2vec(g);
            this.assert0to1(g);
        end
        
        %%
        
        function createPerfcurveAverages(this, varargin)
            if lstrfind(lower(this.roi_.fileprefix), 'broca')
                REG = 'Broca''s area';
            end
            if lstrfind(lower(this.roi_.fileprefix), 'wern')
                REG = 'Wernicke''s area';
            end
            
            [x_fmri,y_fmri,~,auc_fmri] = this.perfcurveAverages(varargin{:});
            
            figure;
            p1 = plot(x_fmri, y_fmri, '-', 'LineWidth', 3);
            hold on
            rline = refline(1, 0);
            rline.Color = 0.5*[1 1 1];
            hold off
            
            pbaspect([1 1 1])
            set(gca, 'FontSize', 12)
            legend([p1], ...
                   sprintf('%s (100 frames) AUC = %6.4f', this.fmriLabel, auc_fmri))
            set(legend, 'Location', 'SouthEast')
            set(legend, 'FontSize', 14)
            legend('boxoff')
            xlabel('False positive rate', 'FontSize', 16); 
            ylabel('True positive rate', 'FontSize', 16);
            title( ...
                {sprintf('ROC for %s in %s', this.fmriLabel, REG); ' '}, ...
                'FontSize', 14)
        end
        function ifc = fmri(this, varargin)
            ip = inputParser;
            addParameter(ip, 'makeAveraged', false, @islogical)
            addParameter(ip, 'showFreeview', false, @islogical)
            addParameter(ip, 'showFsleyes', false, @islogical)
            addParameter(ip, 'showAtlas', true, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ifc = copy(this.fmri_);
            if ipr.makeAveraged
                ifc = this.makeAverage(ifc);
            end
            if ipr.showFsleyes
                if ipr.showAtlas
                    ifc.fsleyes(this.atlas.fqfilename)
                else
                    ifc.fsleyes()
                end
            end
            if ipr.showFreeview
                if ipr.showAtlas
                    ifc.freeview(this.atlas.fqfilename)
                else
                    ifc.freeview()
                end
            end
        end
        function [x,y,t,auc] = perfcurveAverages(this, varargin)
            labelSmpl = this.labelSampleMasked; % for one patient
            atm = this.createAverageTestMasked();
            testSmpl = atm.img(this.LHemis.img ~= 0);
            [x,y,t,auc] = perfcurve( ...
                labelSmpl' > 0, ...
                testSmpl, ...
                true, varargin{:});
        end
        function ifc = productMap(this, varargin)
            if lstrfind(this.fmri_.fileprefix, 'MLP')
                other = this.makeAverage(this.task);
            else
                other = this.makeAverage(this.MLP);
            end
            ifc = this.fmri('makeAveraged', true);
            ifc.img = ifc.img .* other.img;
            ifc.fileprefix = ['prod_' ifc.fileprefix '_' other.fileprefix];
        end
        function roc(this, varargin)
        end
        function ifc = roi(this, varargin)
            ifc = this.roi_;
        end
        function workbench(this, varargin)
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        fmri_
        roi_
    end
    
    methods (Access = protected)		  
 		function this = ParkLang(varargin)
 			%% PARKLANG
 			%  @param fMRI in {'MLP' 'task'}.
            %  @param ROI in {'brain' 'Broca' 'Wernicke'}.
 			
            ip = inputParser;
            addRequired(ip, 'fMRI', @(x) lstrfind({'mlp' 'task'}, lower(x)))
            addRequired(ip, 'ROI', @(x) lstrfind({'brain' 'broca' 'wernicke'}, lower(x)))
            addParameter(ip, 'label', 'neurosynth', @(x) lstrfind({'neurosynth' 'sanai'}, lower(x)))
            parse(ip, varargin{:})
            ipr = ip.Results;            
            
            this.label = lower(ipr.label);
            switch lower(ipr.fMRI)
                case 'mlp'
                    this.fmri_ = copy(this.MLP);
                case 'task'
                    this.fmri_ = copy(this.task);
            end
            this.fmri_.img = this.fmri_.img(:,:,:,this.indicesRS);
            switch lower(ipr.ROI)
                case 'broca'
                    this.roi_ = copy(this.Broca);
                case 'wernicke'
                    this.roi_ = copy(this.Wernicke);
                case 'brain'
                    this.roi_ = copy(this.brainmask);
            end
            this.roi_.img = this.roi_.img > eps('single');
        end
        
        function assert0to1(~, img)
            assert(dipmin(img) == 0);
            assert(dipmax(img) <= 1);
        end
        function fmri = createAverageTestMasked(this)
            fmri = this.fmri('makeAveraged', true);
            fmri.fileprefix = [fmri.fileprefix '_avgt_lhemis'];
            fmri.img = fmri.img .* this.LHemis.img;

        end
        function v = reshape2vec(~, img)
            v = reshape(img, [1 numel(img)]);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

