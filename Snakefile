import os.path

timepoints = ['bl']

rule all:
    input:
        expand('{tp}/brain/mpm_MT_std_NeuroMorph_Segmentation_clean.nii.gz', tp=timepoints),
        expand('{tp}/brain/dwi_fa_seg_stats.csv', tp=timepoints),
        expand('{tp}/brain/dwi_md1000_seg_stats.csv', tp=timepoints),
        expand('{tp}/brain/dwi_ad1000_seg_stats.csv', tp=timepoints),
        expand('{tp}/brain/dwi_rd1000_seg_stats.csv', tp=timepoints),
        expand('{tp}/brain/mpm_MT_seg_stats.csv', tp=timepoints),
        expand('{tp}/brain/mpm_A_seg_stats.csv', tp=timepoints),
        expand('{tp}/brain/mpm_R1_UNICORT_seg_stats.csv', tp=timepoints),
        expand('{tp}/brain/mpm_R2s_OLS_seg_stats.csv', tp=timepoints),
        expand('{tp}/brain/tractseg_output/bundle_segmentations/CST_left.nii.gz', tp=timepoints)

rule multiply_dwi_by_1000:
    input:
        dwi_map='{tp}/brain/dwi_{contrast}.nii.gz'
    output:
        dwi_map_by_1000='{tp}/brain/dwi_{contrast}1000.nii.gz'
    shell:
        'seg_maths {input.dwi_map} -mul 1000 {output.dwi_map_by_1000}'

rule read_dwi_segmentation_stats:
    input:
        flat_seg='{tp}/brain/dwi_tissue_map.nii.gz',
        dwi_map='{tp}/brain/dwi_{contrast}.nii.gz',
    output:
        stats='{tp}/brain/dwi_{contrast}_seg_stats.csv'
    shell:
        'niftkStats.py -in {input.dwi_map} -mask {input.flat_seg} -csv {output.stats}'

rule resample_segmentation_to_dwi:
    input:
        ref='{tp}/brain/hifi_b0_mean.nii.gz',
        flo='{tp}/brain/mpm_MT_std_NeuroMorph_Segmentation_flat.nii.gz',
        aff='{tp}/brain/mpm_MT_std_reg_hifi_b0_mean.aff'
    output:
        result='{tp}/brain/dwi_tissue_map.nii.gz'
    shell:
        'reg_resample -ref {input.ref} -flo {input.flo} -trans {input.aff} -res {output.result} -inter 0'

rule read_mpm_segmentation_stats:
    input:
        flat_seg='{tp}/brain/mpm_MT_std_NeuroMorph_Segmentation_flat.nii.gz',
        mpm='{tp}/brain/mpm_{contrast}_std.nii.gz',
    output:
        stats='{tp}/brain/mpm_{contrast}_seg_stats.csv'
    shell:
        'niftkStats.py -in {input.mpm} -mask {input.flat_seg} -csv {output.stats}'

rule flatten_segmentation:
    input:
        seg='{tp}/brain/mpm_MT_std_NeuroMorph_Segmentation.nii.gz'
    output:
        seg_flat='{tp}/brain/mpm_MT_std_NeuroMorph_Segmentation_flat.nii.gz'
    shell:
        'seg_maths {input.seg} -tpmax {output.seg_flat}'

rule tractseg:
    input:
        dwi='{tp}/brain/eddy_corrected_data.nii.gz',
        bvals='{tp}/brain/dwi.bval',
        bvecs='{tp}/brain/dwi.bvec',
    output:
        peaks='{tp}/brain/tractseg_output/peaks.nii.gz',
        left_cst='{tp}/brain/tractseg_output/bundle_segmentations/CST_left.nii.gz',
        right_cst='{tp}/brain/tractseg_output/bundle_segmentations/CST_right.nii.gz'
    shell:
        'TractSeg -i {input.dwi} --bvals {input.bvals} --bvecs {input.bvecs} --raw_diffusion_input --bundle_specific_threshold --postprocess'

