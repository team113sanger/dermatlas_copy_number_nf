workflow DERMATLAS_METADATA {
    take:
    bamfile_ch
    pair_identities
    patient_metadata
    main:
    // Process BAM files
    bamfile_ch
    | map { file ->
        def index = file + ".bai"
        tuple(file, index)
    }
    | map { file, index ->
        def sample_id = file.baseName.replace(".sample.dupmarked", "")
        tuple(sample_id, file, index)
    }
    | set { indexed_bams }
    
    // Process pair identities
    pair_identities
    | splitCsv(sep:"\t", header:['tumor', 'normal'])
    | map { meta ->
        [pair_id: meta.normal + "_" + meta.tumor] + meta
    }
    | set { pair_id_ch }
    
    
    // Process patient metadata
    patient_metadata
    | splitCsv(sep:"\t", header: true)
    | map { meta ->
        def sample_id = meta[params.col_sample_id]
        def sex_value = meta[params.col_sex]
        def sexchr = [F: "XX", M: "XY"].get(sex_value, "Unknown")
        def patient_info = [
            "Sex": sex_value,
            "Sample": sample_id,
            "Include?": meta[params.col_include],
            "Phenotype": meta[params.col_TN],
            "Karyotype": sexchr
        ]
        tuple(sample_id, patient_info)
    }
    | filter { sample_id, _meta -> sample_id != null && sample_id != "" && sample_id != "-" }
    | set { patient_metadata_ch }
    
    // Create sex info file for ASCAT
    patient_metadata_ch
    | collectFile(name: "allsamples2sex.txt",
        storeDir: "${params.outdir}/ASCAT/${params.release_version}") { id, meta ->
        ["allsamples2sex.txt", "${id}\t${meta['Sex']}\n"]
    }
    
    // Create a map of BAM files by sample ID for easy lookup
    indexed_bams
    | toList()
    | map { items ->
        def bam_map = [:]
        items.each { sample_id, file, index ->
            bam_map[sample_id] = [file: file, index: index]
        }
        return bam_map
    }
    | set { bam_map_ch }
    
    // Create a map of patient metadata by sample ID
    patient_metadata_ch
    | toList()
    | map { items ->
        def patient_map = [:]
        items.each { sample_id, meta ->
            patient_map[sample_id] = meta
        }
        return patient_map
    }
    | set { patient_map_ch }
    
    // Combine pair information with BAM files and patient metadata
    pair_id_ch
    | combine(bam_map_ch)
    | combine(patient_map_ch)
    | map { pair, bam_map, patient_map ->
        def tumor_id = pair.tumor
        def normal_id = pair.normal
        def pair_id = pair.pair_id
        
        // Check if we have BAM files for both tumor and normal samples
        if (!bam_map.containsKey(tumor_id) || !bam_map.containsKey(normal_id)) {
            log.warn("Missing BAM file for pair ${pair_id}: tumor=${tumor_id}, normal=${normal_id}")
            return null
        }
        
        // Create combined metadata
        def combined = [
            pair_id: pair_id,
            tumor: tumor_id,
            normal: normal_id,
            normal_file: bam_map[normal_id].file,
            normal_index: bam_map[normal_id].index,
            tumor_file: bam_map[tumor_id].file,
            tumor_index: bam_map[tumor_id].index
        ]
        
        // Add patient metadata if available
        if (patient_map.containsKey(tumor_id)) {
            combined.putAll(patient_map[tumor_id])
            combined.tumor_metadata = patient_map[tumor_id]
        }
        
        if (patient_map.containsKey(normal_id)) {
            combined.putAll(patient_map[normal_id])
            combined.normal_metadata = patient_map[normal_id]
        }
        
        // Return tuple with all needed information
        tuple(
            combined,
            combined.normal_file,
            combined.normal_index,
            combined.tumor_file,
            combined.tumor_index
        )
    }
    | filter { result -> result != null }
    | set { combined_metadata }
    
    emit:
        combined_metadata
}