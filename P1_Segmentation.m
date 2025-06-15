% P1: Anatomical image segmentation
% Segment anatomical images into GM, WM, CSF and generate deformation fields
% Modified for BIDS structure
clear 

% Add SPM12 to path if needed
% addpath('/path/to/spm12');  % Uncomment and set your path if SPM isn't loaded
spm('defaults', 'FMRI');
spm_jobman('initcfg');

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Get TPM template path
tpm_path = fullfile(spm('Dir'), 'tpm', 'TPM.nii');

clear matlabbatch

for subji = 1:length(subjfolder)
    fprintf('Setting up segmentation for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Get anatomical file path
    anat_path = [bids_root '/' subj_id '/anat/' subj_id '_T1w.nii.gz'];
    
    % Check if compressed file exists, if not try uncompressed
    if ~exist(anat_path, 'file')
        anat_path = [bids_root '/' subj_id '/anat/' subj_id '_T1w.nii'];
    end
    
    if exist(anat_path, 'file')
        % Handle compressed files - unzip for SPM processing % Since I got
        % the functional images after dicm2nii transformation in zip file
        % maybe you might get it with the same way. It is no problem to use
        % this loop for working properly I really sugest ot use it. 
        if endsWith(anat_path, '.gz')
            fprintf('  Unzipping anatomical file...\n');
            temp_anat = gunzip(anat_path);
            anat_path = temp_anat{1};
        end
        
        % Set up segmentation job for this subject
        matlabbatch{subji}.spm.spatial.preproc.channel.vols = {[anat_path ',1']};
        matlabbatch{subji}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{subji}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{subji}.spm.spatial.preproc.channel.write = [0 1];  % save bias corrected images
        
        % Tissue 1: Gray Matter
        matlabbatch{subji}.spm.spatial.preproc.tissue(1).tpm = {[tpm_path ',1']};
        matlabbatch{subji}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{subji}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{subji}.spm.spatial.preproc.tissue(1).warped = [1 1];  % save segmented images in MNI space
        
        % Tissue 2: White Matter
        matlabbatch{subji}.spm.spatial.preproc.tissue(2).tpm = {[tpm_path ',2']};
        matlabbatch{subji}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{subji}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{subji}.spm.spatial.preproc.tissue(2).warped = [1 1];   % save segmented images in MNI space
        
        % Tissue 3: CSF
        matlabbatch{subji}.spm.spatial.preproc.tissue(3).tpm = {[tpm_path ',3']};
        matlabbatch{subji}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{subji}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{subji}.spm.spatial.preproc.tissue(3).warped = [1 1];   % save segmented images in MNI space
        
        % Tissue 4: Bone
        matlabbatch{subji}.spm.spatial.preproc.tissue(4).tpm = {[tpm_path ',4']};
        matlabbatch{subji}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{subji}.spm.spatial.preproc.tissue(4).native = [0 0];
        matlabbatch{subji}.spm.spatial.preproc.tissue(4).warped = [0 0];
        
        % Tissue 5: Soft tissue
        matlabbatch{subji}.spm.spatial.preproc.tissue(5).tpm = {[tpm_path ',5']};
        matlabbatch{subji}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{subji}.spm.spatial.preproc.tissue(5).native = [0 0];
        matlabbatch{subji}.spm.spatial.preproc.tissue(5).warped = [0 0];
        
        % Tissue 6: Air/background
        matlabbatch{subji}.spm.spatial.preproc.tissue(6).tpm = {[tpm_path ',6']};
        matlabbatch{subji}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{subji}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{subji}.spm.spatial.preproc.tissue(6).warped = [0 0];
        
        % Warping options
        matlabbatch{subji}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{subji}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{subji}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{subji}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{subji}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{subji}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{subji}.spm.spatial.preproc.warp.write = [0 1];   % save deformation field maps
        matlabbatch{subji}.spm.spatial.preproc.warp.vox = NaN;
        matlabbatch{subji}.spm.spatial.preproc.warp.bb = [NaN NaN NaN; NaN NaN NaN];
        
        fprintf('  Job configured successfully\n');
    else
        fprintf('  Warning: No anatomical file found for %s\n', subj_id);
    end
end

% Run the segmentation jobs
fprintf('\nRunning segmentation for %d subjects...\n', length(matlabbatch));
fprintf('This may take several minutes per subject...\n');

try
    spm_jobman('run', matlabbatch);
    fprintf('\nP1 Segmentation completed successfully!\n');
    
    % Display what was created
    fprintf('\nOutput files created for each subject:\n');
    fprintf('- c1*.nii: Gray matter segmentation (native space)\n');
    fprintf('- c2*.nii: White matter segmentation (native space)\n');
    fprintf('- c3*.nii: CSF segmentation (native space)\n');
    fprintf('- wc1*.nii: Gray matter segmentation (MNI space)\n');
    fprintf('- wc2*.nii: White matter segmentation (MNI space)\n');
    fprintf('- wc3*.nii: CSF segmentation (MNI space)\n');
    fprintf('- m*.nii: Bias-corrected anatomical image\n');
    fprintf('- y_*.nii: Forward deformation field\n');
    
catch ME
    fprintf('Error during segmentation: %s\n', ME.message);
    fprintf('Check that all anatomical files exist and are valid\n');
end

fprintf('\nNext step: Run Q2 to check segmentation quality\n');