rule dwi_maps:
    input:
        bvecs='{tp}/brain/dwi.bvec',
        bvals='{tp}/brain/dwi.bval',
        dwi='{tp}/brain/eddy_corrected_data.nii.gz'
    output:
        fa='{tp}/brain/dwi_fa.nii.gz',
        md='{tp}/brain/dwi_md.nii.gz',
        ad='{tp}/brain/dwi_ad.nii.gz',
        rd='{tp}/brain/dwi_rd.nii.gz'
    shell:
        'python3.6 /usr/local/bin/calculate_diffusion_maps.py {input.dwi} {input.bvals} {input.bvecs} {output.fa} {output.md} {output.ad} {output.rd}'

rule eddy_correction:
    input:
        dwi='{tp}/brain/dwi.nii.gz',
        mask='{tp}/brain/dwi_brain_mask.nii.gz',
        acqp='{tp}/brain/dwi_acq_params.txt',
        index='{tp}/brain/dwi_index.txt',
        bvecs='{tp}/brain/dwi.bvec',
        bvals='{tp}/brain/dwi.bval',
        fieldcoef='{tp}/brain/topup_results_fieldcoef.nii.gz',
        movpar='{tp}/brain/topup_results_movpar.txt'
    params:
        topup_results='{tp}/brain/topup_results',
        outname='{tp}/brain/eddy_corrected_data'
    output:
        movement_rms='{tp}/brain/eddy_corrected_data.eddy_movement_rms',
        outlier_map='{tp}/brain/eddy_corrected_data.eddy_outlier_map',
        outlier_n_sqr_stdev_map='{tp}/brain/eddy_corrected_data.eddy_outlier_n_sqr_stdev_map',
        outlier_n_stdev_map='{tp}/brain/eddy_corrected_data.eddy_outlier_n_stdev_map',
        outlier_report='{tp}/brain/eddy_corrected_data.eddy_outlier_report',
        parameters='{tp}/brain/eddy_corrected_data.eddy_parameters',
        shell_alignment_parameters='{tp}/brain/eddy_corrected_data.eddy_post_eddy_shell_alignment_parameters',
        restricted_movement_rms='{tp}/brain/eddy_corrected_data.eddy_restricted_movement_rms',
        rotated_bvecs='{tp}/brain/eddy_corrected_data.eddy_rotated_bvecs',
        corrected_image='{tp}/brain/eddy_corrected_data.nii.gz'
    shell:
        'eddy_openmp --imain={input.dwi} --mask={input.mask} --acqp={input.acqp} --index={input.index} --bvecs={input.bvecs} --bvals={input.bvals} --topup={params.topup_results} --out={params.outname}'

rule write_dwi_index:
    output:
        index='{tp}/brain/dwi_index.txt'
    run:
        ones = ["1"] * 67
        l = " ".join(ones)
        with open(output.index, 'w') as f:
            f.write(l)

rule resample_mask_to_dwi:
    input:
        aff='{tp}/brain/mpm_MT_std_reg_hifi_b0_mean.aff',
        mask='{tp}/brain/mpm_MT_std_NeuroMorph_Brain.nii.gz',
        ref='{tp}/brain/hifi_b0_mean.nii.gz'
    output:
        dwi_mask='{tp}/brain/dwi_brain_mask.nii.gz'
    shell:
        'reg_resample -ref {input.ref} -flo {input.mask} -trans {input.aff} -res {output.dwi_mask}'

rule register_mt_to_dwi:
    input:
        b0_mean='{tp}/brain/hifi_b0_mean.nii.gz',
        mt='{tp}/brain/mpm_MT_std.nii.gz'
    output:
        image='{tp}/brain/mpm_MT_std_reg_hifi_b0_mean.nii.gz',
        aff='{tp}/brain/mpm_MT_std_reg_hifi_b0_mean.aff'
    shell:
        'reg_aladin -ref {input.b0_mean} -flo {input.mt} -res {output.image} -aff {output.aff}'

