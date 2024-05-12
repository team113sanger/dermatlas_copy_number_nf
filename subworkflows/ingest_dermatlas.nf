workflow DERMATLAS_METADATA {
    take: 
    bamfile_ch
    pair_identities
    patient_metadata

    main:

    bams = bamfile_ch
    .map { file ->
        tuple(file.baseName.replace(".sample.dupmarked", ""), file)
    }

    pids = pair_identities 
    .splitCsv(sep:"\t",header:['normal', 'tumor']) 
    .map{ meta -> 
        [meta + [pair_id: meta.normal+ "_" + meta.tumor]]
        }
    .flatMap { meta -> 
    [
        [meta["normal"][0], meta],
        [meta["tumor"][0],  meta]
    ]
    }
    

    pmdata = patient_metadata
    .splitCsv(sep:"\t",header : true)
    .map {meta -> meta.subMap("Sex", "Sanger DNA ID", "OK_to_analyse_DNA?", "Phenotype")} 
    .map {meta -> 
            tuple(meta["Sanger DNA ID"], [meta + [sexchr: meta.Sex == "F" ? "XX" : "XY"]])
    }

 
    combined_metadata = bams
    .join(pids)
    .join(pmdata)
    .map{
         id, file, meta, patients -> 
         def combinedMap = meta[0] + [file: file] + patients[0]
        // Check if the 'Sanger DNA ID' matches the 'normal',
        // rename 'file' key accordingly
        if (combinedMap["Sanger DNA ID"] == combinedMap.normal) {
            combinedMap['normal_file'] = combinedMap.remove('file')
        } else {
            combinedMap['tumor_file'] = combinedMap.remove('file')
        }
        [id,combinedMap]
         }
    .map{
        id, meta -> key = groupKey(meta.subMap("pair_id"),2)
        [key,meta]
    }
    .groupTuple()
    .map{
        pair_id, meta -> 
        [pair_id, meta[0] + meta[1]]
    }
    .map{ meta -> tuple(meta, meta[1]["normal_file"], meta[1]["tumor_file"])
    }.view()
    
    emit:
        combined_metadata

}