# fMRI-Pre-processing
fMRI Pre-processing on SPM12 BIDS format - Suitable for Both Univariate and Multivariate Analysis 
# fMRI Pre-processing Pipeline for BIDS Format Data

## Overview

This repository contains a comprehensive fMRI pre-processing pipeline implemented in SPM12 and MATLAB, optimized for both univariate and multivariate analyses. The pipeline follows a modified version of the protocol described in:

**Di, X. & Biswal, B.B. (2023). A functional MRI pre-processing and quality control protocol based on statistical parametric mapping (SPM) and MATLAB. Frontiers in Neuroimaging, 1:1070151.** https://doi.org/10.3389/fnimg.2022.1070151

## Dataset

This pipeline is specifically configured for pre-processing the openly available dataset:

**Lepping, R. J., et al. (2016). Neural Processing of Emotional Musical and Nonmusical Stimuli in Depression. PLoS ONE, 11(6), e0156859.** https://doi.org/10.1371/journal.pone.0156859

The dataset is hosted on OpenNeuro: https://openneuro.org/datasets/ds000171

## Key Features

- **BIDS-compatible**: Fully supports Brain Imaging Data Structure format
- **MVPA-ready**: No spatial smoothing applied to preserve fine-grained spatial patterns
- **Comprehensive QC**: Extensive quality control checks at each processing step
- **Dual-task support**: Handles both music and non-music task conditions
- **Automated batch processing**: Processes multiple subjects and runs efficiently

## Pipeline Steps

### Pre-processing (P)
1. **P0: Slice Timing Correction** *(Added to original protocol)*
   - Corrects for temporal differences in slice acquisition
   - Uses task-specific slice timing parameters

2. **P1: Anatomical Segmentation**
   - Segments T1w images into GM, WM, CSF
   - Generates deformation fields for normalization

3. **P2: Realignment**
   - Motion correction using rigid-body transformation
   - Generates motion parameters (rp_*.txt files)

4. **P3a: Skull Stripping**
   - Creates brain-only images for improved coregistration
   - Uses tissue segmentations from P1

5. **P3b: Coregistration**
   - Aligns functional images to skull-stripped anatomical
   - Uses normalized mutual information cost function

6. **P4: Spatial Normalization**
   - Warps images to MNI152 standard space
   - 3×3×3mm isotropic voxels
   - **No spatial smoothing** (preserves spatial patterns for MVPA)

### Quality Control (Q)
- **Q1**: Initial data checks (parameters, orientation, artifacts)
- **Q2**: Segmentation quality assessment
- **Q3**: Head motion analysis (framewise displacement)
- **Q4**: Coregistration accuracy check
- **Q5**: Normalization quality verification




## Usage

### Running the Complete Pipeline

Execute scripts in numerical order:
```matlab
% Slice timing correction
P0_slice_timing_correction

% Anatomical segmentation
P1_Segmentation

% Realignment
P2_realingment

% Quality checks
Q3_Head_Displacement

% Skull stripping and coregistration
P3_a_Skull_stripped
P3b_co_registration

% Normalization
P4_Normalization_MNI

% Final quality checks
Q4_Coregistration_check
Q5_Normalization_Check
```

### First-Level GLM Analysis

For GLM analysis of preprocessed data:
```matlab
GLM_First_LEVEL  % Reads events from TSV files
```

## Output Structure

```
Depression/
├── sub-*/
│   ├── anat/
│   │   ├── c1*.nii      # Gray matter segmentation
│   │   ├── c2*.nii      # White matter segmentation
│   │   ├── c3*.nii      # CSF segmentation
│   │   ├── m*.nii       # Bias-corrected anatomical
│   │   ├── ss_m*.nii    # Skull-stripped anatomical
│   │   └── y_*.nii      # Deformation field
│   └── func/
│       ├── a*.nii       # Slice-time corrected
│       ├── rp_*.txt     # Motion parameters
│       ├── mean*.nii    # Mean functional image
│       └── wa*.nii      # Normalized functional images
├── QC_images/           # Quality control outputs
└── GLM_Results/         # First-level analyses
```

## Key Modifications from Original Protocol

1. **Added slice timing correction** as the first preprocessing step
2. **No spatial smoothing applied** - preserves spatial resolution for multivariate analyses
3. **Skull stripping** implemented for improved functional-anatomical coregistration
4. **Task-specific processing** for music and non-music conditions
5. **Enhanced quality control** with automated exclusion criteria

## Motion Exclusion Criteria

- Maximum framewise displacement threshold: 1.5mm or 1.5°
- Automated flagging of high-motion runs
- Subject-level exclusion if >50% of runs exceed threshold

## Citation

If you use this pipeline, please cite:

1. The original protocol:
   ```
   Di, X. & Biswal, B.B. (2023). A functional MRI pre-processing and quality control 
   protocol based on statistical parametric mapping (SPM) and MATLAB. 
   Frontiers in Neuroimaging, 1:1070151.
   ```

2. The dataset:
   ```
   Lepping, R. J., et al. (2016). Neural Processing of Emotional Musical and 
   Nonmusical Stimuli in Depression. PLoS ONE, 11(6), e0156859.
   ```

## Notes

- This pipeline is optimized for MVPA/searchlight analyses
- For univariate analyses requiring smoothing, add a smoothing step after normalization
- Quality control images are saved automatically for manual inspection
- Processing time: ~15-20 minutes per subject (varies by system)

## Support

For questions or issues, please open an issue on GitHub or contact [erdemtaskiran3557@gmail.com].
