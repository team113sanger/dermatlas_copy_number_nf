workflow SPLIT_COHORT_SEXES {
    take:
        metadata_ch

    main:
        metadata_ch
        | branch { meta, _nf, _ni, _tf, _ti ->
            valid: meta["Sex"] == "F" || meta["Sex"] == "M"
            invalid: true
        }
        | set { validity_split }

        validity_split.invalid
        | map { meta, _nf, _ni, _tf, _ti ->
            log.warn "Skipping sample ${meta["tumor"]} with invalid Sex value: '${meta["Sex"]}'"
        }

        validity_split.valid
        | set { valid_metadata }

        valid_metadata
        | map { meta, _nf, _ni, _tf, _ti -> meta }
        | branch { meta ->
            female: meta["Sex"] == "F"
            male: meta["Sex"] == "M"
        }
        | set { sex_split }


        sex_split.male
        | collectFile(name: "ascat_pairs_male.tsv",
        storeDir: "${params.outdir}/ASCAT"){
            meta ->
            ["ascat_pairs_male.tsv", "${meta["tumor"]}\t${meta["normal"]}\n"]
        }

    sex_split.female
        | collectFile(name: "ascat_pairs_female.tsv",
        storeDir: "${params.outdir}/ASCAT"){
            meta ->
            ["ascat_pairs_female.tsv", "${meta["tumor"]}\t${meta["normal"]}\n"]
        }

    emit:
    valid_metadata
}