%% GLM Model Specification and Estimation for All Subjects and Runs
% This script handles both music and nonmusic tasks, reading events from TSV files

clear all; clc;

%% Configuration
base_dir = '/Users/erdemtaskiran/Desktop/Depression/Depression';
output_dir = fullfile(base_dir, 'GLM_Results');

% Define your subjects
subjects = {'sub-control01', 'sub-control02', 'sub-control03', 'sub-control04', 'sub-control05', ...
           'sub-control06', 'sub-control07', 'sub-control08', 'sub-control09', 'sub-control10', ...
           'sub-control11', 'sub-control12', 'sub-control13', 'sub-control14', 'sub-control15', ...
           'sub-control16', 'sub-control17', 'sub-control18', 'sub-control19', 'sub-control20', ...
           'sub-mdd01', 'sub-mdd02', 'sub-mdd03', 'sub-mdd04', 'sub-mdd05', 'sub-mdd06', ...
           'sub-mdd07', 'sub-mdd08', 'sub-mdd09', 'sub-mdd10', 'sub-mdd11', 'sub-mdd12', ...
           'sub-mdd13', 'sub-mdd14', 'sub-mdd15', 'sub-mdd16', 'sub-mdd17', 'sub-mdd18', 'sub-mdd19'};

% Define tasks and their runs
tasks = struct();
tasks(1).name = 'music';
tasks(1).runs = {'run-1', 'run-2', 'run-3'};

tasks(2).name = 'nonmusic';
tasks(2).runs = {'run-4', 'run-5'};

% GLM parameters
TR = 3;
fmri_t = 50;
fmri_t0 = 1;
timing_units = 'secs';
hpf = 128;
mask_threshold = 0.8;
preproc_prefix = 'swa'; % Adjust if needed

%% Create output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Initialize batch
matlabbatch = {};
batch_counter = 1;
processing_log = {};

fprintf('=== Starting GLM Model Specification ===\n');

%% Main processing loop for Model Specification
for s = 1:length(subjects)
    subject_id = subjects{s};
    subject_dir = fullfile(base_dir, subject_id);
    
    fprintf('Processing subject: %s\n', subject_id);
    
    if ~exist(subject_dir, 'dir')
        fprintf('  Warning: Subject directory not found, skipping\n');
        continue;
    end
    
    for t = 1:length(tasks)
        task_name = tasks(t).name;
        task_runs = tasks(t).runs;
        
        for r = 1:length(task_runs)
            run_id = task_runs{r};
            
            fprintf('  Task: %s, Run: %s\n', task_name, run_id);
            
            % Define file paths
            func_dir = fullfile(subject_dir, 'func');
            func_file = fullfile(func_dir, sprintf('%s%s_task-%s_%s_bold.nii', preproc_prefix, subject_id, task_name, run_id));
            events_file = fullfile(func_dir, sprintf('%s_task-%s_%s_events.tsv', subject_id, task_name, run_id));
            motion_file = fullfile(func_dir, sprintf('rp_a%s_task-%s_%s_bold.txt', subject_id, task_name, run_id));
            
            % Check if files exist
            if ~exist(func_file, 'file') || ~exist(events_file, 'file') || ~exist(motion_file, 'file')
                fprintf('    Missing files, skipping this run\n');
                if ~exist(func_file, 'file'), fprintf('      Missing: %s\n', func_file); end
                if ~exist(events_file, 'file'), fprintf('      Missing: %s\n', events_file); end
                if ~exist(motion_file, 'file'), fprintf('      Missing: %s\n', motion_file); end
                continue;
            end
            
            %% Read events file
            try
                % Read TSV file
                fid = fopen(events_file, 'r');
                header = fgetl(fid); % Read header
                data = textscan(fid, '%f %f %s', 'Delimiter', '\t');
                fclose(fid);
                
                onsets = data{1};
                durations = data{2};
                trial_types = data{3};
                
                fprintf('    Found %d events in TSV file\n', length(onsets));
            catch
                fprintf('    Error reading events file, skipping\n');
                continue;
            end
            
            % Get unique conditions
            unique_conditions = unique(trial_types);
            fprintf('    Conditions: %s\n', strjoin(unique_conditions, ', '));
            
            % Get number of volumes
            V = spm_vol(func_file);
            num_volumes = length(V);
            
            % Create GLM directory
            glm_dir = fullfile(output_dir, subject_id, sprintf('GLM_task-%s_%s', task_name, run_id));
            if ~exist(glm_dir, 'dir')
                mkdir(glm_dir);
            end
            
            %% Setup Model Specification
            matlabbatch{batch_counter}.spm.stats.fmri_spec.dir = {glm_dir};
            matlabbatch{batch_counter}.spm.stats.fmri_spec.timing.units = timing_units;
            matlabbatch{batch_counter}.spm.stats.fmri_spec.timing.RT = TR;
            matlabbatch{batch_counter}.spm.stats.fmri_spec.timing.fmri_t = fmri_t;
            matlabbatch{batch_counter}.spm.stats.fmri_spec.timing.fmri_t0 = fmri_t0;
            
            % Setup scans
            scans = cell(num_volumes, 1);
            for vol = 1:num_volumes
                scans{vol} = sprintf('%s,%d', func_file, vol);
            end
            matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.scans = scans;
            
            % Setup conditions from TSV data
            for c = 1:length(unique_conditions)
                condition_name = unique_conditions{c};
                
                % Find indices for this condition
                condition_idx = strcmp(trial_types, condition_name);
                condition_onsets = onsets(condition_idx);
                condition_durations = durations(condition_idx);
                
                matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.cond(c).name = condition_name;
                matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.cond(c).onset = condition_onsets;
                matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.cond(c).duration = condition_durations;
                matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.cond(c).tmod = 0;
                matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {});
                matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.cond(c).orth = 1;
            end
            
            % Other session parameters
            matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.multi = {''};
            matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
            matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.multi_reg = {motion_file};
            matlabbatch{batch_counter}.spm.stats.fmri_spec.sess.hpf = hpf;
            
            % GLM parameters
            matlabbatch{batch_counter}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
            matlabbatch{batch_counter}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
            matlabbatch{batch_counter}.spm.stats.fmri_spec.volt = 1;
            matlabbatch{batch_counter}.spm.stats.fmri_spec.global = 'None';
            matlabbatch{batch_counter}.spm.stats.fmri_spec.mthresh = mask_threshold;
            matlabbatch{batch_counter}.spm.stats.fmri_spec.mask = {''};
            matlabbatch{batch_counter}.spm.stats.fmri_spec.cvi = 'AR(1)';
            
            %% Setup Model Estimation (depends on specification)
            matlabbatch{batch_counter + 1}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', ...
                substruct('.','val', '{}',{batch_counter}, '.','val', '{}',{1}, '.','val', '{}',{1}), ...
                substruct('.','spmmat'));
            matlabbatch{batch_counter + 1}.spm.stats.fmri_est.write_residuals = 0;
            matlabbatch{batch_counter + 1}.spm.stats.fmri_est.method.Classical = 1;
            
            % Log processing
            log_entry = sprintf('%s_task-%s_%s: %d volumes, %d conditions', ...
                subject_id, task_name, run_id, num_volumes, length(unique_conditions));
            processing_log{end+1} = log_entry;
            
            fprintf('    Added to batch: %d volumes, %d conditions\n', num_volumes, length(unique_conditions));
            
            % Increment batch counter by 2 (specification + estimation)
            batch_counter = batch_counter + 2;
        end
    end
