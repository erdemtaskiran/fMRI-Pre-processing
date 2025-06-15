% Q5: Normalization Quality Check
% Display normalized functional images overlaid with MNI template
% Check spatial registration quality to MNI152 standard space
% Modified for BIDS structure with multiple functional runs

clear

% Add SPM12 to path if needed
% addpath('/path/to/spm12');  % Uncomment and set your path if SPM isn't loaded
spm('defaults', 'FMRI');

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Create output directory for QC images
qc_output_dir = [bids_root '/QC_images/Q5_normalization_check'];
if ~exist(qc_output_dir, 'dir')
    mkdir(qc_output_dir);
end

% Get SPM canonical template path
spm_path = which('spm');
spm_dir = fileparts(spm_path);
mni_template = [spm_dir '/canonical/single_subj_T1.nii'];

% Verify MNI template exists
if ~exist(mni_template, 'file')
    fprintf('Error: Cannot find MNI template at: %s\n', mni_template);
    fprintf('Please check your SPM12 installation\n');
    return;
end

fprintf('Starting Q5: Normalization Quality Check\n');
fprintf('Checking %d subjects...\n', length(subjfolder));
fprintf('Output directory: %s\n', qc_output_dir);

% Initialize counters for summary
total_subjects = 0;
subjects_with_norm_data = 0;
total_runs_checked = 0;

for subji = 1:length(subjfolder)
    subj_id = subjfolder(subji).name;
    total_subjects = total_subjects + 1;
    
    fprintf('\nProcessing subject %d/%d: %s\n', subji, length(subjfolder), subj_id);
    
    % Find all normalized functional runs for this subject
    norm_files = dir([bids_root '/' subj_id '/func/wa' subj_id '_task-*_bold.nii']);
    
    if isempty(norm_files)
        fprintf('  Warning: No normalized functional files found for %s\n', subj_id);
        fprintf('    Expected files like: wa%s_task-*_bold.nii\n', subj_id);
        continue;
    end
    
    subjects_with_norm_data = subjects_with_norm_data + 1;
    fprintf('  Found %d normalized functional runs\n', length(norm_files));
    
    % Check each normalized functional run
    for runi = 1:length(norm_files)
        run_file = norm_files(runi).name;
        run_path = [bids_root '/' subj_id '/func/' run_file];
        
        % Extract task and run info from filename
        task_pattern = 'task-([^_]+)';
        run_pattern = 'run-([^_]+)';
        task_match = regexp(run_file, task_pattern, 'tokens');
        run_match = regexp(run_file, run_pattern, 'tokens');
        
        if ~isempty(task_match)
            task_name = task_match{1}{1};
        else
            task_name = 'unknown';
        end
        
        if ~isempty(run_match)
            run_name = run_match{1}{1};
        else
            run_name = sprintf('%02d', runi);
        end
        
        fprintf('    Checking run %d/%d: task-%s run-%s\n', runi, length(norm_files), task_name, run_name);
        
        try
            % Get first volume of normalized functional run
            first_volume = [run_path ',1'];
            
            % Set up images for comparison
            imgs = char(first_volume, mni_template);
            
            % Display registration check
            spm_check_registration(imgs);
            
            % Add captions
            spm_orthviews('Caption', 1, sprintf('%s task-%s run-%s', subj_id, task_name, run_name));
            spm_orthviews('Caption', 2, 'MNI152 Template');
            
            % Display contour of functional image onto template
            spm_orthviews('contour', 'display', 1, 2);
            
            % Save QC image
            output_filename = sprintf('%s_task-%s_run-%s_normcheck.jpg', subj_id, task_name, run_name);
            output_path = [qc_output_dir '/' output_filename];
            
            spm_print(output_path, 'Graphics', 'jpg');
            
            fprintf('      ✅ QC image saved: %s\n', output_filename);
            total_runs_checked = total_runs_checked + 1;
            
            % Brief pause to allow SPM graphics to update
            pause(0.5);
            
        catch ME
            fprintf('      ❌ Error processing this run: %s\n', ME.message);
        end
    end
end

% Close any remaining SPM graphics windows
close all;

% Summary report
fprintf('\n' + string(repmat('=', 1, 60)) + '\n');
fprintf('Q5 NORMALIZATION CHECK SUMMARY\n');
fprintf(string(repmat('=', 1, 60)) + '\n');
fprintf('Total subjects processed: %d\n', total_subjects);
fprintf('Subjects with normalized data: %d\n', subjects_with_norm_data);
fprintf('Total functional runs checked: %d\n', total_runs_checked);

if subjects_with_norm_data > 0
    fprintf('Average runs per subject: %.1f\n', total_runs_checked / subjects_with_norm_data);
end

fprintf('\nQC images saved to: %s\n', qc_output_dir);

% What to look for in QC images
fprintf('\n' + string(repmat('-', 1, 50)) + '\n');
fprintf('WHAT TO CHECK IN QC IMAGES:\n');
fprintf(string(repmat('-', 1, 50)) + '\n');
fprintf('✅ GOOD normalization:\n');
fprintf('   • Functional image contours align well with MNI template\n');
fprintf('   • Brain boundaries match between images\n');
fprintf('   • Ventricles and major structures align\n');
fprintf('   • No obvious warping artifacts\n\n');

fprintf('❌ POOR normalization (consider excluding):\n');
fprintf('   • Large misalignment between functional and template\n');
fprintf('   • Brain appears stretched or compressed\n');
fprintf('   • Ventricles do not align\n');
fprintf('   • Functional image appears rotated relative to template\n\n');

fprintf('💡 TIPS:\n');
fprintf('   • Focus on cortical boundaries and ventricular alignment\n');
fprintf('   • Small misalignments in outer edges are usually acceptable\n');
fprintf('   • Check all runs for each subject for consistency\n');
fprintf('   • Document any subjects with poor normalization\n\n');

% Next steps
fprintf('NEXT STEPS:\n');
fprintf('1. Review all QC images in: %s\n', qc_output_dir);
fprintf('2. Create exclusion list for poorly normalized subjects\n');
fprintf('3. Proceed to P5: General Linear Model (GLM)\n');
fprintf('4. Consider re-processing subjects with poor normalization\n\n');

if total_runs_checked == 0
    fprintf('⚠️  WARNING: No normalized files found!\n');
    fprintf('   Make sure P4 (normalization) completed successfully\n');
    fprintf('   Expected files: wa[subject]_task-*_bold.nii\n');
else
    fprintf('🎯 Q5 Normalization check completed successfully!\n');
end

fprintf('\nNote: This completes the spatial preprocessing pipeline:\n');
fprintf('P1 ✅ Slice-time correction → P2 ✅ Segmentation → P3 ✅ Realignment → P4 ✅ Normalization\n');
fprintf('Quality checks: Q1 ✅ → Q2 ✅ → Q3 ✅ → Q4 ✅ → Q5 ✅\n');