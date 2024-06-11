workflow SPLIT_COHORT_SEXES {
    take: 
        metadata_ch

    main:
        metadata_ch
        | map { meta, nf, ni, tf, ti -> meta }
        | branch { 
                female: it["Sex"] == "F"
                male: true }
        | set { sex_split }
        
    
        sex_split.male
        | collectFile(name: "ascat_pairs_male.tsv", 
        storeDir: "${params.OUTDIR}/ASCAT"){
            meta ->
            ["ascat_pairs_male.tsv", "${meta["tumor"]}\t${meta["normal"]}\n"]
        }

    sex_split.female
        | collectFile(name: "ascat_pairs_female.tsv", 
        storeDir: "${params.OUTDIR}/ASCAT"){
            meta ->
            ["ascat_pairs_female.tsv", "${meta["tumor"]}\t${meta["normal"]}\n"]
        }
}