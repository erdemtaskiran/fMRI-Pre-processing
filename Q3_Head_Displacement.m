% Q3: Simple Head Motion Check - Clean Version
% Calculate framewise displacement for all functional runs
clear

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Create output directories
output_dir = [bids_root '/QC_images'];
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

q3_output_dir = [output_dir '/Q3_head_motion'];
if ~exist(q3_output_dir, 'dir')
    mkdir(q3_output_dir);
end

% Initialize storage
fd_max_trans = [];
fd_max_rotat = [];
fd_mean_trans = [];
fd_mean_rotat = [];
run_info = {};
subject_info = {};

fprintf('Starting motion analysis for %d subjects...\n', length(subjfolder));

for subji = 1:length(subjfolder)
    subj_id = subjfolder(subji).name;
    fprintf('Subject %d: %s\n', subji, subj_id);
    
    % Get all motion parameter files
    rp_files = dir([bids_root '/' subj_id '/func/rp_a' subj_id '_task-*_bold.txt']);
    
    if isempty(rp_files)
        fprintf('  No motion files found\n');
        continue;
    end
    
    fprintf('  Found %d motion files\n', length(rp_files));
    
    % Process each run
    for runi = 1:length(rp_files)
        rp_file_path = [bids_root '/' subj_id '/func/' rp_files(runi).name];
        
        fprintf('    Processing: %s\n', rp_files(runi).name);
        
        try
            % Load motion parameters
            rp = load(rp_file_path);
            fprintf('      Loaded motion file: %d rows x %d columns\n', size(rp,1), size(rp,2));
            
            if size(rp, 2) < 6
                fprintf('      Error: Motion file has %d columns, expected 6\n', size(rp, 2));
                continue;
            end
            
            % Show first few motion values for debugging
            fprintf('      First motion values: [%.3f %.3f %.3f %.3f %.3f %.3f]\n', rp(1,:));
            
            % Calculate framewise displacement
            % Translation FD
            Y_diff_trans = diff(rp(:,1:3));
            multp_trans = Y_diff_trans*Y_diff_trans';
            fd_trans = sqrt(diag(multp_trans));
            fprintf('      Translation FD calculated: %d values\n', length(fd_trans));
            
            % Rotation FD (convert to degrees)
            Y_diff_rotat = diff(rp(:,4:6)*180/pi);
            multp_rotat = Y_diff_rotat*Y_diff_rotat';
            fd_rotat = sqrt(diag(multp_rotat));
            fprintf('      Rotation FD calculated: %d values\n', length(fd_rotat));
            
            % Calculate statistics
            max_trans = max(fd_trans);
            max_rotat = max(fd_rotat);
            mean_trans = mean(fd_trans);
            mean_rotat = mean(fd_rotat);
            
            fprintf('      Statistics: max_trans=%.3f, max_rotat=%.3f\n', max_trans, max_rotat);
            
            % Store results
            fd_max_trans = [fd_max_trans; max_trans];
            fd_max_rotat = [fd_max_rotat; max_rotat];
            fd_mean_trans = [fd_mean_trans; mean_trans];
            fd_mean_rotat = [fd_mean_rotat; mean_rotat];
            run_info = [run_info; {rp_files(runi).name}];
            subject_info = [subject_info; {subj_id}];
            
            fprintf('      SUCCESS: Arrays now have %d entries\n', length(fd_max_trans));
            
        catch ME
            fprintf('      ERROR: %s\n', ME.message);
            fprintf('      Error occurred at line: %s\n', ME.stack(1).name);
        end
    end
end

% Check if we have data
n_runs = length(fd_max_trans);
fprintf('\nProcessed %d runs total\n', n_runs);

if n_runs == 0
    fprintf('No motion data was processed successfully!\n');
    return;
end

% Create scatter plot
fprintf('Creating scatter plot...\n');
figure('DefaultAxesFontSize',18, 'Position', [100, 100, 800, 600]);

try
    scatterhist(fd_max_trans, fd_max_rotat, 'NBins', [50 50], 'Direction', 'out', 'Marker', '.', 'MarkerSize', 15);
    xline(1.5,'r', 'LineWidth', 2);
    yline(1.5,'r', 'LineWidth', 2);
    title('Maximum Framewise Displacement');
    xlabel('Translation (mm)');
    ylabel('Rotation (degrees)');
    box off;
    grid on;
    
    % Save plot
    exportgraphics(gcf, [q3_output_dir '/Q3_head_motion_scatter.jpg'], 'Resolution', 300);
    fprintf('Scatter plot saved\n');
    
catch ME
    fprintf('Error creating plot: %s\n', ME.message);
end

% Summary statistics
fprintf('\n=== MOTION SUMMARY ===\n');
fprintf('Total runs processed: %d\n', n_runs);
fprintf('Mean max translation FD: %.3f ± %.3f mm\n', mean(fd_max_trans), std(fd_max_trans));
fprintf('Mean max rotation FD: %.3f ± %.3f degrees\n', mean(fd_max_rotat), std(fd_max_rotat));

