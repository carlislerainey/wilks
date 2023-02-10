wc <- academicWriteR::count_words("doc/wilks.md")
wc_formatted <- scales::comma(wc)
cat(wc_formatted, file = "doc/misc/word-count.tex")
