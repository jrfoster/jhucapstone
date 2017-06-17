truncate table quintagrams
insert quintagrams
select
	left(ngram, len(ngram) - charindex('_', reverse(ngram) + '_'))
	,right(ngram, charindex('_', reverse(ngram) + '_') - 1)
	,frequency
from combined_quintagrams
where frequency > 2

truncate table quadragrams
insert quadragrams
select
	left(ngram, len(ngram) - charindex('_', reverse(ngram) + '_'))
	,right(ngram, charindex('_', reverse(ngram) + '_') - 1)
	,frequency
from combined_quadragrams
where frequency > 4

truncate table trigrams
insert trigrams
select
	left(ngram, len(ngram) - charindex('_', reverse(ngram) + '_'))
	,right(ngram, charindex('_', reverse(ngram) + '_') - 1)
	,frequency
from combined_trigrams
where frequency > 8

truncate table bigrams
insert bigrams
select
	left(ngram, len(ngram) - charindex('_', reverse(ngram) + '_'))
	,right(ngram, charindex('_', reverse(ngram) + '_') - 1)
	,frequency
from combined_bigrams
where frequency > 8

truncate table unigrams
insert unigrams
select ngram as "word", frequency
from combined_unigrams
where frequency > 1
