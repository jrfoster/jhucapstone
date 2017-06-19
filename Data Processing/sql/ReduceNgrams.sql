insert combined_unigrams
select ngram, sum(convert(int,[count])) as "frequency"
from combined
group by ngram
truncate table combined

insert combined_bigrams
select ngram, sum(convert(int,[count])) as "frequency"
from combined
group by ngram
truncate table combined

insert combined_trigrams
select ngram, sum(convert(int,[count])) as "frequency"
from combined
group by ngram
truncate table combined

insert combined_quadragrams
select ngram, sum(convert(int,[count])) as "frequency"
from combined
group by ngram
truncate table combined

insert combined_quintagrams
select ngram, sum(convert(int,[count])) as "frequency"
from combined
group by ngram
truncate table combined