end

%% Save batch and run
batch_file = fullfile(output_dir, 'GLM_specification_estimation_batch.mat');
save(batch_file, 'matlabbatch');

% Save processing log
log_file = fullfile(output_dir, 'processing_log.txt');
fid = fopen(log_file, 'w');
for i = 1:length(processing_log)
    fprintf(fid, '%s\n', processing_log{i});
end
fclose(fid);

%% Summary
fprintf('\n=== BATCH SUMMARY ===\n');
fprintf('Total batch jobs created: %d\n', length(matlabbatch));
fprintf('Total GLM analyses: %d\n', length(processing_log));
fprintf('Batch saved to: %s\n', batch_file);
fprintf('Processing log: %s\n', log_file);

%% Run the batch
fprintf('\n=== RUNNING GLM ANALYSIS ===\n');
fprintf('Starting model specification and estimation...\n');

try
    spm_jobman('run', matlabbatch);
    fprintf('GLM analysis completed successfully!\n');
    
    % Create completion report
    completion_file = fullfile(output_dir, 'completion_report.txt');
    fid = fopen(completion_file, 'w');
    fprintf(fid, 'GLM Analysis Completion Report\n');
    fprintf(fid, 'Generated: %s\n', datestr(now));
    fprintf(fid, 'Total analyses completed: %d\n', length(processing_log));
    fprintf(fid, '\nProcessed runs:\n');
    for i = 1:length(processing_log)
        fprintf(fid, '%s\n', processing_log{i});
    end
    fclose(fid);
    
catch ME
    fprintf('Error during batch execution:\n');
    fprintf('%s\n', ME.message);
    
    % Save error report
    error_file = fullfile(output_dir, 'error_report.txt');
    fid = fopen(error_file, 'w');
    fprintf(fid, 'Error Report\n');
    fprintf(fid, 'Generated: %s\n', datestr(now));
    fprintf(fid, 'Error message: %s\n', ME.message);
    fprintf(fid, 'Error identifier: %s\n', ME.identifier);
    if ~isempty(ME.stack)
        fprintf(fid, 'Error location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    fclose(fid);
end

%% Verification check
fprintf('\n=== VERIFICATION ===\n');
success_count = 0;
failed_runs = {};

for i = 1:length(processing_log)
    parts = split(processing_log{i}, ':');
    run_info = parts{1};
    
    % Extract subject and run info to find GLM directory
    run_parts = split(run_info, '_');
    if length(run_parts) >= 3
        subject_id = run_parts{1};
        task_run = strjoin(run_parts(2:end), '_');
        glm_dir = fullfile(output_dir, subject_id, sprintf('GLM_%s', task_run));
        spm_file = fullfile(glm_dir, 'SPM.mat');
        
        if exist(spm_file, 'file')
            success_count = success_count + 1;
        else
            failed_runs{end+1} = run_info;
        end
    end
end

fprintf('Successful GLM analyses: %d/%d\n', success_count, length(processing_log));
if ~isempty(failed_runs)
    fprintf('Failed runs:\n');
    for i = 1:length(failed_runs)
        fprintf('  %s\n', failed_runs{i});
    end
end

fprintf('\nAnalysis complete! Check individual GLM directories for results.\n');