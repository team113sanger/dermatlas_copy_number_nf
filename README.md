# dermatlas_copy_number_nf

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.04.5-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

`dermatlas_copy_number_nf` is a bioinformatics pipeline written in [Nextflow](http://www.nextflow.io) for performing copy number alteration (CNA) analysis on cohorts of tumors within the [Dermatlas project](https://www.dermatlasproject.org). 

## Pipeline summary

In brief, this pipeline takes sets matched tumor-normal samples that have been pre-processed by the Dermatlas ingestion process and then:
- Links each sample bamfile to it's associated metadata.
- Links tumor-normal pairs.
- Runs ASCAT on each tumor-normal pair, outputting segment calls and diagnostic plots. 
- Collates summary statistics for all ASCAT runs and filters out samples that fall below a threshold Goodness-of-Fit level (GOF <90%).
- Merges the segment calls from ASCAT that pass filtering.
- Runs GISTIC2 on the merged segment calls to identify regions with significant copy-number alterations in the cohort (CNAs).
- Filters GISTIC2 calls to identify those that overlap with ASCAT and which pass a Q-value threshold.

## Inputs 

### Cohort-dependent variables
- `bam_files`: path to the top-level directory for a set of `.bam` files. **Note:** *pipeline assumes that corresponding `.bam.bai` index files have been pre-generated and are co-located with bams and you should use a `**` glob match to recursively collect all bamfiles in the directory.*
- `all_samples`: path to a file containing a tab-delimited list of all matched tumour-normal pairs in a cohort.
- `metadata_manifest`: path to a tab-delimited manifest containing information about sample phenotype and preparation. Columns can be specified using the following variables. Defaults columns and allowed values are:
    - `col_sex` (Default: `Sex`) - **M or F**
    - `col_sample_id` (Default: `Sanger_DNA_ID`) - **ID of the sample (e.g. PD001234)**
    - `col_include` (Default: `OK_to_analyse_DNA?`) - **Y or N**
    - `col_TN` (Default: `Phenotype`) - **T or N**


**Optional**
- `subcohorts`: a map defining subcohort analyses to run after ASCAT completes. Each entry maps a subcohort name to its configuration with `sample_list` and `plot_dir`:

  ```groovy
  subcohorts = [
      "independent_tumours": [
          sample_list: "/path/to/independent_tumours_matched.tsv",
          plot_dir: "PLOTS_INDEPENDENT"
      ],
      "one_tumour_per_patient": [
          sample_list: "/path/to/one_tumour_per_patient_matched.tsv",
          plot_dir: "PLOTS_ONE_PER_PATIENT"
      ]
  ]
  ```

  Each sample list file should be tab-delimited with `tumor` and `normal` columns specifying the matched pairs for that subcohort.

### Cohort-independent variables
Reference files that are reused across pipeline executions have been placed within the pipeline's default `nextflow.config` file to simplify user configuration and can be ommited from setup. Behind the scences the following reference files are required for a run: 
- `reference_genome`: path to a reference genome fasta file.
- `bait_set`: path to a `.bed` file describing the analysed genomic regions.
- `resource_files`: path to a directory containing ASCAT loci and allele files.
- `gc_file`: path to the ASCAT GC correction file.
- `rt_file`: path to the ASCAT replication timing correction file.
- `difficult_regions_file`: path to a file containing genomic regions considered to be problematic for analyses such as variant calling by Genome In A Bottle (GIAB); used by GISTIC2 for masking regions.
- `chrom_arms_file`: path to the file containing chromosome arm lengths.
- `gistic_broad_peak_q_cutoff`: a Q-value cutoff to be used when fitlering Gistic broad peak outputs (default 0.1).

Default reference file values supplied within the `nextflow.config` file can be overided by adding them to the params `.json` file. An example complete params file `example_params.json` is supplied within this repo for demonstation.

## Usage

Whether launched via the integrated website or manually, the pipeline is submitted the same way: `run_copy_number.sh` is piped into `bsub` as the
job script.

```bash
bsub -o "<stdout_log>" -e "<stderr_log>" \
     -g "<lsf_job_group>" -J "<job_name>" \
     < <dir>/run_copy_number.sh
```

Queue, resource group and memory come from the `#BSUB` directives inside the wrapper, so `bsub` adds only the job
name, job group and log paths. It is an ordinary bash script, so `bash run_copy_number.sh` also runs it in the
foreground on any farm node - the `#BSUB` lines are inert comments; `bsub` only makes it a batch job. Either way
it sources `./source_me.sh` relative to the directory it was started from.

Nearly all runs are triggered from the [Dermatlas cohorts page](https://team113.sanger.ac.uk/dermatlas/cohorts/),
which issues that command remotely against a project directory it has already provisioned - `source_me.sh`,
`run_copy_number.sh` and `copy_number.config` are all written for you. There is nothing to do by hand.

### Without the website

Clone the repo and supply what the website otherwise provisions: a project directory, the pipeline's
environment, and a couple of edits to the wrapper.

The config globs `${BAMS_DIR}/**.bam`, so BAMs may sit at any depth below `bams/`, each with its `.bam.bai`
alongside. See [Inputs](#cohort-dependent-variables) for the sample-list and metadata formats.

```
<project_dir>/                                   # PROJECT_DIR
├── bams/                                        # BAMS_DIR
│   └── PD1001a/PD1001a.sample.dupmarked.bam{,.bai}
├── metadata/
│   ├── 6740_3016-analysed_matched.tsv           # tumour/normal pairs
│   ├── 6740_3016-independent_tumours_matched.tsv
│   ├── 6740_3016-one_tumour_per_patient_matched.tsv
│   ├── 6740_3016-related_tumours_matched.tsv    # may be empty
│   └── cohort_metadata.tsv                      # patient metadata manifest
├── analysis/                                    # ANALYSIS_DIR; results land here
└── copynumber_pipe/                             # created by the wrapper, not by you
    ├── .lock                                    # see Reclaiming disk space
    ├── .completed_successfully                  #   "
    ├── work/                                    # deleted after a successful run
    └── tmp/
```

The environment itself can come from a `source_me.sh` or from the wrapper directly. Both are supported; pick one.

<details>
<summary><strong>With a <code>source_me.sh</code></strong> - reusable across runs, and the shape the website generates</summary>

1. Write `source_me.sh` beside the wrapper in `assets/`, which is where the wrapper looks by default. With
   reporting opted out, these twelve exports are the whole contract:

   ```bash
   export PROJECT_DIR="/lustre/.../6740_3016_MY_COHORT_WES"
   export COMMANDS_DIR="${PROJECT_DIR}/commands"
   export ANALYSIS_DIR="${PROJECT_DIR}/analysis"
   export BAMS_DIR="${PROJECT_DIR}/bams"
   export STUDY="6740"          # prefixes output filenames, and the run id
   export PROJECT="3016"        # prefixes output filenames, and the run id
   export COHORT="MY_COHORT"    # ends the output filename prefix
   export DNA_PAIR_LIST_ANALYSED_MATCHED="${PROJECT_DIR}/metadata/6740_3016-analysed_matched.tsv"
   export DNA_PAIR_LIST_INDEPENDENT_TUMOURS_MATCHED="${PROJECT_DIR}/metadata/6740_3016-independent_tumours_matched.tsv"
   export DNA_PAIR_LIST_ONE_TUMOUR_PER_PATIENT_MATCHED="${PROJECT_DIR}/metadata/6740_3016-one_tumour_per_patient_matched.tsv"
   export DNA_PAIR_LIST_RELATED_TUMOURS_MATCHED="${PROJECT_DIR}/metadata/6740_3016-related_tumours_matched.tsv"  # may be empty
   export COHORT_METADATA_FILE="${PROJECT_DIR}/metadata/cohort_metadata.tsv"  # metadata_manifest
   ```

2. In the wrapper, under **OPT-IN REPORTING** set `DERMATLAS_WEBSITE_LOGGING` and
   `DERMATLAS_SLACK_NOTIFICATIONS` to `"false"`, and under **RUN CONFIGURATION** point `CONFIG` at your
   `copy_number.config` and set `REVISION` to the release tag to run.

3. Submit from the directory holding `source_me.sh`:

   ```bash
   cd dermatlas_copy_number_nf/assets
   bsub -o run.out -e run.err -J "copynumber-<cohort>" < run_copy_number.sh
   ```

To override a single value without regenerating the file, uncomment just that variable in the wrapper's
**MANUAL ENVIRONMENT OVERRIDES** block - it is read after `source_me.sh`, so it wins.

</details>

<details>
<summary><strong>By editing <code>run_copy_number.sh</code> directly</strong> - self-contained, nothing to track outside the script</summary>

1. Under **ENVIRONMENT SETUP**, set `SOURCE_ME="none"` so the wrapper skips sourcing anything.

2. Under **MANUAL ENVIRONMENT OVERRIDES**, uncomment and fill in the pipeline-essential exports. With reporting
   opted out, these twelve are the whole contract:

   ```bash
   export PROJECT_DIR="/lustre/.../6740_3016_MY_COHORT_WES"
   export COMMANDS_DIR="${PROJECT_DIR}/commands"
   export ANALYSIS_DIR="${PROJECT_DIR}/analysis"
   export BAMS_DIR="${PROJECT_DIR}/bams"
   export STUDY="6740"          # prefixes output filenames, and the run id
   export PROJECT="3016"        # prefixes output filenames, and the run id
   export COHORT="MY_COHORT"    # ends the output filename prefix
   export DNA_PAIR_LIST_ANALYSED_MATCHED="${PROJECT_DIR}/metadata/6740_3016-analysed_matched.tsv"
   export DNA_PAIR_LIST_INDEPENDENT_TUMOURS_MATCHED="${PROJECT_DIR}/metadata/6740_3016-independent_tumours_matched.tsv"
   export DNA_PAIR_LIST_ONE_TUMOUR_PER_PATIENT_MATCHED="${PROJECT_DIR}/metadata/6740_3016-one_tumour_per_patient_matched.tsv"
   export DNA_PAIR_LIST_RELATED_TUMOURS_MATCHED="${PROJECT_DIR}/metadata/6740_3016-related_tumours_matched.tsv"  # may be empty
   export COHORT_METADATA_FILE="${PROJECT_DIR}/metadata/cohort_metadata.tsv"  # metadata_manifest
   ```

3. Under **OPT-IN REPORTING** set `DERMATLAS_WEBSITE_LOGGING` and `DERMATLAS_SLACK_NOTIFICATIONS` to
   `"false"`, and under **RUN CONFIGURATION** point `CONFIG` at your `copy_number.config` and set `REVISION`
   to the release tag to run.

4. Submit from anywhere - with `SOURCE_ME="none"` there is no `source_me.sh` to be beside:

   ```bash
   bsub -o run.out -e run.err -J "copynumber-<cohort>" < dermatlas_copy_number_nf/assets/run_copy_number.sh
   ```

The same block is the annotated master list for either route - every variable with its purpose and an example
value, including the website- and Slack-only ones you would add if you opted back in.

</details>

`copy_number.config` reads these same variables, so it needs no editing unless you want different `subcohorts`
or reference files. `REVISION` is fetched from GitHub, so your clone supplies the wrapper and config, not the
pipeline code - local edits to the workflow are not picked up until released.

The header of [`assets/run_copy_number.sh`](assets/run_copy_number.sh) maps every section and marks the
`[edit]` blocks, which are the only places you should need to touch.

### Toggles

| Variable | Default | Effect when `false` |
| --- | --- | --- |
| `DERMATLAS_WEBSITE_LOGGING` | `true` | no analysis-log record is written to the Dermatlas website |
| `DERMATLAS_SLACK_NOTIFICATIONS` | `true` | no Slack message on completion or failed launch |
| `DERMATLAS_CLEANUP_WORK_DIR` | `true` | this run's work directory is kept instead of deleted |

Work-directory cleanup only ever happens after a **successful** run; a failed one always keeps its work
directory, and so does one stopped by `bkill` or an LSF limit - `DERMATLAS_CLEANUP_WORK_DIR` is not consulted
unless the run succeeded. Cleanup relies on `params.publish_dir_mode = 'copy'`, and only ever removes the `work/` directory
the wrapper itself created.

None are required. Each is resolved from the environment, most specific first - a shell export beats
`source_me.sh`, which beats the default under **OPT-IN REPORTING** - so a single run can opt out without
editing anything:

```bash
export DERMATLAS_CLEANUP_WORK_DIR=false
bsub -o run.out -e run.err -J "copynumber-<cohort>" < run_copy_number.sh
```

`true/false`, `yes/no`, `on/off` and `1/0` are all accepted in any case; anything else fails the launch
immediately rather than part-way through.

### Reclaiming disk space

`work/` and `tmp/` are the bulk of a cohort's disk and inode use, and are usually deleted by a separate clean-up
script you run yourself rather than by the wrapper. So the wrapper leaves three dot-files in
`${PROJECT_DIR}/<pipeline_slug>/` that let such a script tell a live run from a finished one - **including a run
started by a different user, with no LSF tools involved**.

<details>
<summary><strong>The artefacts, and how to delete safely around them</strong></summary>

| Artefact | Meaning |
| --- | --- |
| `.lock` | created once and **never removed**. Its presence says only that this directory uses the scheme. It never means a run is live. |
| `.completed_successfully` | the last run finished successfully |
| `.completed_with_error` | the last run reached a conclusion and failed - `bkill` and LSF limit kills included |

Liveness is not a file. It is an exclusive `flock` held on `.lock` for as long as the wrapper owns the directory,
and the kernel releases it when the process dies by any means, including `kill -9` and a node crash. So there is
never a stale lock to clear - and `.lock` must never be deleted, because unlinking it lets the next run lock a
fresh inode and exclude nobody.

Both sentinels are cleared when a run starts and exactly one is written when it ends, so their absence is a
truthful "no verdict for what is on disk right now".

A second submission of a cohort while one is already running fails immediately with exit 75, naming the holder.
That is deliberate: both runs would otherwise share one `work/`, and the first to finish would delete it under
the second.

#### Reading the state

| State | `flock -n` | `.completed_successfully` | `.completed_with_error` |
| --- | --- | --- | --- |
| running now | busy | - | - |
| succeeded | free | yes | - |
| failed, incl. `bkill`ed | free | - | yes |
| died mid-run (`kill -9`, node crash) | free | - | - |

`flock -n <file> <command>` takes the lock, runs the command, and releases it - or, if something else already
holds the lock, runs nothing at all and exits with the code given to `-E`. So a check and a deletion are the same
one-liner with a different command on the end:

```bash
p="${PROJECT_DIR}/copynumber_pipe"

# 1. Is a run using this directory? `true` does nothing, so this only reports.
if flock -n -E 75 "$p/.lock" true; then
    echo "free - nothing is using $p"
else
    echo "RUNNING - held by:"; cat "$p/.lock"
fi

# 2. Move the work directory, but only if nothing is using it. The lock is held
#    for as long as the mv takes, so a run cannot start underneath it.
flock -n -E 75 "$p/.lock" mv "$p/work" /path/to/to_delete/
echo $?   # 0 = moved.  75 = a run owns it, and nothing was touched.
```

Testing the lock needs only **read** permission on `.lock`, so this works against another user's running
pipeline. Moving their `work/` afterwards still needs write permission on their pipeline directory.

#### Writing the clean-up statement

Take the lock across both the decision and the move, never test-then-move, and require `.lock` to exist first:
on a directory that pre-dates this scheme `flock` would create one and report a live run as idle.

```bash
cd "${PROJECT_DIR}/.."
mkdir -p to_delete

find . -type d \( -name '*_pipe' -o -name '*_pipeline' \) -print0 |
while IFS= read -r -d '' p; do
    [[ -e "$p/.lock" ]] || { echo "SKIP (no .lock) $p"; continue; }

    flock -n -E 75 "$p/.lock" bash -c '
        p="$1"
        # --- the policy: pick one ---------------------------------------
        [[ -e "$p/.completed_successfully" ]] || exit 3    # succeeded only
        # [[ -e "$p/.completed_with_error" ]] || exit 3    # failed only
        # ! [[ -e "$p/.completed_successfully" || -e "$p/.completed_with_error" ]] || exit 3   # died mid-run
        # (no test at all)                                 # anything not running
        # ----------------------------------------------------------------
        for d in work tmp; do
            [[ -d "$p/$d" ]] || continue
            # ${p#./} first: a leading "./" would turn into "._" and hide the result
            mv -v "$p/$d" "to_delete/$(echo "${p#./}" | tr / _)_${d}"
        done
    ' _ "$p"

    case $? in
      0)  ;;
      75) echo "SKIP (RUNNING)  $p" ;;
      3)  echo "SKIP (policy)   $p" ;;
      *)  echo "ERROR           $p" ;;
    esac
done
# rm -rf to_delete/
```

Rules that keep this safe: **neither sentinel present means "died mid-run", never "succeeded"**; never unlink or
replace `.lock`; and if the pipeline directory is on a filesystem not mounted with `flock` (Lustre `localflock`,
NFS `local_lock=`) the lock is node-local and a sweep running elsewhere will not see it - the wrapper warns about
this at launch, but a script that deletes data should check `findmnt -T "$p" -no FSTYPE,OPTIONS` itself and refuse.

A lock that looks stale is a live file descriptor, not a leftover file: `lsof "$p/.lock"` names the process
holding it. `nextflow run` inherits the descriptor, so an orphaned nextflow keeps its directory protected even
after the wrapper is gone - which is the intended behaviour.

</details>

### Container registry

When running the pipeline for the first time on the farm you will need to provide credentials to pull singularity containers from the team113 sanger gitlab. You should be able to do this by running
```
module load singularity/3.11.4 
singularity remote login --username $(whoami) docker://gitlab-registry.internal.sanger.ac.uk
```

The pipeline can configured to run on either Sanger OpenStack secure-lustre instances or farm22 by changing the profile speicified:
`-profile secure_lustre` or `-profile farm22`. 

## Pipeline visualisation
Created using nextflow's in-built visualisation features.

```mermaid
flowchart TB
    subgraph " "
    v0["Channel.fromPath"]
    v1["Channel.fromPath"]
    v2["Channel.fromPath"]
    v27["genome"]
    v28["baits"]
    v29["per_chrom_dir"]
    v30["gc_file"]
    v31["rt_file"]
    v43["gof_threshold"]
    v49["Channel.fromList"]
    v74["cohort_prefix"]
    v81["refgenefile"]
    v90["difficult_regions"]
    v91["focal_cutoff"]
    v92["prefix"]
    v98["arms_file"]
    v99["broad_cutoff"]
    v100["cohort_prefix"]
    end
    subgraph " "
    v11[" "]
    v24[" "]
    v26[" "]
    v33[" "]
    v34[" "]
    v35[" "]
    v36[" "]
    v37[" "]
    v38[" "]
    v39[" "]
    v61[" "]
    v62[" "]
    v76[" "]
    v77[" "]
    v78[" "]
    v79[" "]
    v80[" "]
    v83[" "]
    v84[" "]
    v85["gistic_tabs"]
    v86[" "]
    v87[" "]
    v88[" "]
    v94["sample_summary"]
    v95["cohort_summary"]
    v102[" "]
    end
    subgraph ASCAT_ANALYSIS
    v32([RUN_ASCAT_EXOMES])
    v40([EXTRACT_GOODNESS_OF_FIT])
    v3(( ))
    v41(( ))
    end
    subgraph ANALYSE_SUBCOHORT
    v60([SUMMARISE_ASCAT_ESTIMATES])
    v75([CREATE_FREQUENCY_PLOTS])
    subgraph GISTIC2_ANALYSIS
    v82([RUN_GISTIC2])
    v93([FILTER_GISTIC2_CALLS])
    v101([FILTER_BROAD_GISTIC2_CALLS])
    v89(( ))
    v96(( ))
    end
    end
    v0 --> v3
    v1 --> v3
    v2 --> v3
    v3 --> v11
    v3 --> v24
    v3 --> v26
    v27 --> v32
    v28 --> v32
    v29 --> v32
    v30 --> v32
    v31 --> v32
    v3 --> v32
    v32 --> v39
    v32 --> v40
    v32 --> v38
    v32 --> v37
    v32 --> v36
    v32 --> v35
    v32 --> v34
    v32 --> v33
    v32 --> v41
    v40 --> v41
    v43 --> v41
    v49 --> v41
    v41 --> v60
    v60 --> v62
    v60 --> v61
    v60 --> v75
    v74 --> v75
    v41 --> v75
    v75 --> v80
    v75 --> v79
    v75 --> v78
    v75 --> v77
    v75 --> v76
    v75 --> v89
    v75 --> v96
    v81 --> v82
    v41 --> v82
    v82 --> v88
    v82 --> v87
    v82 --> v86
    v82 --> v85
    v82 --> v84
    v82 --> v83
    v82 --> v89
    v82 --> v96
    v90 --> v93
    v91 --> v93
    v92 --> v93
    v89 --> v93
    v93 --> v95
    v93 --> v94
    v98 --> v101
    v99 --> v101
    v100 --> v101
    v96 --> v101
    v101 --> v102
```

## Testing

This pipeline has been developed with the [nf-test](http://nf-test.com) testing framework. Unit tests and small test data are provided within the pipeline `test` subdirectory. A snapshot has been taken of the outputs of most steps in the pipeline to help detect regressions when editing. You can run all tests on openstack with:

```
nf-test test 
```
and individual tests with:
```
nf-test test tests/modules/ascat_exomes.nf.test
```

For faster testing of the flow of data through the pipeline **without running any of the tools involved**, stubs have been provided to mock the results of each succesful step.
```
nextflow run main.nf \
-params-file params.json \
-c tests/nextflow.config \
--stub-run
```

## Cutting a release

Cutting a new release requires a new semantic version tag, a changelog entry and
a commit of the updated version in every file that records it.

### One-off setup, per clone

Releases go through `git hf` (HubFlow). If it is not on your `PATH`, `module load git`.
In a fresh clone, enable it once:

```bash
git hf init   # writes this clone's hubflow branch/prefix config; the defaults are correct
```

That is the only setup required.

### Steps

1. `git hf release start <version>`
2. `./.update-version.sh <version>` — sets the semantic version in every file that
   records it (`assets/run_copy_number.sh`, `docs/source/conf.py`, `nextflow.config`).
   Run `./.update-version.sh --help` for details. Commit the changes.
3. Update `CHANGELOG.md` and commit it.
4. `git hf release finish <version>`

## Asset release bundles

`assets/` is published to GitHub Releases as `projectify_asset_bundle.tar.gz` (plus a
`.sha256` of it) by `.github/workflows/publish-assets.yml`, so `dermanager projectify` can
fetch the files straight from the release CDN - no API call, no token, no rate limit:

```
https://github.com/team113sanger/dermatlas_copy_number_nf/releases/download/<ref>/projectify_asset_bundle.tar.gz
```

| `<ref>` | Bundle contents | Updated |
| --- | --- | --- |
| `X.Y.Z` | `assets/` at that release tag | once, then immutable |
| `main-latest` | `assets/` at the head of `main`, i.e. the latest released state | every push to `main` |
| `develop-latest` | `assets/` at the head of `develop` | every push to `develop` |

The two `-latest` refs are fixed tags on pre-releases. Each push replaces the bundle attached
to the tag, so the download URL never changes and always serves that branch's current assets.
`releases/latest/download/...` is deliberately not used - it resolves only to the newest
non-pre-release, so it cannot address the rolling channels.

This repository is GitHub-primary. It was previously GitLab-primary and push-mirrored to
GitHub; that mirror was retired and the GitLab project archived. To publish a bundle for a
ref that predates the workflow, run it by hand from the GitHub Actions tab (*Publish
projectify asset bundle* -> *Run workflow*) with `ref` set to the tag or branch to build from.
