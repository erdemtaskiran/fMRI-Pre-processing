% P3a: Skull Stripping
% Create skull-stripped bias-corrected anatomical image using tissue segmentations
% Modified for BIDS structure
clear

% Add SPM12 to path if needed
% addpath('/path/to/spm12');  % Uncomment and set your path if SPM isn't loaded
spm('defaults', 'FMRI');
spm_jobman('initcfg');

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

clear matlabbatch

for subji = 1:length(subjfolder)
    fprintf('Setting up skull stripping for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    anat_dir = [bids_root '/' subj_id '/anat'];
    
    % Input files from P1 segmentation (adapted for BIDS naming)
    bias_corrected_file = fullfile(anat_dir, ['m' subj_id '_T1w.nii']);  % Bias-corrected anatomical
    gm_file = fullfile(anat_dir, ['c1' subj_id '_T1w.nii']);             % Gray matter
    wm_file = fullfile(anat_dir, ['c2' subj_id '_T1w.nii']);             % White matter  
    csf_file = fullfile(anat_dir, ['c3' subj_id '_T1w.nii']);            % CSF
    
    % Check if all required files exist
    if exist(bias_corrected_file, 'file') && exist(gm_file, 'file') && ...
       exist(wm_file, 'file') && exist(csf_file, 'file')
        
        fprintf('  All segmentation files found\n');
        
        % Set up Image Calculator job for skull stripping
        matlabbatch{subji}.spm.util.imcalc.input{1,1} = [bias_corrected_file ',1'];
        matlabbatch{subji}.spm.util.imcalc.input{2,1} = [gm_file ',1'];
        matlabbatch{subji}.spm.util.imcalc.input{3,1} = [wm_file ',1'];
        matlabbatch{subji}.spm.util.imcalc.input{4,1} = [csf_file ',1'];
        
        % Output filename: skull-stripped bias-corrected image (BIDS naming)
        matlabbatch{subji}.spm.util.imcalc.output = ['ss_m' subj_id '_T1w'];
        matlabbatch{subji}.spm.util.imcalc.outdir = {anat_dir};
        
        % Expression: Multiply bias-corrected image by brain mask
        % (GM + WM + CSF) > 0.5 creates a brain mask, then multiply by original image
        matlabbatch{subji}.spm.util.imcalc.expression = 'i1.*((i2+i3+i4)>0.5)';
        
        % Calculator options (same as GitHub script)
        matlabbatch{subji}.spm.util.imcalc.var = struct('name', {}, 'value', {});
        matlabbatch{subji}.spm.util.imcalc.options.dmtx = 0;
        matlabbatch{subji}.spm.util.imcalc.options.mask = 0;
        matlabbatch{subji}.spm.util.imcalc.options.interp = 1;
        matlabbatch{subji}.spm.util.imcalc.options.dtype = 4;
        
        fprintf('  Skull stripping job configured\n');
        
    else
        fprintf('  Warning: Missing segmentation files for %s\n', subj_id);
        fprintf('    Expected files:\n');
        fprintf('      %s\n', bias_corrected_file);
        fprintf('      %s\n', gm_file);
        fprintf('      %s\n', wm_file); 
        fprintf('      %s\n', csf_file);
        
        % Remove this subject from batch if files missing
        matlabbatch{subji} = [];
    end
end

% Remove empty cells from matlabbatch
matlabbatch = matlabbatch(~cellfun('isempty', matlabbatch));

% Run the skull stripping jobs
if ~isempty(matlabbatch)
    fprintf('\nRunning skull stripping for %d subjects...\n', length(matlabbatch));
    
    try
        spm_jobman('run', matlabbatch);
        fprintf('\nP3a Skull Stripping completed successfully!\n');
        
        % Display what was created
        fprintf('\nOutput files created for each subject:\n');
        fprintf('- ss_m*_T1w.nii: Skull-stripped bias-corrected anatomical image\n');
        
        fprintf('\nWhat this does:\n');
        fprintf('1. Takes bias-corrected anatomical image (m*.nii)\n');
        fprintf('2. Creates brain mask from tissue segmentations (GM+WM+CSF > 0.5)\n');
        fprintf('3. Multiplies anatomical by mask to remove skull\n');
        fprintf('4. Results in clean brain-only image for coregistration\n');
        
        fprintf('\nProcessing chain so far:\n');
        fprintf('1. ✅ Slice-time correction: a*.nii\n');
        fprintf('2. ✅ Anatomical segmentation: c1, c2, c3, m*.nii\n');
        fprintf('3. ✅ Realignment: rp_*.txt, mean*.nii\n');
        fprintf('4. ✅ Head motion QC: Q3a + Q3b completed\n');
        fprintf('5. ✅ Skull stripping: ss_m*.nii\n');
        
        fprintf('\nNext step: P3b Coregistration (functional to skull-stripped anatomical)\n');
        
        % Verify output files were created
        fprintf('\nVerifying skull-stripped files were created:\n');
        for subji = 1:length(subjfolder)
            subj_id = subjfolder(subji).name;
            skull_stripped_file = [bids_root '/' subj_id '/anat/ss_m' subj_id '_T1w.nii'];
            if exist(skull_stripped_file, 'file')
                fprintf('✅ %s: skull-stripped file created\n', subj_id);
            else
                fprintf('❌ %s: skull-stripped file NOT found\n', subj_id);
            end
        end
        
    catch ME
        fprintf('Error during skull stripping: %s\n', ME.message);
        fprintf('Check that all segmentation files exist from P1\n');
    end
    
else
    fprintf('No subjects have the required segmentation files!\n');
    fprintf('Make sure P1 (anatomical segmentation) was completed successfully\n');
end

fprintf('\nNote: Skull-stripped image will be used as reference for coregistration\n');
fprintf('This improves functional-anatomical alignment by removing skull interference\n');