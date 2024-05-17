workflow DERMATLAS_METADATA {
    take: 
    bamfile_ch
    index_ch
    pair_identities
    patient_metadata
    outdir

    main:

    bams = bamfile_ch
    .map { file ->
        tuple(file.baseName.replace(".sample.dupmarked", ""), file)
    }
   indices = index_ch
    .map { file ->
        tuple(file.baseName.replace(".sample.dupmarked.bam", ""), file)
    }
    indexed_bams = bams.join(indices)


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
    | splitCsv(sep:"\t",header : true)
    | map {meta -> meta.subMap("Sex", "Sanger DNA ID", "OK_to_analyse_DNA?", "Phenotype")} 
    | map {meta -> 
            tuple(meta["Sanger DNA ID"], [meta + [sexchr: meta.Sex == "F" ? "XX" : "XY"]])
    }

 
    combined_metadata = indexed_bams
    | join(pids)
    | join(pmdata)
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
        [id,combinedMap]
         }
    | map{
        id, meta -> key = groupKey(meta.subMap("pair_id"),2)
        [key, meta]
    }
    | groupTuple()
    | map{
        pair_id, meta -> 
        [pair_id, meta[0] + meta[1]]
    }
    | map{ meta -> tuple(meta, 
                        meta[1]["normal_file"], 
                        meta[1]["normal_index"], 
                        meta[1]["tumor_file"],  
                        meta[1]["tumor_index"])
    }

    combined_metadata 
    | collectFile(name: "sex2chr.txt", storeDir: outdir){
        meta ->
        ["sex2chr.txt", "${meta[0].pair_id[0]}\t${meta[0].sexchr[1]}\n"]
    }
    | set {sex2chr_ch}

    emit:
        combined_metadata
        sex2chr_ch

}