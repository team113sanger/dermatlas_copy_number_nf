def filter_ascat_qc_fails(channel, qc_fails) {
    qc_fail_list = qc_fails.splitCsv(sep:"\t").flatten()
    qc_fail_list
}