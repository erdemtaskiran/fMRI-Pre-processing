% Quality control Q4
% Check registration between the functional and anatomical images
% Modified for BIDS structure with multiple functional runs
clear

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Create output directory
output_dir = [bids_root '/QC_images/Q4_coregister_check'];
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

for subji = 1:length(subjfolder)
    fprintf('Checking coregistration for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Get skull-stripped anatomical image
    skull_stripped_anat = [bids_root '/' subj_id '/anat/ss_m' subj_id '_T1w.nii'];
    
    if ~exist(skull_stripped_anat, 'file')
        fprintf('  Warning: Skull-stripped anatomical not found for %s\n', subj_id);
        continue;
    end
    
    % Get all slice-time corrected functional runs
    func_files = dir([bids_root '/' subj_id '/func/a' subj_id '_task-*_bold.nii']);
    
    if isempty(func_files)
        fprintf('  Warning: No slice-time corrected functional files found for %s\n', subj_id);
        continue;
    end
    
    % Process each functional run
    for runi = 1:length(func_files)
        func_basename = func_files(runi).name;
        func_path = [bids_root '/' subj_id '/func/' func_basename];
        
        fprintf('  Checking run %d/%d: %s\n', runi, length(func_files), func_basename);
        
        try
            % Create image array for registration check
            % First image: first volume of functional run (after coregistration)
            % Second image: skull-stripped anatomical (reference)
            imgs = char([func_path ',1'], [skull_stripped_anat ',1']);
            
            % Check registration
            spm_check_registration(imgs);
            
            % Extract task and run info for caption
            [~, filename_no_ext, ~] = fileparts(func_basename);
            
            % Display captions
            spm_orthviews('Caption', 1, [subj_id ' - ' filename_no_ext ' (functional)']);
            spm_orthviews('Caption', 2, 'Skull-stripped anatomical');
            
            % Display contour of functional image onto anatomical
            spm_orthviews('contour', 'display', 1, 2);
            
            % Save the figure
            output_file = [output_dir '/' subj_id '_' filename_no_ext '_coreg_check.jpg'];
            spm_print(output_file, 'Graphics', 'jpg');
            
            fprintf('    Saved: %s\n', [subj_id '_' filename_no_ext '_coreg_check.jpg']);
            
        catch ME
            fprintf('    Error checking coregistration: %s\n', ME.message);
        end
    end
    
    fprintf('  Subject %s completed\n', subj_id);
end

fprintf('\n=== Q4 COREGISTRATION QUALITY CHECK COMPLETED ===\n');
fprintf('Individual coregistration checks saved to: %s\n', output_dir);
fprintf('\nEach image shows:\n');
fprintf('- Functional image (first volume) overlaid on skull-stripped anatomical\n');
fprintf('- Contour of functional image boundaries\n');
fprintf('- Visual assessment of alignment quality\n');
fprintf('\nWhat to look for:\n');
fprintf('✅ GOOD alignment:\n');
fprintf('  - Functional brain matches anatomical brain boundaries\n');
fprintf('  - Cortical features align well\n');
fprintf('  - No obvious misalignment or rotation\n');
fprintf('  - Brain stem and cerebellum properly aligned\n');
fprintf('\n❌ POOR alignment:\n');
fprintf('  - Functional brain outside anatomical boundaries\n');
fprintf('  - Obvious rotation or translation errors\n');
fprintf('  - Cortical features misaligned\n');
fprintf('  - Partial brain coverage issues\n');
fprintf('\nFiles created: %d coregistration check images\n', length(dir([output_dir '/*.jpg'])));
fprintf('\nNext steps:\n');
fprintf('1. Review all coregistration check images\n');
fprintf('2. Identify subjects/runs with poor alignment\n');
fprintf('3. Consider re-running coregistration for problematic cases\n');
fprintf('4. Proceed to P4 (spatial normalization) for well-aligned data\n');
fprintf('\nNote: Good coregistration is essential for accurate normalization!\n');