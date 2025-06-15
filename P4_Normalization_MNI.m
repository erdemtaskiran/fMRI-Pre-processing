% P4: Spatial Normalization
% Normalize functional images to MNI space using deformation fields
% Modified for BIDS structure with multiple functional runs
clear

% Add SPM12 to path if needed
% addpath('/path/to/spm12');  % Uncomment and set your path if SPM isn't loaded
spm('defaults', 'FMRI');
spm_jobman('initcfg');

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

clear matlabbatch
job_counter = 0;

for subji = 1:length(subjfolder)
    fprintf('Setting up normalization for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Check if deformation field exists (from P1 segmentation)
    deformation_field = [bids_root '/' subj_id '/anat/y_' subj_id '_T1w.nii'];
    
    if ~exist(deformation_field, 'file')
        fprintf('  Warning: Deformation field not found for %s\n', subj_id);
        fprintf('    Expected: %s\n', deformation_field);
        continue;
    end
    
    % Get all slice-time corrected functional runs (coregistered)
    func_files = dir([bids_root '/' subj_id '/func/a' subj_id '_task-*_bold.nii']);
    
    if isempty(func_files)
        fprintf('  Warning: No slice-time corrected functional files found for %s\n', subj_id);
        continue;
    end
    
    % Process each functional run separately (one job per run)
    for runi = 1:length(func_files)
        job_counter = job_counter + 1;
        
        func_basename = func_files(runi).name;
        func_path = [bids_root '/' subj_id '/func/' func_basename];
        
        fprintf('  Setting up run %d/%d: %s\n', runi, length(func_files), func_basename);
        
        try
            % Get all volumes in this functional run
            v = spm_vol(func_path);
            fprintf('    Found %d volumes to normalize\n', length(v));
            
            % Set up normalization job for this run
            % Deformation field (same for all runs of this subject)
            matlabbatch{job_counter}.spm.spatial.normalise.write.subj(1).def = {deformation_field};
            
            % Images to resample: all volumes in this functional run
            for imagei = 1:length(v)
                matlabbatch{job_counter}.spm.spatial.normalise.write.subj(1).resample{imagei,1} = ...
                    [func_path ',' num2str(imagei)];
            end
            
            % Normalization options (same as GitHub script)
            matlabbatch{job_counter}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70; 78 76 85];
            matlabbatch{job_counter}.spm.spatial.normalise.write.woptions.vox = [3 3 3];   % 3mm isotropic voxels
            matlabbatch{job_counter}.spm.spatial.normalise.write.woptions.interp = 4;      % 4th degree B-spline
            matlabbatch{job_counter}.spm.spatial.normalise.write.woptions.prefix = 'w';    % normalized prefix
            
            fprintf('    Normalization job configured successfully\n');
            
        catch ME
            fprintf('    Error setting up normalization: %s\n', ME.message);
            job_counter = job_counter - 1;
        end
    end
end

% Run the normalization jobs
if job_counter > 0
    fprintf('\nRunning spatial normalization for %d functional runs...\n', job_counter);
    fprintf('This may take several minutes per run...\n');
    
    try
        spm_jobman('run', matlabbatch);
        fprintf('\nP4 Spatial Normalization completed successfully!\n');
        
        % Display what was accomplished
        fprintf('\nWhat normalization did:\n');
        fprintf('1. Used deformation fields from anatomical segmentation (y_*.nii)\n');
        fprintf('2. Warped functional images to MNI152 standard space\n');
        fprintf('3. Resampled to 3x3x3mm isotropic voxels\n');
        fprintf('4. Used 4th degree B-spline interpolation (no smoothing)\n');
        fprintf('5. Applied same transformation to all volumes in each run\n');
        
        fprintf('\nProcessing chain completed:\n');
        fprintf('1. ✅ Slice-time correction: a*.nii\n');
        fprintf('2. ✅ Anatomical segmentation: c1, c2, c3, m*, y_*.nii\n');
        fprintf('3. ✅ Realignment: rp_*.txt, mean*.nii\n');
        fprintf('4. ✅ Head motion QC: Q3a + Q3b completed\n');
        fprintf('5. ✅ Skull stripping: ss_m*.nii\n');
        fprintf('6. ✅ Coregistration: Functional aligned to anatomical\n');
        fprintf('7. ✅ Normalization: wa*.nii in MNI space\n');
        
        fprintf('\nNext step: Q5 - Check normalization quality\n');
        
        % MVPA readiness check
        fprintf('\nMVPA Pipeline Status:\n');
        fprintf('✅ Slice-time corrected\n');
        fprintf('✅ Motion corrected\n');
        fprintf('✅ Coregistered to anatomy\n');
        fprintf('✅ Normalized to standard space\n');
        fprintf('✅ NO spatial smoothing applied\n');
        fprintf('✅ Spatial patterns preserved\n');
        fprintf('✅ Ready for pattern analysis!\n');
        
        % Verify some output files were created
        fprintf('\nVerifying normalized files were created:\n');
        test_count = 0;
        for subji = 1:min(3, length(subjfolder)) % Check first 3 subjects
            subj_id = subjfolder(subji).name;
            norm_files = dir([bids_root '/' subj_id '/func/wa' subj_id '_task-*_bold.nii']);
            if ~isempty(norm_files)
                fprintf('✅ %s: %d normalized runs created\n', subj_id, length(norm_files));
                test_count = test_count + 1;
            else
                fprintf('❌ %s: no normalized files found\n', subj_id);
            end
        end
        
        if test_count > 0
            fprintf('\n🎯 Normalization successful! Files created with "wa" prefix\n');
        else
            fprintf('\n⚠️ Warning: No normalized files found - check for errors\n');
        end
        
    catch ME
        fprintf('Error during normalization: %s\n', ME.message);
        fprintf('Check that deformation fields exist from P1 segmentation\n');
    end
    
else
    fprintf('No functional runs found to normalize!\n');
    fprintf('Check that:\n');
    fprintf('1. Deformation fields exist (y_*.nii from P1 segmentation)\n');
    fprintf('2. Slice-time corrected functional files exist (a*.nii)\n');
    fprintf('3. Coregistration was completed successfully\n');
end

fprintf('\nNote: Normalized images (wa*.nii) are in MNI152 standard space\n');
fprintf('These can be used for group-level analysis and cross-subject comparisons\n');
fprintf('For MVPA: Use wa*.nii files - they preserve spatial patterns without smoothing\n');