% Check exclusion criteria
included_idx = (fd_max_trans < 1.5) & (fd_max_rotat < 1.5);
excluded_idx = (fd_max_trans > 1.5) | (fd_max_rotat > 1.5);

n_included = sum(included_idx);
n_excluded = sum(excluded_idx);

fprintf('\nRuns meeting motion criteria (<1.5 mm/deg): %d/%d (%.1f%%)\n', ...
    n_included, n_runs, 100*n_included/n_runs);

if n_excluded > 0
    fprintf('\nRuns with excessive motion (>1.5 mm or degrees):\n');
    excluded_subjects = subject_info(excluded_idx);
    excluded_runs = run_info(excluded_idx);
    excluded_trans = fd_max_trans(excluded_idx);
    excluded_rotat = fd_max_rotat(excluded_idx);
    
    for i = 1:n_excluded
        fprintf('  %s - %s: Trans=%.2f mm, Rot=%.2f deg\n', ...
            excluded_subjects{i}, excluded_runs{i}, excluded_trans(i), excluded_rotat(i));
    end
else
    fprintf('\n✅ All runs meet motion criteria!\n');
end

% Save results to TXT file instead of CSV
try
    fprintf('\nAttempting to save %d motion results...\n', n_runs);
    
    % Save main results as simple text file
    fid = fopen([q3_output_dir '/Q3_motion_results.txt'], 'w');
    
    if fid == -1
        error('Could not open file for writing');
    end
    
    % Write header
    fprintf(fid, 'Subject\tRun_File\tMax_Trans_FD\tMax_Rot_FD\tMean_Trans_FD\tMean_Rot_FD\n');
    
    % Write data
    for i = 1:n_runs
        fprintf(fid, '%s\t%s\t%.4f\t%.4f\t%.4f\t%.4f\n', ...
            subject_info{i}, run_info{i}, fd_max_trans(i), fd_max_rotat(i), ...
            fd_mean_trans(i), fd_mean_rotat(i));
    end
    
    fclose(fid);
    fprintf('TXT file saved: %s\n', [q3_output_dir '/Q3_motion_results.txt']);
    
    % Save exclusion report
    fid_excl = fopen([q3_output_dir '/Q3_exclusion_report.txt'], 'w');
    
    if fid_excl == -1
        error('Could not open exclusion file for writing');
    end
    
    % Calculate exclusion criteria
    included_idx = (fd_max_trans < 1.5) & (fd_max_rotat < 1.5);
    excluded_idx = (fd_max_trans > 1.5) | (fd_max_rotat > 1.5);
    
    n_included = sum(included_idx);
    n_excluded = sum(excluded_idx);
    
    % Write exclusion report header
    fprintf(fid_excl, '=== Q3 HEAD MOTION EXCLUSION REPORT ===\n');
    fprintf(fid_excl, 'Analysis Date: %s\n', datestr(now));
    fprintf(fid_excl, 'Motion Threshold: 1.5 mm/degrees\n\n');
    
    % Summary statistics
    fprintf(fid_excl, 'SUMMARY:\n');
    fprintf(fid_excl, 'Total runs processed: %d\n', n_runs);
    fprintf(fid_excl, 'Runs meeting criteria: %d (%.1f%%)\n', n_included, 100*n_included/n_runs);
    fprintf(fid_excl, 'Runs exceeding threshold: %d (%.1f%%)\n', n_excluded, 100*n_excluded/n_runs);
    fprintf(fid_excl, '\n');
    
    % Overall motion statistics
    fprintf(fid_excl, 'MOTION STATISTICS:\n');
    fprintf(fid_excl, 'Mean max translation FD: %.3f ± %.3f mm\n', mean(fd_max_trans), std(fd_max_trans));
    fprintf(fid_excl, 'Mean max rotation FD: %.3f ± %.3f degrees\n', mean(fd_max_rotat), std(fd_max_rotat));
    fprintf(fid_excl, 'Max translation FD observed: %.3f mm\n', max(fd_max_trans));
    fprintf(fid_excl, 'Max rotation FD observed: %.3f degrees\n', max(fd_max_rotat));
    fprintf(fid_excl, '\n');
    
    if n_excluded > 0
        fprintf(fid_excl, 'EXCLUDED RUNS (Motion > 1.5 mm/degrees):\n');
        fprintf(fid_excl, 'Subject\tRun_File\tTrans_FD\tRot_FD\tReason\n');
        fprintf(fid_excl, '----------------------------------------\n');
        
        excluded_subjects = subject_info(excluded_idx);
        excluded_runs = run_info(excluded_idx);
        excluded_trans = fd_max_trans(excluded_idx);
        excluded_rotat = fd_max_rotat(excluded_idx);
        
        for i = 1:n_excluded
            % Determine reason for exclusion
            reason = '';
            if excluded_trans(i) > 1.5 && excluded_rotat(i) > 1.5
                reason = 'Both Trans+Rot';
            elseif excluded_trans(i) > 1.5
                reason = 'Translation';
            elseif excluded_rotat(i) > 1.5
                reason = 'Rotation';
            end
            
            fprintf(fid_excl, '%s\t%s\t%.3f\t%.3f\t%s\n', ...
                excluded_subjects{i}, excluded_runs{i}, excluded_trans(i), excluded_rotat(i), reason);
        end
        
        fprintf(fid_excl, '\n');
        
        % Subject-level exclusion summary
        unique_excluded_subjects = unique(excluded_subjects);
        fprintf(fid_excl, 'SUBJECTS WITH EXCLUDED RUNS:\n');
        fprintf(fid_excl, 'Subject\tExcluded_Runs\tTotal_Runs\tPercent_Excluded\n');
        fprintf(fid_excl, '------------------------------------------------\n');
        
        for i = 1:length(unique_excluded_subjects)
            subj = unique_excluded_subjects{i};
            subj_excluded = sum(strcmp(excluded_subjects, subj));
            subj_total = sum(strcmp(subject_info, subj));
            subj_percent = 100 * subj_excluded / subj_total;
            
            fprintf(fid_excl, '%s\t%d\t%d\t%.1f%%\n', subj, subj_excluded, subj_total, subj_percent);
        end
        
    else
        fprintf(fid_excl, 'EXCLUDED RUNS: None\n');
        fprintf(fid_excl, '✅ All runs meet motion criteria!\n');
    end
    
    % Recommendations
    fprintf(fid_excl, '\n');
    fprintf(fid_excl, 'RECOMMENDATIONS:\n');
    if n_excluded == 0
        fprintf(fid_excl, '- No exclusions needed based on motion criteria\n');
        fprintf(fid_excl, '- Proceed with all runs for further analysis\n');
    else
        fprintf(fid_excl, '- Consider excluding the %d runs listed above\n', n_excluded);
        fprintf(fid_excl, '- Review individual motion plots for excluded runs\n');
        fprintf(fid_excl, '- Consider subject-level exclusion if >50%% of runs excluded\n');
        
        % Check for subjects with majority excluded runs
        subjects_to_exclude = {};
        unique_all_subjects = unique(subject_info);
        for i = 1:length(unique_all_subjects)
            subj = unique_all_subjects{i};
            subj_excluded = sum(strcmp(excluded_subjects, subj));
            subj_total = sum(strcmp(subject_info, subj));
            if subj_excluded / subj_total > 0.5
                subjects_to_exclude{end+1} = subj;
            end
        end
        
        if ~isempty(subjects_to_exclude)
            fprintf(fid_excl, '\n');
            fprintf(fid_excl, 'SUBJECTS RECOMMENDED FOR COMPLETE EXCLUSION (>50%% runs excluded):\n');
            for i = 1:length(subjects_to_exclude)
                fprintf(fid_excl, '- %s\n', subjects_to_exclude{i});
            end
        end
    end
    
    fclose(fid_excl);
    fprintf('Exclusion report saved: %s\n', [q3_output_dir '/Q3_exclusion_report.txt']);
    
    % Also save MATLAB workspace for debugging
    save([q3_output_dir '/Q3_motion_workspace.mat'], 'fd_max_trans', 'fd_max_rotat', ...
         'fd_mean_trans', 'fd_mean_rotat', 'subject_info', 'run_info');
    fprintf('MAT file saved for debugging\n');
    
    % Show first few entries to verify
    fprintf('\nFirst 3 entries in saved data:\n');
    for i = 1:min(3, n_runs)
        fprintf('%s - %s: Trans=%.3f, Rot=%.3f\n', ...
            subject_info{i}, run_info{i}, fd_max_trans(i), fd_max_rotat(i));
    end
    
catch ME
    fprintf('Error saving files: %s\n', ME.message);
    
    % Debug the arrays directly
    fprintf('\nDEBUG INFO:\n');
    fprintf('fd_max_trans size: [%d x %d]\n', size(fd_max_trans));
    fprintf('fd_max_rotat size: [%d x %d]\n', size(fd_max_rotat));
    fprintf('subject_info size: [%d x %d]\n', size(subject_info));
    fprintf('run_info size: [%d x %d]\n', size(run_info));
    
    if ~isempty(fd_max_trans)
        fprintf('First few fd_max_trans values: ');
        disp(fd_max_trans(1:min(3,end)));
    end
    
    if ~isempty(subject_info)
        fprintf('First few subjects: ');
        for i = 1:min(3, length(subject_info))
            fprintf('%s ', subject_info{i});
        end
        fprintf('\n');
    end
end

fprintf('\nQ3 motion analysis completed!\n');
fprintf('Output directory: %s\n', q3_output_dir);