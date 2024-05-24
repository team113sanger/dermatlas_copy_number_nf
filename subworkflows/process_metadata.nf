workflow DERMATLAS_METADATA {
    take: 
    bamfile_ch
    index_ch
    pair_identities
    patient_metadata
    outdir

    main:

    bamfile_ch
    | map { file ->
        tuple(file.baseName.replace(".sample.dupmarked", ""), file)}
    | set {bams}

   index_ch
   | map { file ->
        tuple(file.baseName.replace(".sample.dupmarked.bam", ""), file)} 
    | set { indices }

    bams
    | join(indices)
    | set { indexed_bams }


    pair_identities 
    | splitCsv(sep:"\t",header:['normal', 'tumor']) 
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

    emit:
        combined_metadata

}