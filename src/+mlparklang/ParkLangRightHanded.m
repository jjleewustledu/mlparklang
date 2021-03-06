classdef ParkLangRightHanded < mlparklang.ParkLang
	%% PARKLANGRIGHTHANDED  

	%  $Revision$
 	%  was created 21-Apr-2020 20:08:58 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlparklang/src/+mlparklang.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
        indicesRS
    end
    
    methods        
        function g = get.indicesRS(this)
            [~,g] = intersect(this.allRS, this.rightHandedRS);
        end	  
 		function this = ParkLangRightHanded(varargin)
 			%% PARKLANGRIGHTHANDED
 			%  @param fMRI in {'MLP' 'task'}.
            %  @param ROI in {'brain' 'Broca' 'Wernicke'}.

 			this = this@mlparklang.ParkLang(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

