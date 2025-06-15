% Slice Timing Correction
% Correct for differences in slice acquisition times
% Based on your BIDS metadata
clear

% Add SPM12 to path if needed
% addpath('/path/to/spm12');  % Uncomment and set your path if SPM isn't loaded
spm('defaults', 'FMRI');
spm_jobman('initcfg');

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Slice Timing Correction
% Correct for differences in slice acquisition times
% Handles different tasks (music vs nonmusic) with their specific parameters
clear

% Add SPM12 to path if needed
% addpath('/path/to/spm12');  % Uncomment and set your path if SPM isn't loaded
spm('defaults', 'FMRI');
spm_jobman('initcfg');

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Slice timing parameters for MUSIC task (from task-music_bold.json)
music_slice_timing = [1.5, 0.0, 1.56, 0.06, 1.62, 0.12, 1.68, 0.18, 1.74, 0.24, 1.8, 0.3, 1.86, 0.36, 1.92, 0.42, 1.98, 0.48, 2.04, 0.54, 2.1, 0.6, 2.16, 0.66, 2.22, 0.72, 2.28, 0.78, 2.34, 0.84, 2.4, 0.9, 2.46, 0.96, 2.52, 1.02, 2.58, 1.08, 2.64, 1.14, 2.7, 1.2, 2.76, 1.26, 2.82, 1.32, 2.88, 1.38, 2.94, 1.44];

% Slice timing parameters for NONMUSIC task (from task-nonmusic_bold.json)
nonmusic_slice_timing = [1.5, 0.0, 1.56, 0.06, 1.62, 0.12, 1.68, 0.18, 1.74, 0.24, 1.8, 0.3, 1.86, 0.36, 1.92, 0.42, 1.98, 0.48, 2.04, 0.54, 2.1, 0.6, 2.16, 0.66, 2.22, 0.72, 2.28, 0.78, 2.34, 0.84, 2.4, 0.9, 2.46, 0.96, 2.52, 1.02, 2.58, 1.08, 2.64, 1.14, 2.7, 1.2, 2.76, 1.26, 2.82, 1.32, 2.88, 1.38, 2.94, 1.44];

% Common parameters (same for both tasks)
tr = 3.0; % seconds
nslices = length(music_slice_timing); % Should be same for both tasks
ta = tr - (tr/nslices); % acquisition time
refslice = 1; % reference slice (first slice)

clear matlabbatch
job_counter = 0;

