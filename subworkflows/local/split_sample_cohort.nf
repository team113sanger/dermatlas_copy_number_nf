workflow SPLIT_COHORT_SEXES {
    take: 
        metadata_ch

    main:
        metadata_ch
        | map { meta, _nf, _ni, _tf, _ti -> meta }
        | filter { meta ->
            if (meta["Sex"] != "F" && meta["Sex"] != "M") {
                log.warn "Skipping sample ${meta["tumor"]} with invalid Sex value: '${meta["Sex"]}'"
                return false
            }
            return true
        }
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
}