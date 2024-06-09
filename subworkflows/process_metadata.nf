workflow DERMATLAS_METADATA {
    take: 
    bamfile_ch
    pair_identities
    patient_metadata

    main:

    bamfile_ch
    | map { file -> 
            index = file + ".bai"
            tuple(file, index)}
    | map { file, index ->
        tuple(file.baseName.replace(".sample.dupmarked", ""), file, index)}
    | set { indexed_bams } 

    pair_identities 
    | splitCsv(sep:"\t", header:['tumor', 'normal']) 
    | map{ meta -> 
        [meta + [pair_id: meta.normal+ "_" + meta.tumor]]
        }
    | flatMap { meta -> 
    [
        [meta["normal"][0], meta],
        [meta["tumor"][0],  meta]
    ]}
    | set { pair_id_ch }
    

    patient_metadata
    | splitCsv(sep:"\t",header : true)
    | map {meta -> meta.subMap("Sex", "Sanger DNA ID", "OK_to_analyse_DNA?", "Phenotype")} 
    | map {meta -> 
            tuple(meta["Sanger DNA ID"], [meta + [sexchr: meta.Sex == "F" ? "XX" : "XY"]])}
    | set{ patient_metadata_ch }

    

    patient_metadata_ch
    | filter { id, meta -> id =~ "PD"}
    | collectFile(name: "allsamples2sex.txt", 
      storeDir: "${params.OUTDIR}/ASCAT/${params.release_version}"){
        id, meta ->
        ["allsamples2sex.txt", "${id}\t${meta["sexchr"][0]}\n"]
    }


 
    indexed_bams
    | join(pair_id_ch)
    | join(patient_metadata_ch)
    | map{
         id, file, index, meta, patients -> 
         def combinedMap = meta[0] + [file: file, index: index] + patients[0]
        // Check if the 'Sanger DNA ID' matches the 'normal',rename 'file' key accordingly
        if (combinedMap["Sanger DNA ID"] == combinedMap.normal) {
            combinedMap['normal_file'] = combinedMap.remove('file')
            combinedMap['normal_index'] = combinedMap.remove('index')
        } else {
            combinedMap['tumor_file'] = combinedMap.remove('file')
            combinedMap['tumor_index'] = combinedMap.remove('index')
        }
        [id, combinedMap]
         }
    | map{
        id, meta -> key = groupKey(meta.subMap("pair_id") ,2)
        [key, meta]
    }
    | groupTuple()
    | map{
        pair_id, meta -> 
        pair_id + meta[0] + meta[1]
    }
    | map{ meta -> tuple(meta, 
                        meta["normal_file"], 
                        meta["normal_index"], 
                        meta["tumor_file"],  
                        meta["tumor_index"])}
    | set { combined_metadata }


    combined_metadata 
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

    emit:
        combined_metadata

}