% P3b: Coregistration
% Coregister functional images to skull-stripped anatomical image
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
    fprintf('Setting up coregistration for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Check if skull-stripped anatomical exists
    skull_stripped_anat = [bids_root '/' subj_id '/anat/ss_m' subj_id '_T1w.nii'];
    
    if ~exist(skull_stripped_anat, 'file')
        fprintf('  Warning: Skull-stripped anatomical not found for %s\n', subj_id);
        fprintf('    Expected: %s\n', skull_stripped_anat);
        continue;
    end
    
    % Get all slice-time corrected functional runs
    func_files = dir([bids_root '/' subj_id '/func/a' subj_id '_task-*_bold.nii']);
    
    if isempty(func_files)
        fprintf('  Warning: No slice-time corrected functional files found for %s\n', subj_id);
        continue;
    end
    
    % Process each functional run separately
    for runi = 1:length(func_files)
        job_counter = job_counter + 1;
        
        func_basename = func_files(runi).name;
        func_path = [bids_root '/' subj_id '/func/' func_basename];
        
        % Extract basename without extension for mean file
        [~, basename_no_ext, ~] = fileparts(func_basename);
        mean_func_file = [bids_root '/' subj_id '/func/mean' basename_no_ext '.nii'];
        
        fprintf('  Setting up run %d/%d: %s\n', runi, length(func_files), func_basename);
        
        % Check if mean functional image exists
        if ~exist(mean_func_file, 'file')
            fprintf('    Warning: Mean functional file not found: %s\n', mean_func_file);
            job_counter = job_counter - 1;
            continue;
        end
        
        try
            % Get all volumes in this functional run
            v = spm_vol(func_path);
            fprintf('    Found %d volumes to coregister\n', length(v));
            
            % Set up coregistration job
            % Reference: skull-stripped anatomical
            matlabbatch{job_counter}.spm.spatial.coreg.estimate.ref = {[skull_stripped_anat ',1']};
            
            % Source: mean functional image for this run
            matlabbatch{job_counter}.spm.spatial.coreg.estimate.source = {[mean_func_file ',1']};
            
            % Other images: all volumes in this functional run
            for imagei = 1:length(v)
                matlabbatch{job_counter}.spm.spatial.coreg.estimate.other{imagei,1} = ...
                    [func_path ',' num2str(imagei)];
            end
            
            % Coregistration options (same as GitHub script)
            matlabbatch{job_counter}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
            matlabbatch{job_counter}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
            matlabbatch{job_counter}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            matlabbatch{job_counter}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
            
            fprintf('    Coregistration job configured successfully\n');
            
        catch ME
            fprintf('    Error setting up coregistration: %s\n', ME.message);
            job_counter = job_counter - 1;
        end
    end
end

% Run the coregistration jobs
if job_counter > 0
    fprintf('\nRunning coregistration for %d functional runs...\n', job_counter);
    fprintf('This may take several minutes per run...\n');
    
    try
        spm_jobman('run', matlabbatch);
        fprintf('\nP3b Coregistration completed successfully!\n');
        
        % Display what was accomplished
        fprintf('\nWhat coregistration did:\n');
        fprintf('1. Used skull-stripped anatomical as reference (ss_m*.nii)\n');
        fprintf('2. Aligned mean functional image to anatomical\n');
        fprintf('3. Applied same transformation to all volumes in each run\n');
        fprintf('4. Used normalized mutual information (NMI) cost function\n');
        fprintf('5. Optimized functional-anatomical alignment\n');
        
        fprintf('\nProcessing chain so far:\n');
        fprintf('1. ✅ Slice-time correction: a*.nii\n');
        fprintf('2. ✅ Anatomical segmentation: c1, c2, c3, m*.nii\n');
        fprintf('3. ✅ Realignment: rp_*.txt, mean*.nii\n');
        fprintf('4. ✅ Head motion QC: Q3a + Q3b completed\n');
        fprintf('5. ✅ Skull stripping: ss_m*.nii\n');
        fprintf('6. ✅ Coregistration: Functional aligned to anatomical\n');
        
        fprintf('\nNext step: Q4 - Check coregistration quality\n');
        
        % Note about MVPA-friendly processing
        fprintf('\nMVPA Notes:\n');
        fprintf('- Functional data remains unsmoothed ✅\n');
        fprintf('- Spatial patterns preserved ✅\n');
        fprintf('- Motion corrected and aligned ✅\n');
        fprintf('- Ready for normalization (P4) ✅\n');
        
    catch ME
        fprintf('Error during coregistration: %s\n', ME.message);
        fprintf('Check that skull-stripped anatomical and mean functional files exist\n');
    end
    
else
    fprintf('No functional runs found to coregister!\n');
    fprintf('Check that:\n');
    fprintf('1. Skull-stripped anatomical files exist (ss_m*.nii)\n');
    fprintf('2. Slice-time corrected functional files exist (a*.nii)\n');
    fprintf('3. Mean functional files exist (mean*.nii)\n');
end

fprintf('\nNote: Coregistration aligns functional and anatomical images\n');
fprintf('This enables accurate spatial normalization in the next step (P4)\n');