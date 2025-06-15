% Quality control Q3b
% Plot time series from fMRI images and head motion for each run
% Modified for BIDS structure with multiple functional runs
clear

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Create output directory
output_dir = [bids_root '/QC_images/Q3b_motion_plots'];
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

for subji = 1:length(subjfolder)
    fprintf('Processing subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Get all slice-time corrected functional runs
    func_files = dir([bids_root '/' subj_id '/func/a' subj_id '_task-*_bold.nii']);
    
    if isempty(func_files)
        fprintf('  Warning: No slice-time corrected files found for %s\n', subj_id);
        continue;
    end
    
    % Process each functional run
    for runi = 1:length(func_files)
        fprintf('  Processing run %d/%d: %s\n', runi, length(func_files), func_files(runi).name);
        
        func_path = [bids_root '/' subj_id '/func/' func_files(runi).name];
        
        % Extract run info for filename
        [~, func_basename, ~] = fileparts(func_files(runi).name);
        
        try
            % Load the slice-time corrected functional images
            v_all = spm_vol(func_path);
            
            fprintf('    Loading %d volumes for signal analysis...\n', length(v_all));
            
            clear a dt
            
            % Read all volumes and calculate global signal
            for imagei = 1:length(v_all)
                v = spm_vol([func_path ',' num2str(imagei)]);
                y = spm_read_vols(v);
                a(:,imagei) = y(:);
            end
            
            gm = mean(mean(a)); % grand mean (4D)
            
            % Calculate pairwise variance
            for imagei = 1:length(v_all)-1
                dt(imagei) = (mean((a(:,imagei) - a(:,imagei+1)).^2))/gm;
            end
            
            meany = mean(a)./gm; % scaled global mean
            
            % Load motion parameters
            rp_file = [bids_root '/' subj_id '/func/rp_' func_basename '.txt'];
            
            if exist(rp_file, 'file')
                rp = load(rp_file);
                
                % Calculate framewise displacement
                % Translation FD
                Y_diff_trans = diff(rp(:,1:3));
                multp_trans = Y_diff_trans*Y_diff_trans';
                fd_trans = sqrt(diag(multp_trans));
                
                % Rotation FD
                Y_diff_rotat = diff(rp(:,4:6)*180/pi);
                multp_rotat = Y_diff_rotat*Y_diff_rotat';
                fd_rotat = sqrt(diag(multp_rotat));
                
                % Create plots
                figure('Position', [100, 100, 1200, 800], 'Visible', 'off');
                
                % Plot 1: Global mean
                subplot(2,2,1)
                plot(meany)
                title('Global mean (slice-time corrected)');
                xlabel('Image number')
                ylabel('Normalized intensity')
                box off
                grid on
                
                % Plot 2: Rigid body motion
                subplot(2,2,2)
                plot([rp(:,1:3) rp(:,4:6)*180/pi])
                title('Rigid body motion');
                xlabel('Image number')
                ylabel('mm / degrees')
                legend('X trans', 'Y trans', 'Z trans', 'X rot', 'Y rot', 'Z rot', 'Location', 'best')
                box off
                grid on
                
                % Plot 3: Pairwise variance
                subplot(2,2,3)
                plot(dt)
                yline(mean(dt)+3*std(dt),'-','3 SD','color',[0 0.4470 0.7410]);
                title('Pairwise variance (slice-time corrected)');
                xlabel('Image pair')
                ylabel('Scaled variance')
                box off
                grid on
                
                % Plot 4: Framewise displacement
                subplot(2,2,4)
                plot([fd_trans fd_rotat])
                title('Framewise displacement');
                xlabel('Image pair')
                ylabel('mm / degrees')
                legend('Translation','Rotation','location','best','box','off')
                if max(max([fd_trans fd_rotat])) > 1.5
                    yline(1.5,'r','FD = 1.5');
                end
                box off
                grid on
                
                % Add overall title with motion statistics
                suptitle(sprintf('%s - %s | Max FD: %.2f mm, %.2f deg', ...
                    subj_id, func_basename, max(fd_trans), max(fd_rotat)));
                
                % Save figure
                output_file = [output_dir '/' subj_id '_' func_basename '_motion.jpg'];
                exportgraphics(gcf, output_file, 'Resolution', 200);
                
                close(gcf);
                
                fprintf('    Saved: %s (Max FD: %.2f mm, %.2f deg)\n', ...
                    [subj_id '_' func_basename '_motion.jpg'], max(fd_trans), max(fd_rotat));
                
            else
                fprintf('    Warning: Motion parameter file not found: %s\n', rp_file);
            end
            
        catch ME
            fprintf('    Error processing run: %s\n', ME.message);
        end
    end
    
    fprintf('  Subject %s completed\n', subj_id);
end

fprintf('\n=== Q3B HEAD MOTION PLOTS COMPLETED ===\n');
fprintf('Individual motion plots saved to: %s\n', output_dir);
fprintf('\nEach plot shows:\n');
fprintf('1. Global signal over time (slice-time corrected)\n');
fprintf('2. 6DOF motion parameters (3 trans + 3 rot)\n');
fprintf('3. Pairwise variance with 3SD threshold\n');
fprintf('4. Framewise displacement with 1.5mm/deg threshold\n');
fprintf('\nWhat to look for:\n');
fprintf('- Sudden spikes in motion or signal\n');
fprintf('- Drift or systematic changes\n');
fprintf('- Correlation between motion and signal changes\n');
fprintf('- Runs exceeding 1.5mm/deg threshold\n');
fprintf('\nNext step: Review motion plots and proceed to P3a (skull stripping)\n');