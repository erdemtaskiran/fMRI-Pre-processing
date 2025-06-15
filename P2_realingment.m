% P2: Functional images realign (on slice-time corrected data)
% Align all slice-time corrected functional images to the first image and estimate motion parameters
% Modified for BIDS structure with slice-time corrected a*.nii files
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
    fprintf('Setting up realignment for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Get all slice-time corrected functional runs (a*.nii files)
    func_files = dir([bids_root '/' subj_id '/func/a' subj_id '_task-*_bold.nii']);
    
    if isempty(func_files)
        fprintf('  Warning: No slice-time corrected files found for %s\n', subj_id);
        fprintf('  Looking for a*.nii files...\n');
        continue;
    end
    
    % Process each functional run separately
    for runi = 1:length(func_files)
        job_counter = job_counter + 1;
        
        func_path = [bids_root '/' subj_id '/func/' func_files(runi).name];
        
        fprintf('  Setting up run %d/%d: %s\n', runi, length(func_files), func_files(runi).name);
        
        % Get volume information
        try
            v = spm_vol(func_path);
            fprintf('    Found %d volumes\n', length(v));
            
            % Set up realignment job for this run
            for imagei = 1:length(v)
                matlabbatch{job_counter}.spm.spatial.realign.estwrite.data{1}{imagei,1} = ...
                    [func_path ',' num2str(imagei)];
            end
            
            % Estimation options (same as original GitHub script)
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.eoptions.sep = 4;
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.eoptions.interp = 2;
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.eoptions.weight = '';
            
            % Reslicing options (same as original GitHub script)
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.roptions.which = [0 1];   % mean image only
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.roptions.interp = 4;
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.roptions.mask = 1;
            matlabbatch{job_counter}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
            
            fprintf('    Job configured successfully\n');
            
        catch ME
            fprintf('    Error reading functional file: %s\n', ME.message);
            job_counter = job_counter - 1; % Don't increment job counter for failed jobs
        end
    end
end

% Run the realignment jobs
if job_counter > 0
    fprintf('\nRunning realignment for %d slice-time corrected functional runs...\n', job_counter);
    fprintf('This may take several minutes per run...\n');
    
    try
        spm_jobman('run', matlabbatch);
        fprintf('\nP2 Realignment completed successfully!\n');
        
        % Display what was created
        fprintf('\nOutput files created for each functional run:\n');
        fprintf('- rp_a*.txt: Motion parameters for slice-time corrected data\n');
        fprintf('- meana*.nii: Mean functional image for each corrected run\n');
        fprintf('- ra*.nii: Realigned slice-time corrected images (if requested)\n');
        
        fprintf('\nProcessing chain so far:\n');
        fprintf('1. ✅ Original: *_bold.nii.gz\n');
        fprintf('2. ✅ Slice-time corrected: a*_bold.nii\n');
        fprintf('3. ✅ Motion parameters: rp_a*_bold.txt\n');
        fprintf('4. ✅ Mean images: meana*_bold.nii\n');
        
        fprintf('\nNext step: Run P3 (coregistration) using mean images and anatomical data\n');
        
    catch ME
        fprintf('Error during realignment: %s\n', ME.message);
        fprintf('Check that all slice-time corrected files exist and are valid\n');
    end
    
else
    fprintf('No slice-time corrected functional runs found to process!\n');
    fprintf('Make sure slice timing correction created a*.nii files in func/ folders\n');
end

fprintf('\nNote: This realignment uses the slice-time corrected data (a*.nii files)\n');
fprintf('Motion correction is now applied to properly time-corrected functional data\n');