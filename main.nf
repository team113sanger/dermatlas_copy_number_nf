#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { RUN_ASCAT_EXOMES } from './modules/ascat.nf'



workflow  {
    bamfiles = Channel.fromPath("tests/testdata/*.bam")
    .map { file ->
        tuple(file.baseName.replace(".sample.dupmarked", ""), file)
    }

    pair_identities = Channel.fromPath("tests/testdata/pair_ids.tsv")
    .splitCsv(sep:"\t",header:['normal', 'tumor']) 
    .map{meta -> 
        [meta + [pair_id: meta.normal+ "_" + meta.tumor]]
        }
    .flatMap { meta -> 
    [
        [meta["normal"][0], meta],
        [meta["tumor"][0],  meta]
    ]
    }
    

    // // RUN_ASCAT_EXOMES()
    patientData=Channel.fromPath("tests/testdata/metadata_tab")
    .splitCsv(sep:"\t",header : true)
    .map {meta -> meta.subMap("Sex", "Sanger DNA ID", "OK_to_analyse_DNA?", "Phenotype")} 
    .map {meta -> 
            tuple(meta["Sanger DNA ID"], [meta + [sexchr: meta.Sex == "F" ? "XX" : "XY"]])
    }


    combined_metadata = bamfiles.join(pair_identities).join(patientData)
    .map{
         id, file, meta, patients -> 
         def combinedMap = meta[0] + [file: file] + patients[0]
        // Check if the 'Sanger DNA ID' matches the 'normal', and rename 'file' key accordingly
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
    .view()
    RUN_ASCAT_EXOMES(combined_metadata)
    

}

// params.sample_list="${params.projdir}/*_tumour_normal_submitted_caveman.txt"
// params.metadata_file="${params.projdir}/*_METADATA_*.t*"