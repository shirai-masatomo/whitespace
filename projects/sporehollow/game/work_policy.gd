extends RefCounted
## Research values, not final balance. Physical material handling follows in unit 2.
const DESIGNATION_LIMIT = 32
const RETRY_SECONDS = 2.0
const PRIORITIES = {"build":2,"gather":1,"collect":2,"other":3}
const LABELS = {"build":"建築","gather":"採集","collect":"回収","other":"その他"}
const PAGE_SIZE = 10
