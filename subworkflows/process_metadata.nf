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
    
    pair_id_ch.view()

    patient_metadata
    | splitCsv(sep:"\t",header : true)
    | map {meta -> meta.subMap("Sex", "Sanger_DNA_ID", "OK_to_analyse_DNA?", "Phenotype")}
    | map {meta -> 
            tuple(meta["Sanger_DNA_ID"], [meta + [sexchr: meta.Sex == "F" ? "XX" : "XY"]])}
    | set{ patient_metadata_ch }


    patient_metadata_ch
    | filter { id, meta -> id =~ "PD"}
    | collectFile(name: "allsamples2sex.txt", 
      storeDir: "${params.outdir}/ASCAT/${params.release_version}"){
        id, meta ->
        ["allsamples2sex.txt", "${id}\t${meta["Sex"][0]}\n"]
    }


    pair_id_ch
    | join(patient_metadata_ch)
    | join(indexed_bams)
    | map{
         id, meta, patients, file, index  -> 
         def combinedMap = meta[0] + [file: file, index: index] + patients[0]
        // Check if the 'Sanger DNA ID' matches the 'normal',rename 'file' key accordingly
        if (combinedMap["Sanger_DNA_ID"] == combinedMap.normal) {
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