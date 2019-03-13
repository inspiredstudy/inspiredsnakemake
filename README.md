# INSPIRED study analysis pipeline

This repository contains the main analysis recipe for INSPIRED including brain
segmentation, white matter tract segmentation, necessary inter-modality
registrations, calculation of diffusion maps and metric readouts.

The [Snakemake](https://snakemake.readthedocs.io/en/stable/) software should be
used to run the pipeline.  In production this is done is parallel using
[Clustrun](https://github.com/jstutters/clustrun).

Data in the study is stored in the following structure:

    scans
        site (01, 02)
            patient (001, 002, 003)
                timepoint (bl)
                    brain
                    cord

The pipeline should be executed with the patient folder as the working directory.

In production this pipeline is executed in a Docker container described in the
[inspireddocker](https://github.com/inspiredstudy/inspireddocker) repository.
The Dockerfile in that repository should be referred to for a list of
dependencies.
