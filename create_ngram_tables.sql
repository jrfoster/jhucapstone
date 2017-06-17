create table combined_unigrams (
	ngram varchar(255) not null,
	frequency int not null)

create table combined_bigrams (
	ngram varchar(max) not null,
	frequency int not null)

create table combined_trigrams (
	ngram varchar(max) not null,
	frequency int not null)

create table combined_quadragrams (
	ngram varchar(max) not null,
	frequency int not null)

create table combined_quintagrams (
	ngram varchar(max) not null,
	frequency int not null)

create table unigrams (
	word varchar(255) not null,
	frequency int not null)

create table bigrams (
	root varchar(max) not null,
	word varchar(255) not null,
	frequency int not null)

create table trigrams (
	root varchar(max) not null,
	word varchar(255) not null,
	frequency int not null)

create table quadragrams (
	root varchar(max) not null,
	word varchar(255) not null,
	frequency int not null)

create table quintagrams (
	root varchar(max) not null,
	word varchar(255) not null,
	frequency int not null)