for subji = 1:length(subjfolder)
    fprintf('Setting up slice timing correction for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Process MUSIC task runs
    music_files = dir([bids_root '/' subj_id '/func/' subj_id '_task-music_*_bold.nii.gz']);
    if isempty(music_files)
        music_files = dir([bids_root '/' subj_id '/func/' subj_id '_task-music_*_bold.nii']);
    end
    
    for runi = 1:length(music_files)
        job_counter = job_counter + 1;
        
        func_path = [bids_root '/' subj_id '/func/' music_files(runi).name];
        
        fprintf('  Setting up MUSIC run %d/%d: %s\n', runi, length(music_files), music_files(runi).name);
        
        % Handle compressed files
        if endsWith(func_path, '.gz')
            fprintf('    Unzipping functional file...\n');
            temp_func = gunzip(func_path);
            func_path = temp_func{1};
        end
        
        try
            v = spm_vol(func_path);
            fprintf('    Found %d volumes, %d slices\n', length(v), nslices);
            
            % Set up slice timing correction job for this MUSIC run
            for imagei = 1:length(v)
                matlabbatch{job_counter}.spm.temporal.st.scans{1}{imagei,1} = ...
                    [func_path ',' num2str(imagei)];
            end
            
            % Use MUSIC task slice timing parameters
            matlabbatch{job_counter}.spm.temporal.st.nslices = nslices;
            matlabbatch{job_counter}.spm.temporal.st.tr = tr;
            matlabbatch{job_counter}.spm.temporal.st.ta = ta;
            matlabbatch{job_counter}.spm.temporal.st.so = music_slice_timing;
            matlabbatch{job_counter}.spm.temporal.st.refslice = refslice;
            matlabbatch{job_counter}.spm.temporal.st.prefix = 'a';
            
            fprintf('    MUSIC task job configured successfully\n');
            
        catch ME
            fprintf('    Error reading MUSIC functional file: %s\n', ME.message);
            job_counter = job_counter - 1;
        end
    end
    
    % Process NONMUSIC task runs
    nonmusic_files = dir([bids_root '/' subj_id '/func/' subj_id '_task-nonmusic_*_bold.nii.gz']);
    if isempty(nonmusic_files)
        nonmusic_files = dir([bids_root '/' subj_id '/func/' subj_id '_task-nonmusic_*_bold.nii']);
    end
    
    for runi = 1:length(nonmusic_files)
        job_counter = job_counter + 1;
        
        func_path = [bids_root '/' subj_id '/func/' nonmusic_files(runi).name];
        
        fprintf('  Setting up NONMUSIC run %d/%d: %s\n', runi, length(nonmusic_files), nonmusic_files(runi).name);
        
        % Handle compressed files
        if endsWith(func_path, '.gz')
            fprintf('    Unzipping functional file...\n');
            temp_func = gunzip(func_path);
            func_path = temp_func{1};
        end
        
        try
            v = spm_vol(func_path);
            fprintf('    Found %d volumes, %d slices\n', length(v), nslices);
            
            % Set up slice timing correction job for this NONMUSIC run
            for imagei = 1:length(v)
                matlabbatch{job_counter}.spm.temporal.st.scans{1}{imagei,1} = ...
                    [func_path ',' num2str(imagei)];
            end
            
            % Use NONMUSIC task slice timing parameters
            matlabbatch{job_counter}.spm.temporal.st.nslices = nslices;
            matlabbatch{job_counter}.spm.temporal.st.tr = tr;
            matlabbatch{job_counter}.spm.temporal.st.ta = ta;
            matlabbatch{job_counter}.spm.temporal.st.so = nonmusic_slice_timing;
            matlabbatch{job_counter}.spm.temporal.st.refslice = refslice;
            matlabbatch{job_counter}.spm.temporal.st.prefix = 'a';
            
            fprintf('    NONMUSIC task job configured successfully\n');
            
        catch ME
            fprintf('    Error reading NONMUSIC functional file: %s\n', ME.message);
            job_counter = job_counter - 1;
        end
    end
end

% Run the slice timing correction jobs
if job_counter > 0
    fprintf('\nRunning slice timing correction for %d functional runs...\n', job_counter);
    fprintf('This may take several minutes per run...\n');
    
    try
        spm_jobman('run', matlabbatch);
        fprintf('\nSlice timing correction completed successfully!\n');
        
        % Display what was created
        fprintf('\nOutput files created for each functional run:\n');
        fprintf('- a*.nii: Slice-time corrected functional images\n');
        fprintf('- Original files remain unchanged\n');
        
        fprintf('\nNext steps:\n');
        fprintf('1. Use the a*.nii files (slice-time corrected) for further processing\n');
        fprintf('2. Run P2 (realignment) on the corrected data\n');
        
    catch ME
        fprintf('Error during slice timing correction: %s\n', ME.message);
        fprintf('Check that all functional files exist and are valid\n');
    end
    
else
    fprintf('No functional runs found to process!\n');
end

fprintf('\nSlice timing correction uses task-specific parameters:\n');
fprintf('MUSIC task:\n');
fprintf('- TR: %.1f seconds\n', tr);
fprintf('- Slices: %d\n', nslices);
fprintf('- Slice timing: Interleaved (Siemens even-first)\n');
fprintf('- Max timing difference: %.1f seconds\n', max(music_slice_timing) - min(music_slice_timing));

fprintf('\nNONMUSIC task:\n');
fprintf('- TR: %.1f seconds\n', tr);
fprintf('- Slices: %d\n', nslices);
fprintf('- Slice timing: Interleaved (Siemens even-first)\n');
fprintf('- Max timing difference: %.1f seconds\n', max(nonmusic_slice_timing) - min(nonmusic_slice_timing));

% Check if slice timing is identical between tasks
if isequal(music_slice_timing, nonmusic_slice_timing)
    fprintf('\n✅ Both tasks have IDENTICAL slice timing parameters\n');
else
    fprintf('\n⚠️ Tasks have DIFFERENT slice timing parameters - handled separately\n');
end