rule mean_b0:
    input:
        b0='{tp}/brain/hifi_b0.nii.gz'
    output:
        b0_mean='{tp}/brain/hifi_b0_mean.nii.gz'
    shell:
        'fslmaths {input.b0} -Tmean {output.b0_mean}'

rule topup:
    input:
        b0='{tp}/brain/dwi_b0_complete.nii.gz',
        acq_params='{tp}/brain/dwi_acq_params.txt',
    output:
        hifi_b0='{tp}/brain/hifi_b0.nii.gz',
        fieldcoef='{tp}/brain/topup_results_fieldcoef.nii.gz',
        movpar='{tp}/brain/topup_results_movpar.txt'
    params:
        outdir='{tp}/brain/topup_results'
    shell:
        'topup --imain={input.b0} --datain={input.acq_params} --config=b02b0.cnf --out={params.outdir} --iout={output.hifi_b0}'

rule write_dwi_acquisition_parameters:
    output:
        acq_params='{tp}/brain/dwi_acq_params.txt'
    run:
        with open(output.acq_params, 'w') as f:
            for l in range(7):
                print('0 1 0 0.0304496', file=f)
            print('0 -1 0 0.0304496', file=f)

rule combine_b0:
    input:
        dwi='{tp}/brain/dwi.nii.gz',
        dwi_rev_blip='{tp}/brain/dwi_reversed_blip.nii.gz'
    output:
        b0='{tp}/brain/dwi_b0_complete.nii.gz'
    shadow: 'shallow'
    run:
        for vol in [0, 1, 15, 28, 42, 55, 66]:
            shell('seg_maths {input.dwi} -tp {vol} b0_{vol}.nii.gz')
        shell('seg_maths b0_0.nii.gz -merge 7 4 b0_1.nii.gz b0_15.nii.gz b0_28.nii.gz b0_42.nii.gz b0_55.nii.gz b0_66.nii.gz {input.dwi_rev_blip} {output.b0}')

rule clean_gif:
    input:
        seg='{tp}/brain/mpm_MT_std_NeuroMorph_Segmentation.nii.gz',
    output:
        seg_clean='{tp}/brain/mpm_MT_std_NeuroMorph_Segmentation_clean.nii.gz',
    shell:
        'seg_maths {input.seg} -tpmax -thr 1.5 -ero 1 -lconcomp -dil 1 tmp.nii.gz && '
        'seg_maths tmp.nii.gz -merge 5 4 tmp.nii.gz tmp.nii.gz tmp.nii.gz tmp.nii.gz tmp.nii.gz tmp4d.nii.gz && '
        'seg_maths {input.seg} -mul tmp4d.nii.gz {output.seg_clean} && '
        'rm tmp.nii.gz'

rule gif:
    input:
        mpm_mt='{tp}/brain/mpm_MT_std.nii.gz',
    output:
        seg='{tp}/brain/mpm_MT_std_NeuroMorph_Segmentation.nii.gz',
        parc='{tp}/brain/mpm_MT_std_NeuroMorph_Parcellation.nii.gz',
        brain='{tp}/brain/mpm_MT_std_NeuroMorph_Brain.nii.gz'
    threads: 4
    run:
        outdir = os.path.abspath(os.path.dirname(output.seg))
        shell('seg_GIF -in {input.mpm_mt} -db /gif/db.xml -v 1 -out ' + outdir)

rule standardize_orientation:
    input:
        mpm_mt='{tp}/brain/mpm_{contrast}.nii.gz',
    output:
        mpm_mt_std='{tp}/brain/mpm_{contrast}_std.nii.gz',
    shell:
        'fslreorient2std {input.mpm_mt} {output.mpm_mt_std}'