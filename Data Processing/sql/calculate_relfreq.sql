/* Calcualte the relative frequency (probability) for unigrams based on frequency / corpus size */
declare @uniCnt integer
select @uniCnt = count(*) from combined_unigrams

update combined_unigrams
set relFreq = convert(numeric(20,10), frequency) / @uniCnt

/* Calculate the relative frequencies of all n-grams given their frequency and the frequency of the n-1-gram root */
update combined_bigrams
set relFreq = convert(numeric(20,10),b.frequency) / a.frequency
from combined_bigrams b
	join combined_unigrams a on a.ngram = substring(b.ngram, 1, charindex('_', b.ngram)-1)

update combined_trigrams
set relFreq = convert(numeric(20,10),b.frequency) / a.frequency
from combined_trigrams b
	join combined_bigrams a on a.ngram = left(b.ngram, len(b.ngram) - charindex('_', reverse(b.ngram) + '_'))

update combined_quadragrams
set relFreq = convert(numeric(20,10),b.frequency) / a.frequency
from combined_quadragrams b
	join combined_trigrams a on a.ngram = left(b.ngram, len(b.ngram) - charindex('_', reverse(b.ngram) + '_'))

update combined_quintagrams
set relFreq = convert(numeric(20,10),b.frequency) / a.frequency
from combined_quintagrams b
	join combined_quadragrams a on a.ngram = left(b.ngram, len(b.ngram) - charindex('_', reverse(b.ngram) + '_'))